module MKL

using Preferences
using Libdl
using LinearAlgebra

# Choose an MKL path; taking an explicit preference as the first choice,
# but if nothing is set as a preference, fall back to the default choice of `MKL_jll`.
const mkl_path = something(
    @load_preference("mkl_path", nothing),
    "mkl_jll",
)::String

if lowercase(mkl_path) == "mkl_jll"
    # Only load MKL_jll if we are suppoed to use it as the MKL source
    # to avoid an unnecessary download of the (lazy) artifact.
    import MKL_jll
    const mkl_found = MKL_jll.is_available()
    const libmkl_rt = mkl_found ? MKL_jll.libmkl_rt : nothing
elseif lowercase(mkl_path) == "system"
    # We expect the "system" MKL to already be loaded,
    # or be on our linker search path.
    libname = string("libmkl_rt", ".", Libdl.dlext)
    const libmkl_rt = find_library(libname, [""])
    const mkl_found = libmkl_rt != ""
    mkl_found || @warn("Couldn't find $libname. Try to specify the path to `libmkl_rt` explicitly.")
else
    # mkl_path should be a valid path to libmkl_rt.
    const libmkl_rt = mkl_path
    const mkl_found = isfile(libmkl_rt)
    mkl_found || @warn("Couldn't find MKL library at $libmkl_rt.")
end

# Changing the MKL provider/path preference
function set_mkl_path(path)
    if lowercase(path) ∉ ("mkl_jll", "system") && !isfile(path)
        error("The provided argument $path neither seems to be a valid path to libmkl_rt nor \"mkl_jll\" or \"system\".")
    end
    @set_preferences!("mkl_path" => path)
    @info("New MKL preference set; please restart Julia to see this take effect", path)
end

using LinearAlgebra

if Base.USE_BLAS64
    const MKLBlasInt = Int64
else
    const MKLBlasInt = Int32
end

@enum Threading begin
    THREADING_INTEL
    THREADING_SEQUENTIAL
    THREADING_PGI
    THREADING_GNU
    THREADING_TBB
end

@enum Interface begin
    INTERFACE_LP64
    INTERFACE_ILP64
    INTERFACE_GNU
end

function set_threading_layer(layer::Threading = THREADING_SEQUENTIAL)
    err = ccall((:MKL_Set_Threading_Layer, libmkl_rt), Cint, (Cint,), layer)
    err == -1 && throw(ErrorException("MKL_Set_Threading_Layer() returned -1"))
    return nothing
end

function set_interface_layer(interface::Interface = INTERFACE_LP64)
    err = ccall((:MKL_Set_Interface_Layer, libmkl_rt), Cint, (Cint,), interface)
    err == -1 && throw(ErrorException("MKL_Set_Interface_Layer() returned -1"))
    return nothing
end

function lbt_mkl_forwarding()
    if Sys.isapple()
        set_threading_layer(THREADING_SEQUENTIAL)
    end
    # MKL 2022 and onwards have 64_ for ILP64 suffixes. The LP64 interface
    # includes LP64 APIs for the non-suffixed symbols and ILP64 API for the
    # 64_ suffixed symbols. LBT4 in Julia is necessary for this to work.
    set_interface_layer(INTERFACE_LP64)
    if Base.USE_BLAS64
        # Load ILP64 forwards
        BLAS.lbt_forward(libmkl_rt; clear=true, suffix_hint="64")
        # Load LP64 forward
        BLAS.lbt_forward(libmkl_rt; suffix_hint="")
    else
        BLAS.lbt_forward(libmkl_rt; clear=true, suffix_hint="")
    end
    return nothing
end

function __init__()
    if mkl_found
        lbt_mkl_forwarding()
    else
        @warn("MKL library couldn't be found. Please make sure to set the `mkl_path` preference correctly (e.g. via `MKL.set_mkl_path`).")
    end
end

function mklnorm(x::Vector{Float64})
    ccall((:dnrm2_, libmkl_rt), Float64,
          (Ref{MKLBlasInt}, Ptr{Float64}, Ref{MKLBlasInt}), length(x), x, 1)
end

end # module
