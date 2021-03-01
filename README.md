# MKL.jl
## Intel MKL linear algebra in Julia.

*MKL.jl* is a package that makes Julia's linear algebra use Intel MKL BLAS and LAPACK instead of OpenBLAS. The build step of the package will automatically download Intel MKL and rebuild Julia's system image against Intel MKL for Julia versions prior to v1.7. On Julia v1.7 and later, we ship Julia with [libblastrampoline](https://github.com/staticfloat/libblastrampoline), which can enable picking a BLAS at runtime.

## To Install:

```julia
julia>] add MKL
```
On Julia 1.7 and later, nothing further is necessary. On older releases of Julia, a new system image build happens right after installation. If it doesn't (happens when MKL_jll.jl has been installed before), run the following command to build a new system image and restart Julia.
```julia
julia>] build MKL
```

## To Check Installation:

```julia
julia> using LinearAlgebra

julia> BLAS.vendor()  # Prior to Julia v1.7
:mkl

julia> BLAS.get_config()  # Julia v1.7 and later
LinearAlgebra.BLAS.LBTConfig(LinearAlgebra.BLAS.LBTLibraryInfo[LinearAlgebra.BLAS.LBTLibraryInfo("/Users/viral/.julia/artifacts/073ff95e2c63501547247d6e1321bf4ee2a78933/lib/libmkl_rt.1.dylib", Ptr{Nothing} @0x00007fb6a5ef4820, "", UInt8[0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff  …  0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01], :ilp64, :plain)], [:f2c_capable], ["LAPACKE_c_nancheck", "LAPACKE_cbbcsd", "LAPACKE_cbbcsd_work", "LAPACKE_cbdsqr", "LAPACKE_cbdsqr_work", "LAPACKE_cgb_nancheck", "LAPACKE_cgb_trans", "LAPACKE_cgbbrd", "LAPACKE_cgbbrd_work", "LAPACKE_cgbcon"  …  "zunmlq_", "zunmql_", "zunmqr_", "zunmr2_", "zunmr3_", "zunmrq_", "zunmrz_", "zunmtr_", "zupgtr_", "zupmtr_"])
```

## Using the 64-bit vs 32-bit version of MKL

By default, when building *MKL.jl* the 32-bit version of MKL is installed. This is due to frequently encountered compatibility issues with the MKL version linked to *numpy*, that by default is shipped with the 32-bit version of MKL. To use the 64-bit version of MKL set the environment variable `ENV["USE_BLAS64"] = true` before building *MKL.jl*. This is not supported on Julia v1.7 yet.
