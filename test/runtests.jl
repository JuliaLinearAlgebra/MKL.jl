using Test
using LinearAlgebra

@test BLAS.vendor == :mkl
