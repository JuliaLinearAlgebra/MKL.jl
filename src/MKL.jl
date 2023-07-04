module MKL

using Preferences
using Libdl

# Choose an MKL provider; taking an explicit preference as the first choice,
# but if nothing is set as a preference, fall back to an environment variable,
# and if that is not given, fall back to the default choice of `MKL_jll`.
const mkl_provider = lowercase(something(
    @load_preference("mkl_provider", nothing),
    get(ENV, "JULIA_MKL_PROVIDER", nothing),
    "mkl_jll",
)::String)

if mkl_provider == "mkl_jll"
    # Only load MKL_jll if we are suppoed to use it as the MKL source
    # to avoid an unnecessary download of the (lazy) artifact.
    import MKL_jll
    const libmkl_rt = MKL_jll.libmkl_rt
    const mkl_path = dirname(libmkl_rt)
elseif mkl_provider == "system"
    # We want to use a "system" MKL, so let's try to find it.
    # The user may provide the path to libmkl_rt via a preference
    # or an environment variable. Otherwise, we expect it to
    # already be loaded, or be on our linker search path.
    const mkl_path = lowercase(something(
        @load_preference("mkl_path", nothing),
        get(ENV, "JULIA_MKL_PATH", nothing),
        "",
    )::String)
    libname = string("libmkl_rt", ".", Libdl.dlext)
    const libmkl_rt = find_library(libname, [mkl_path])
    libmkl_rt == "" && error("Couldn't find $libname. Maybe try setting JULIA_MKL_PATH?")
else
    error("Invalid mkl_provider choice $(mkl_provider).")
end

# Changing the MKL provider preference
function set_mkl_provider(provider)
    if lowercase(provider) ∉ ("mkl_jll", "system")
        error("Invalid mkl_provider choice $(provider)")
    end
    @set_preferences!("mkl_provider" => lowercase(provider))

    @info("New MKL provider set; please restart Julia to see this take effect", provider)
end

<<<<<<< HEAD
using LinearAlgebra
=======
is_lbt_available() = VERSION > v"1.7.0-DEV.641"

is_lbt_available() && using LinearAlgebra
>>>>>>> f0b81d6 (add Libdl.ext to MKL.libmkl_rt)

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

function __init__()
    if MKL_jll.is_available()
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
    end
end

function mklnorm(x::Vector{Float64})
    ccall((:dnrm2_, libmkl_rt), Float64,
          (Ref{MKLBlasInt}, Ptr{Float64}, Ref{MKLBlasInt}), length(x), x, 1)
end

end # module
