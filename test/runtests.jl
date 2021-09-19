using MKL, MKL_jll, Test
import LinearAlgebra

@show LinearAlgebra.BLAS.get_config()

if VERSION > MKL.JULIA_VER_NEEDED
    @test LinearAlgebra.BLAS.get_config().loaded_libs[1].libname == libmkl_rt
else
    @test LinearAlgebra.BLAS.vendor() == :mkl
end

@test LinearAlgebra.peakflops() > 0

include(joinpath(Sys.STDLIB, "LinearAlgebra", "test", "runtests.jl"))
