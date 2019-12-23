# IntelMKL.jl
## Intel MKL linear algebra in Julia.

[![Build Status](https://travis-ci.org/JuliaComputing/IntelMKL.jl.svg?branch=master)](https://travis-ci.org/JuliaComputing/IntelMKL.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/n37h9eagmnx1gly0/branch/master?svg=true)](https://ci.appveyor.com/project/andreasnoack/mkl-jl/branch/master)

*IntelMKL.jl* is a package that makes Julia's linear algebra use Intel MKL BLAS and LAPACK instead of OpenBLAS. The build step of the package will automatically download Intel MKL and rebuild Julia's system image against Intel MKL.

## To Install:

```julia
julia>]add https://github.com/JuliaComputing/IntelMKL.jl
```
After installation it should build automatically (which takes some time). If building was not triggered automatically (happens when MKL download is done already on the system), run the following command:
```julia
julia>] build IntelMKL
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
