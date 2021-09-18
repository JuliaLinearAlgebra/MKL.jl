# MKL.jl
## Using Julia with Intel's MKL

MKL.jl is a Julia package that allows users to use the Intel MKL library for Julia's underlying BLAS and LAPACK, instead of OpenBLAS, which Julia ships with by default. On Julia v1.7 and later, Julia includes [libblastrampoline](https://github.com/staticfloat/libblastrampoline), which enables picking a BLAS and LAPACK library at runtime. A [JuliaCon 2021 talk](https://www.youtube.com/watch?v=t6hptekOR7s) provides details on this mechanism. 

On Julia 1.6 and earlier, adding this package will rebuild Julia's system image with MKL support built in.

## To Install:

On Julia 1.7 and later, adding the package will replace the system BLAS and LAPACK with MKL provided ones at runtime. Note that the MKL package has to be loaded in every new Julia process. Upon quitting and restarting, Julia will start with the default OpenBLAS.
```julia
julia> using Pkg; Pkg.add("MKL")
```

On 1.6 and earlier, a new system image is built upon installing this package. If it doesn't happen successfully (happens when MKL_jll.jl has been installed before), run the following command to build a new system image and restart Julia.
```julia
julia> using Pkg; Pkg.build("MKL")
```

## To Check Installation:

On Julia 1.7 and later:
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

On Julia 1.6 and earlier:
```
julia> BLAS.vendor()
:mkl
```


## Using the 64-bit vs 32-bit version of MKL

On Julia v1.7 and later, we use ILP64 by default on 64-bit systems, and LP64 on 32-bit systems.

On Julia 1.6 and earlier, when building *MKL.jl*, the 32-bit version of MKL is installed. This is due to frequently encountered compatibility issues with the MKL version linked to *numpy*, which by default is shipped with the 32-bit version of MKL. To use the 64-bit version of MKL, set the environment variable `ENV["USE_BLAS64"] = true` before building *MKL.jl*. 

