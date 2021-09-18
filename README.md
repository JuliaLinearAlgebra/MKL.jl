# MKL.jl
## Intel MKL linear algebra in Julia.

*MKL.jl* is a package that makes Julia's linear algebra use Intel MKL BLAS and LAPACK instead of OpenBLAS. The build step of the package will automatically download Intel MKL and rebuild Julia's system image against Intel MKL for Julia versions prior to v1.7. On Julia v1.7 and later, we ship Julia with [libblastrampoline](https://github.com/staticfloat/libblastrampoline), which can enable picking a BLAS at runtime.

## To Install:

On Julia 1.7 and later:
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

On Julia 1.6 and earlier, when building *MKL.jl*, the 32-bit version of MKL is installed. This is due to frequently encountered compatibility issues with the MKL version linked to *numpy*, that by default is shipped with the 32-bit version of MKL. To use the 64-bit version of MKL set the environment variable `ENV["USE_BLAS64"] = true` before building *MKL.jl*. 

