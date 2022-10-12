# MKL.jl

## Using Julia with Intel's MKL

MKL.jl is a Julia package that allows users to use the Intel MKL library for Julia's underlying BLAS and LAPACK, instead of OpenBLAS, which Julia ships with by default. Julia includes [libblastrampoline](https://github.com/staticfloat/libblastrampoline), which enables picking a BLAS and LAPACK library at runtime. A [JuliaCon 2021 talk](https://www.youtube.com/watch?v=t6hptekOR7s) provides details on this mechanism. 

This package requires Julia 1.7+

## Usage

If you want to use `MKL.jl` in your project, make sure it is the first package you load before any other package. It is essential that MKL be loaded before other packages so that it can find the Intel OMP library and avoid [issues resulting out of GNU OMP being loaded first](https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/700).

## To Install:

Adding the package will replace the system BLAS and LAPACK with MKL provided ones at runtime. Note that the MKL package has to be loaded in every new Julia process. Upon quitting and restarting, Julia will start with the default OpenBLAS.
```julia
julia> using Pkg; Pkg.add("MKL")
```

## To Check Installation:

```julia
julia> using LinearAlgebra

julia> BLAS.get_config()
LinearAlgebra.BLAS.LBTConfig
Libraries: 
└ [ILP64] libopenblas64_.0.3.13.dylib

julia> using MKL

julia> BLAS.get_config()
LinearAlgebra.BLAS.LBTConfig
Libraries: 
└ [ILP64] libmkl_rt.1.dylib
```

## Using the 64-bit vs 32-bit version of MKL

We use ILP64 by default on 64-bit systems, and LP64 on 32-bit systems.
