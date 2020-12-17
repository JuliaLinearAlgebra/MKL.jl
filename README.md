# MKL.jl
## Intel MKL linear algebra in Julia.

[![Build Status](https://travis-ci.org/JuliaComputing/MKL.jl.svg?branch=master)](https://travis-ci.org/JuliaComputing/MKL.jl)

*MKL.jl* is a package that makes Julia's linear algebra use Intel MKL BLAS and LAPACK instead of OpenBLAS. The build step of the package will automatically download Intel MKL and rebuild Julia's system image against Intel MKL.

**Note:** MKL.jl replaces OpenBLAS with MKL for dense linear algebra functions called directly from Julia, but SuiteSparse and other C/Fortran libraries will continue to use the BLAS they were linked against at build time. If you want SuiteSparse to use MKL, you will need to build Julia from source with MKL support.

## To Install:

```julia
julia>] add MKL
```
After installation it should build automatically (which takes some time). If building was not triggered automatically (happens when MKL download is done already on the system), run the following command:
```julia
julia>] build MKL
```
Then after building restart Julia.


## To Check Installation:

Once the install has completed, you'll have

```julia
julia> using LinearAlgebra

julia> BLAS.vendor()
:mkl
```
and all Julia's dense linear algebra routines ranging from matrix multiply, over solving linear systems of equations, to eigenvalue computations will be computed by Intel MKL. In many cases, this will greatly improve the execution time.


## Using the 64-bit vs 32-bit version of MKL

By default, when building *MKL.jl* the 32-bit version of MKL is installed. This is due to frequently encountered compatibility issues with the MKL version linked to *numpy*, that by default is shipped with the 32-bit version of MKL. To use the 64-bit version of MKL set the environment variable `ENV["USE_BLAS64"] = true` before building *MKL.jl*.
