using MKL, MKL_jll, Test
import LinearAlgebra

@show LinearAlgebra.BLAS.get_config()
@test LinearAlgebra.BLAS.get_config().loaded_libs[1].libname == libmkl_rt
@test LinearAlgebra.peakflops() > 0

include(joinpath(Sys.STDLIB, "LinearAlgebra", "test", "runtests.jl"))
