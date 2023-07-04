# MKL.jl

## Using Julia with Intel's MKL

MKL.jl is a Julia package that allows users to use the Intel MKL library for Julia's underlying BLAS and LAPACK, instead of OpenBLAS, which Julia ships with by default. Julia includes [libblastrampoline](https://github.com/staticfloat/libblastrampoline), which enables picking a BLAS and LAPACK library at runtime. A [JuliaCon 2021 talk](https://www.youtube.com/watch?v=t6hptekOR7s) provides details on this mechanism. 

This package requires Julia 1.7+

## Usage

If you want to use `MKL.jl` in your project, make sure it is the first package you load before any other package. It is essential that MKL be loaded before other packages so that it can find the Intel OMP library and avoid [issues resulting out of GNU OMP being loaded first](https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/700).

## Installation (Julia 1.7 and newer):

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

Note that you can put `using MKL` into your `startup.jl` to make Julia automatically use Intel MKL in every session.

## Using the 64-bit vs 32-bit version of MKL

We use ILP64 by default on 64-bit systems, and LP64 on 32-bit systems.

## Using a preinstalled Intel MKL

If you already have an Intel MKL installation available (as on most HPC clusters), you can use the the environment variable `JULIA_MKL_PATH` or the [preference](https://github.com/JuliaPackaging/Preferences.jl) `mkl_path` to hint MKL.jl to the `libmkl_rt` library. Specifically, the options are:

* `mkl_jll` (default): Download and install MKL via [MKL_jll.jl](https://github.com/JuliaBinaryWrappers/MKL_jll.jl).
* `system`: The package will try to automatically locate the libmkl_rt library (i.e. find it on the linker search path).
* `path/to/my/libmkl_rt.<EXT>`: Explicit path to the `libmkl_rt.<EXT>` where `<EXT>` is the shared library extension of the system at hand (e.g. `.so`, `.dll`, `.dylib`)

Note that, in contrast to the preference, the environment variable only has an effect when MKL.jl is (re-)precompiled. To force a change of the MKL path after the compilation has happened, use the function `MKL.set_mkl_path`, which takes the options listed above as input.
