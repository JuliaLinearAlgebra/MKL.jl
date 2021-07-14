# using MKL
using Preferences
using Pkg
using Libdl

const JULIA_VER_NEEDED = v"1.7.0-DEV.641"
is_lbt_available() = VERSION > JULIA_VER_NEEDED

function find_uuid_in_project(name)
    get(Pkg.Types.EnvCache().project.deps, name, nothing)
end

if is_lbt_available()
    # Julia version >= 1.7: Use LBT
    const MKL_uuid = find_uuid_in_project("MKL")

    # 1. update preferences based on env variables if necessary
    if haskey(ENV, "JULIA_MKL_USE_JLL")
        use_jll = lowercase(get(ENV, "JULIA_MKL_USE_JLL", "true"))
        set_preferences!(MKL_uuid, "use_jll" => use_jll)
    end

    if haskey(ENV, "JULIA_MKL_PATH")
        mkl_path = lowercase(get(ENV, "JULIA_MKL_PATH", "true"))
        set_preferences!(MKL_uuid, "mkl_path" => mkl_path)
    end

    @show has_preference(MKL_uuid, "use_jll")

    # 2. set up libraries
    use_jll = load_preference(MKL_uuid, "use_jll", "true")
    mkl_path = load_preference(MKL_uuid, "mkl_path", "")

    if parse(Bool, use_jll)
        @info "MKL provider: MKL_jll (default)."
        using MKL_jll # force download of artifacts
    else
        @info "MKL provider: System"
        mkl_path != "" && (@info "Explicit MKL path set: ")

        @info "Checking availability of libmkl_core and libmkl_rt"
        if find_library(["libmkl_core"], mkl_path) == ""
            error("libmkl_core could not be found")
        end
        if find_library(["libmkl_rt"], mkl_path) == ""
            error("libmkl_rt could not be found")
        end
    end
else
    # Julia versions < 1.7: Build a custom system image
    using PackageCompiler
    using MKL_jll

    # if no environment variable ENV["USE_BLAS64"] is set install.jl
    # tries to change USE_BLAS64 = false
    const USEBLAS64 = parse(Bool,get(ENV, "USE_BLAS64","false"))

    include("../src/install.jl")
    enable_mkl_startup()
end

# Why?
using MKL