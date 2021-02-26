# MKL.jl
## Intel MKL linear algebra in Julia.

[![Build Status](https://travis-ci.org/JuliaComputing/MKL.jl.svg?branch=master)](https://travis-ci.org/JuliaComputing/MKL.jl)

*MKL.jl* is a package that makes Julia's linear algebra use Intel MKL BLAS and LAPACK instead of OpenBLAS.

**Note:** Because of the use of libblastrampoline (LBT), MKL.jl replaces OpenBLAS for all usage of BLAS, for all libraries linked to LBT.

## To Install:

```julia
julia>] add MKL
```

## To Check Installation:

Once the install has completed, you'll have

```julia
julia> using LinearAlgebra

julia> BLAS.get_config()
LinearAlgebra.BLAS.LBTConfig(LinearAlgebra.BLAS.LBTLibraryInfo[LinearAlgebra.BLAS.LBTLibraryInfo("/Users/viral/.julia/artifacts/073ff95e2c63501547247d6e1321bf4ee2a78933/lib/libmkl_rt.1.dylib", Ptr{Nothing} @0x00007fd01063e090, "", UInt8[0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff  …  0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01], :ilp64, :plain)], [:f2c_capable], ["LAPACKE_c_nancheck", "LAPACKE_cbbcsd", "LAPACKE_cbbcsd_work", "LAPACKE_cbdsqr", "LAPACKE_cbdsqr_work", "LAPACKE_cgb_nancheck", "LAPACKE_cgb_trans", "LAPACKE_cgbbrd", "LAPACKE_cgbbrd_work", "LAPACKE_cgbcon"  …  "zunmlq_", "zunmql_", "zunmqr_", "zunmr2_", "zunmr3_", "zunmrq_", "zunmrz_", "zunmtr_", "zupgtr_", "zupmtr_"])
```
and all Julia's dense linear algebra routines ranging from matrix multiply, over solving linear systems of equations, eigenvalue computations, and sparse linear algebra (SuiteSparse calling MKL) will be computed by Intel MKL. In many cases, this will greatly improve the execution time.
