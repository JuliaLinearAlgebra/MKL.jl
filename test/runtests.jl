using LinearAlgebra
using MKL
using MKL_jll
using Test

@test BLAS.get_config().loaded_libs[1].libname == libmkl_rt
@test LinearAlgebra.peakflops() > 0
