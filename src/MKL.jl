module MKL

using Preferences

const JULIA_VER_NEEDED = v"1.7.0-DEV.641"
is_lbt_available() = VERSION > JULIA_VER_NEEDED

const use_jll = parse(Bool, @load_preference("use_jll", "true"))

const MKL_uuid = Base.PkgId(MKL).uuid
@show use_jll
@show has_preference(MKL_uuid, "use_jll")
@show load_preference(MKL_uuid, "use_jll")

if use_jll
    # MKL_jll
    using MKL_jll
    MKL_jll.is_available() || error("MKL.jl not properly configured, please run `Pkg.build(\"MKL\")`.")
else
    # System MKL
    using Libdl
    mkl_path = @load_preference("mkl_path", "")
    @show mkl_path
    const libmkl_core = find_library(["libmkl_core"], mkl_path == "" ? [""] : [mkl_path])
    @show libmkl_core
    const libmkl_rt = find_library(["libmkl_rt"], mkl_path == "" ? [""] : [mkl_path])
    @show libmkl_rt
    @show x = dlopen(libmkl_rt)
    @show dlclose(x)
    if libmkl_core == "" || libmkl_rt == ""
        error("MKL.jl not properly configured, please run `Pkg.build(\"MKL\")`.")
    end
end

is_lbt_available() && using LinearAlgebra

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

function set_threading_layer(layer::Threading = THREADING_INTEL)
    err = ccall((:MKL_Set_Threading_Layer, libmkl_rt), Cint, (Cint,), layer)
    err == -1 && throw(ErrorException("return value was -1"))
    return nothing
end

function set_interface_layer(interface = Base.USE_BLAS64 ? INTERFACE_ILP64 : INTERFACE_LP64)
    err = ccall((:MKL_Set_Interface_Layer, libmkl_rt), Cint, (Cint,), interface)
    err == -1 && throw(ErrorException("return value was -1"))
    return nothing
end

function __init__()
    # if MKL_jll.is_available()
    # set_threading_layer()
    # set_interface_layer()
    # is_lbt_available() && BLAS.lbt_forward(libmkl_rt, clear=true)
    # end
end

function mklnorm(x::Vector{Float64})
    ccall((:dnrm2_, libmkl_rt), Float64,
          (Ref{MKLBlasInt}, Ptr{Float64}, Ref{MKLBlasInt}),
          length(x), x, 1)
end

# Carsten: Unnecessary?!
is_lbt_available() && include("install.jl")

end # module
