# MKL.jl
## Intel MKL linear algebra in Julia.

[![Build Status](https://travis-ci.org/JuliaComputing/MKL.jl.svg?branch=master)](https://travis-ci.org/JuliaComputing/MKL.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/n37h9eagmnx1gly0/branch/master?svg=true)](https://ci.appveyor.com/project/andreasnoack/mkl-jl/branch/master)

*MKL.jl* is a package that makes Julia's linear algebra use Intel MKL BLAS and LAPACK instead of OpenBLAS. The build step of the package will automatically download Intel MKL and rebuild Julia's system image against Intel MKL. Once the install has completed, you'll have

```
julia> using LinearAlgebra

julia> BLAS.vendor()
:mkl
```
and all Julia's dense linear algebra routines ranging from matrix multiply, over solving linear systems of equations, to eigenvalue computations will be computed by Intel MKL. In many cases, this will greatly improve the execution time.

### Warning

- Downstream binary libraries that depend on BLAS such as SuiteSparse (solving sparse linear systems) and ARPACK (for large scale eigevalue computations) will currently not work once MKL.jl has been installed. We are working on removing these limitations.

- It is not possible to revert the effect of install MKL.jl. To return to OpenBLAS, it is necessary to reinstall Julia.

- The current version of MKL.jl doesn't have access to the same precompilation information as the official binaries and source builds so the REPL will have more latency after MKL.jl has been installed. It should be possible to fix this once Julia 1.1 has been released. See https://github.com/JuliaComputing/MKL.jl/issues/1.
