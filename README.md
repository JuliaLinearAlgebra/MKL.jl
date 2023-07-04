# MKL.jl

## Using Julia with Intel's MKL

MKL.jl is a Julia package that allows users to use the Intel MKL library for Julia's underlying BLAS and LAPACK, instead of OpenBLAS, which Julia ships with by default. Julia includes [libblastrampoline](https://github.com/staticfloat/libblastrampoline), which enables picking a BLAS and LAPACK library at runtime. A [JuliaCon 2021 talk](https://www.youtube.com/watch?v=t6hptekOR7s) provides details on this mechanism. 

This package requires Julia 1.7+.

## Installation

To install the package execute

```julia
julia> using Pkg; Pkg.add("MKL")
```

## Usage

Loading the package (`using MKL`) will replace the system BLAS and LAPACK with MKL provided ones at runtime. Make sure it is the first package you load before any other package. It is essential that MKL be loaded before other packages so that it can find the Intel OMP library and avoid [issues resulting out of GNU OMP being loaded first](https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/700).

Note that the MKL package has to be loaded in every new Julia process. Upon quitting and restarting, Julia will start with the default OpenBLAS.

## Check

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

Note that you can put `using MKL` into your `startup.jl` to make Julia automatically use Intel MKL in every session.

## Using the 64-bit vs 32-bit version of MKL

We use ILP64 by default on 64-bit systems, and LP64 on 32-bit systems.

## Using a system-provided Intel MKL

If you want to use a system-provided Intel MKL installation, you can set the [preference](https://github.com/JuliaPackaging/Preferences.jl) `mkl_path` to hint MKL.jl to the corresponding `libmkl_rt` library. Specifically, the options are:

* `mkl_jll` (default): Download and install MKL via [MKL_jll.jl](https://github.com/JuliaBinaryWrappers/MKL_jll.jl).
* `system`: The package will try to automatically locate the system-provided libmkl_rt library (i.e. find it on the linker search path).
* `path/to/my/libmkl_rt.<EXT>`: Explicit path to the `libmkl_rt.<EXT>` where `<EXT>` is the shared library extension of the system at hand (e.g. `.so`, `.dll`, `.dylib`)
