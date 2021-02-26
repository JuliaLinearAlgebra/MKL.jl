module MKL

using LinearAlgebra
using MKL_jll

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

function set_threading_layer(layer::Threading = THREADING_INTEL)
    err = ccall((:MKL_Set_Threading_Layer, libmkl_rt), Cint, (Cint,), layer)
    err == -1 && throw(ErrorException("return value was -1"))
    return nothing
end

function set_interface_layer(interface = BLAS.BlasInt == Int64 ? INTERFACE_ILP64 : INTERFACE_LP64)
    err = ccall((:MKL_Set_Interface_Layer, libmkl_rt), Cint, (Cint,), interface)
    err == -1 && throw(ErrorException("return value was -1"))
    return nothing
end

function __init__()
    if MKL_jll.is_available()
        set_threading_layer()
        set_interface_layer()
        BLAS.lbt_forward(libmkl_rt, clear=true)
    end
end

function mklnorm(x::Vector{Float64})
    ccall((:dnrm2_, libmkl_rt), Float64,
          (Ref{BLAS.BlasInt}, Ptr{Float64}, Ref{BLAS.BlasInt}),
          length(x), x, 1)
end


end # module
