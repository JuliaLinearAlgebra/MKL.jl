using PackageCompilerX

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
        @info("Replacing libblas_name in $(file)")
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

"""
    find_init_func_bounds(lines)

Given a list of `lines`, find the beginning and ending indicies within `lines` that
contains the `__init__()` function, if any.  If none can be found, returns `(nothing, nothing)`.
"""
function find_init_func_bounds(lines)
    start_idx = findfirst(match.(r"^function\s+__init__\(\)\s*$", lines) .!= nothing)
    if start_idx === nothing
        return (nothing, nothing)
    end

    func_len = findfirst(match.(r"^end\s*$", lines[start_idx+1:end]) .!= nothing)
    if func_len === nothing
        return (nothing, nothing)
    end
    return (start_idx, start_idx + func_len)
end

function force_proper_PATH(base_dir, dir_path)
    # We need to be compatible with Julia 1.0+, so we need to search for `__init__()`
    # within both `sysimg.jl` (for Julia 1.0 and 1.1) as well as `Base.jl` (for 1.2+)

    for file in ("sysimg.jl", "Base.jl")
        @info("Checking $(file)")
        lineedit(joinpath(base_dir, file)) do lines
            # Find the start/end of `__init__()` within this file, if possible:
            init_start, init_end = find_init_func_bounds(lines)
            if init_start === nothing
                @info("Could not find init function in $(file)")
                return nothing
            end

            # Scan the function for mentions of our `dir_path`; if it already exists,
            # then call it good, returning `nothing` so the file is not modified.
            if any(match.(r"\s+ENV\[\"PATH\"\] =", lines[init_start+1:init_end-1]) .!= nothing)
                @info("Found ENV already")
                return nothing
            end

            # If we found a function, insert our `ENV["PATH"]` mapping:
            pathsep = Sys.iswindows() ? ';' : ':'
            insert!(
                lines,
                init_start + 1,
                "    ENV[\"PATH\"] = string(ENV[\"PATH\"], $(repr(pathsep)), $(repr(dir_path)))\n",
            )
            @info("Successfully modified $(file)")
            return lines
        end
    end
end

function generate_precompile_statments()
    jl_dev_ver = length(VERSION.prerelease) == 2 && (VERSION.prerelease)[1] == "DEV" # test if running nightly/unreleased version
    jl_gh_tag = jl_dev_ver ? "master" : "release-$(VERSION.major).$(VERSION.minor)"
    prec_jl_url = "https://raw.githubusercontent.com/JuliaLang/julia/$jl_gh_tag/contrib/generate_precompile.jl"

    @info "getting precompile script from: $prec_jl_url"

    prec_jl_fn = "generate_precompile.jl"
    download(prec_jl_url, prec_jl_fn)
    prec_jl_content = read(prec_jl_fn, String)
    patch = "@info(\"processed: \$n_succeeded\")\ncp(precompile_file, \"precomp_stmt.jl\", force=true)"
    open(prec_jl_fn, "w") do f
       write(f, replace(prec_jl_content, "@assert n_succeeded > 3500" => patch))
    end

    try
        julia_ = joinpath(Sys.BINDIR, Base.julia_exename())
        cmd = `$julia_ $prec_jl_fn`
        run(cmd)
    catch
        @warn "Rebuilding system image with precompiling failed. This may lead to REPL latency."
    end

end


function enable_mkl_startup(libmkl_rt)
    # First, we need to modify a few files in Julia's base directory
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")

    # Replace definitions of `libblas_name`, etc.. to point to MKL
    replace_libblas(base_dir, libmkl_rt)

    # Force-setting `ENV["PATH"]` to include the location of MKL libraries
    # This is required on Windows, where we can't use RPATH
    @info("Checking if we need to update PATH...")
    if Sys.iswindows()
        force_proper_PATH(base_dir, dirname(libmkl_rt))
    end

    # Next, build a new system image
    generate_precompile_statments()
    PackageCompilerX.create_sysimage(:MKL, cpu_target="native", precompile_statements_file="precomp_stmt.jl", incremental=false, replace_default=false, sysimage_path="/Users/david/code/julia_mkl/MKL.jl/sysimg/out") #! replace & no path
end

function enable_openblas_startup(libopenblas = "libopenblas")
    # First, we need to modify a few files in Julia's base directory
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")

    # Replace definitions of `libblas_name`, etc.. to point to MKL
    if Sys.WORD_SIZE == 64
        libopenblas = "$(libopenblas)64_"
    end
    replace_libblas(base_dir, libopenblas)

    # Next, build a new system image
    sysimgpath = PackageCompiler.sysimgbackup_folder("native")
    if ispath(sysimgpath)
        rm(sysimgpath, recursive=true)
    end
    force_native_image!()
end
