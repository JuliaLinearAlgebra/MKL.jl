function replace_libblas(base_dir, name)
    file = joinpath(base_dir, "build_h.jl")
    lines = readlines(file)

    libblas_idx   = findfirst(match.(r"const libblas_name", lines)   .!= nothing)
    liblapack_idx = findfirst(match.(r"const liblapack_name", lines) .!= nothing)

    @assert libblas_idx !== nothing && liblapack_idx !== nothing

    lines[libblas_idx] = "const libblas_name = $(repr(name))"
    lines[liblapack_idx] = "const liblapack_name = $(repr(name))"

    write(file, string(join(lines, '\n'), '\n'))
end

const MKL_PAYLOAD_START = "#== START MKL INSERT ==#"
const MKL_PAYLOAD_END = "#== END MKL INSERT ==#"

# Generates the code for the loading of MKL.jl before the stdlibs and running
# the __init__() explicitly, since these need to have been run when
# LinearAlgebra loads and determines what BLAS vendor is used.
# We also have to push to LOAD_PATH since at this stage only @stdlibs
# is in LOAD_PATH and MKL.jl can thus not be found.
function MKL_loading_code(load_paths::AbstractVector{<:AbstractString})
    res = [MKL_PAYLOAD_START]
    for path in load_paths
        push!(res, string("pushfirst!(LOAD_PATH, \"", escape_string(path), "\")"))
    end
    push!(res, "MKL = Base.require(Base, :MKL)")
    push!(res, "MKL.MKL_jll.__init__()")
    push!(res, "MKL.__init__()")
    for _ in eachindex(load_paths)
        push!(res, "popfirst!(LOAD_PATH)")
    end
    push!(res, MKL_PAYLOAD_END)
    return res
end

function insert_MKL_load(base_dir, load_paths::AbstractVector{<:AbstractString})
    file = joinpath(base_dir, "sysimg.jl")
    @info "Splicing in code to load MKL in $(file)"
    lines = readlines(file)

    # Be idempotent
    if MKL_PAYLOAD_START in lines
        @warn "Skipping injection of MKL into $file: existing MKL loading code detected"
        return
    end

    # After this the stdlibs get included, so insert MKL to be loaded here
    start_idx = findfirst(match.(r"Base._track_dependencies\[\] = true", lines) .!= nothing)

    splice!(lines, (start_idx + 1):start_idx, MKL_loading_code(load_paths))
    write(file, string(join(lines, '\n'), '\n'))
    return
end

function remove_MKL_load(base_dir)
    file = joinpath(base_dir, "sysimg.jl")
    @info "Removing code to load MKL in $(file)"
    lines = readlines(file)

    start_idx = findfirst(==(MKL_PAYLOAD_START), lines)
    end_idx = findfirst(==(MKL_PAYLOAD_END), lines)

    if start_idx === nothing || end_idx === nothing
        if start_idx !== nothing || end_idx !== nothing
            @warn "Incomplete MKL loading code detected, check $file"
        else
            @warn "No MKL loading code detected in $file"
        end
        return
    end

    splice!(lines, start_idx:end_idx)
    write(file, string(join(lines, '\n'), '\n'))
    return
end

function get_precompile_statments_file()
    jl_dev_ver = length(VERSION.prerelease) == 2 && (VERSION.prerelease)[1] == "DEV" # test if running nightly/unreleased version
    jl_gh_tag = jl_dev_ver ? "master" : "release-$(VERSION.major).$(VERSION.minor)"
    prec_jl_url = "https://raw.githubusercontent.com/JuliaLang/julia/$jl_gh_tag/contrib/generate_precompile.jl"
    @info "getting precompile script from: $prec_jl_url"
    prec_jl_fn = tempname()
    download(prec_jl_url, prec_jl_fn)
    prec_jl_content = read(prec_jl_fn, String)
    # PackageCompiler.jl already inits stdio and double initing it leads to bad things
    write(prec_jl_fn, replace(prec_jl_content, "Base.reinit_stdio()" => "# Base.reinit_stdio()"))
    return prec_jl_fn
end

default_mkl_load_paths() = haskey(ENV, "JULIA_MKL_LOAD_PATH") ?
    split(ENV["JULIA_MKL_LOAD_PATH"], ':') : ["@v#.#", "@"]
enable_mkl_startup(; load_paths::AbstractVector{<:AbstractString} = default_mkl_load_paths()) =
    change_blas_library(MKL_jll.libmkl_rt, load_paths=load_paths)
enable_openblas_startup() = change_blas_library("libopenblas")

function change_blas_library(libblas; load_paths::Union{Nothing, AbstractVector{<:AbstractString}} = nothing)
    @info "Using $libblas as the default BLAS library for Julia"

    # First, we need to modify a few files in Julia's base directory
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")
    if libblas == "libopenblas"
        if Sys.WORD_SIZE == 64
            libblas = "$(libblas)64_"
        end
        remove_MKL_load(base_dir)
    else
        insert_MKL_load(base_dir, load_paths)
    end

    # Replace definitions of `libblas_name`, etc.. to point to MKL or OpenBLAS
    replace_libblas(base_dir, libblas)

    # Next, build a new system image
    # We don't want to load PackageCompiler in top level scope because
    # we will put MKL.jl in the sysimage and having PackageCompiler loaded
    # means it will also be put there
    @eval begin
        using PackageCompiler
        PackageCompiler.create_sysimage(; incremental=false, replace_default=true,
                                        script=get_precompile_statments_file())
    end
end
