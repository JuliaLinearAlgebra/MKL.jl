module MKL

using MKL_jll

using LinearAlgebra, Logging

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
    lbt_forward_to_mkl()
end

function lbt_forward_to_mkl()
    if !MKL_jll.is_available()
        isinteractive() && @warn "MKL is not available/installed."
        return
    end

    # MKL 2024.1 and onwards have 64_ for ILP64 suffixes. The LP64 interface
    # includes LP64 APIs for the non-suffixed symbols and ILP64 API for the
    # 64_ suffixed symbols. LBT4 in Julia is necessary for this to work.
    set_interface_layer(INTERFACE_LP64)
    if Base.USE_BLAS64
        # Load ILP64 forwards
        BLAS.lbt_forward(libmkl_rt; clear=true, suffix_hint="64")
        # Load LP64 forwards
        BLAS.lbt_forward(libmkl_rt; suffix_hint="")
    else
        BLAS.lbt_forward(libmkl_rt; clear=true, suffix_hint="")
    end
end

function mklnorm(x::Vector{Float64})
    ccall((:dnrm2_, libmkl_rt), Float64,
          (Ref{LinearAlgebra.BlasInt}, Ptr{Float64}, Ref{LinearAlgebra.BlasInt}), length(x), x, 1)
end

function set_num_threads(n::LinearAlgebra.BlasInt)
    ccall((:mkl_set_num_threads, libmkl_rt), Cvoid, (Ref{LinearAlgebra.BlasInt},), n)
end

function get_num_threads()::LinearAlgebra.BlasInt
    ccall((:mkl_get_max_threads, libmkl_rt), LinearAlgebra.BlasInt, ())
end
end # module
