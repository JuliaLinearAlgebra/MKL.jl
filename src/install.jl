using PackageCompiler

"""
    lineedit(editor::Function, filename::String)

Easily edit a file, line by line.  If your `editor` function returns `nothing` the
file is not modified.  If the file does not exist, silently fails.  Usage example:

    lineedit("foo.jl") do lines
        map(lines) do l
            if occursin(r"libblas_name", l)
                return "const libblas_name = \"libfoo.so\"\n"
            end
            return l
        end
    end
"""
function lineedit(editor::Function, filename::String)
    # Silently fail for files that don't exist
    if !isfile(filename)
        return nothing
    end

    lines = open(filename) do io
        readlines(io, keep=true)
    end

    # Run user editor; if something goes wrong, just quit out
    try
        lines = editor(lines)
    catch e
        @error("Error occured while running user line editor:", e)
        return nothing
    end

    # Write it out, if the editor decides something needs to change
    if lines != nothing
        open(filename, "w") do io
            for l in lines
                write(io, l)
            end
        end
    end

    # Return the lines, just for fun
    return lines
end

function replace_libblas(base_dir, name)
    # Replace `libblas` and `liblapack` in build_h.jl
    file = joinpath(base_dir, "build_h.jl")
    lineedit(file) do lines
        @info("Replacing libblas_name in $(repr(file))")
        return map(lines) do l
            if occursin(r"libblas_name", l)
                return "const libblas_name = $(repr(name))\n"
            elseif occursin(r"liblapack_name", l)
                return "const liblapack_name = $(repr(name))\n"
            else
                return l
            end
        end
    end
end

# Used to insert a load of MKL.jl before the stdlibs and run the __init__ explicitly
# since these need to have been run when LinearAlgebra loads and determines
# what BLAS vendor is used.
# We also have to push to LOAD_PATH since at this stage only @stdlibs
# is in LOAD_PATH and MKL.jl can thus not be found.
const MKL_PAYLOAD = """
    # START MKL INSERT
    pushfirst!(LOAD_PATH, "@v#.#")
    pushfirst!(LOAD_PATH, "@")
    MKL = Base.require(Base, :MKL)
    MKL.MKL_jll.__init__()
    MKL.__init__()
    popfirst!(LOAD_PATH)
    popfirst!(LOAD_PATH)
    # END MKL INSERT"""

const MKL_PAYLOAD_LINES = split(MKL_PAYLOAD, '\n')

function insert_MKL_load(base_dir)
    file = joinpath(base_dir, "sysimg.jl")
    @info "Splicing in code to load MKL in $(file)"
    lines = readlines(file)

    # Be idempotent
    if MKL_PAYLOAD_LINES[1] in lines
        return
    end

    # After this the stdlibs get included, so insert MKL to be loaded here
    start_idx = findfirst(match.(r"Base._track_dependencies\[\] = true", lines) .!= nothing)

    splice!(lines, (start_idx + 1):start_idx, MKL_PAYLOAD_LINES)
    write(file, string(join(lines, '\n'), '\n'))
    return
end

function remove_MKL_load(base_dir)
    file = joinpath(base_dir, "sysimg.jl")
    @info "Removing code to load MKL in $(file)"
    lines = readlines(file)

    start_idx = findfirst(==(MKL_PAYLOAD_LINES[1]), lines)
    end_idx = findfirst(==(MKL_PAYLOAD_LINES[end]), lines)

    if start_idx === nothing || end_idx === nothing
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
    return prec_jl_fn
end

function enable_mkl_startup(libmkl_rt=MKL_jll.libmkl_rt)
# First, we need to modify a few files in Julia's base directory
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")

    # Replace definitions of `libblas_name`, etc.. to point to MKL
    replace_libblas(base_dir, libmkl_rt)
    insert_MKL_load(base_dir)

    # Next, build a new system image
    PackageCompiler.create_sysimage(; incremental=false, replace_default=true, script="generate_precompile.jl")
end

function enable_openblas_startup(libopenblas = "libopenblas")
    # First, we need to modify a few files in Julia's base directory
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")

    # Replace definitions of `libblas_name`, etc.. to point to MKL
    if Sys.WORD_SIZE == 64
        libopenblas = "$(libopenblas)64_"
    end
    replace_libblas(base_dir, libopenblas)
    remove_MKL_load(base_dir)

    # Next, build a new system image
    PackageCompiler.create_sysimage(; incremental=false, replace_default=true) #, script=get_precompile_statments_file())
end
