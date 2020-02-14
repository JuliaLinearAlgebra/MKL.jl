module MKL

using MKL_jll

# We cannot depend on LinearAlgebra since we need to be loaded before it
if Base.USE_BLAS64
    const BlasInt = Int64
else
    const BlasInt = Int32
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

function set_threading_layer(layer::Threading = THREADING_INTEL)
    err = ccall((:MKL_Set_Threading_Layer, libmkl_rt), Cint,
        (Cint,), layer)
    if err == -1
        throw(ErrorException("return value was -1"))
    end
    return nothing
end

function set_interface_layer(interface = BlasInt == Int64 ? INTERFACE_ILP64 : INTERFACE_LP64)
    err = ccall((:MKL_Set_Interface_Layer, libmkl_rt), Cint,
        (Cint,), interface)
    if err == -1
        throw(ErrorException("return value was -1"))
    end
    return nothing
end

function __init__()
    set_threading_layer()
    set_interface_layer()
end

mklnorm(x::Vector{Float64}) = ccall((:dnrm2_, libmkl_rt), Float64,
    (Ref{BlasInt}, Ptr{Float64}, Ref{BlasInt}),
    length(x), x, 1)


# Include installation routines as well
include("install.jl")

end
