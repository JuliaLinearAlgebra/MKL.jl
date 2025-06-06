# MKL.jl

## Using Julia with Intel's MKL

MKL.jl is a Julia package that allows users to use the Intel MKL library for Julia's underlying BLAS and LAPACK, instead of OpenBLAS, which Julia ships with by default. Julia includes [libblastrampoline](https://github.com/staticfloat/libblastrampoline), which enables picking a BLAS and LAPACK library at runtime. A [JuliaCon 2021 talk](https://www.youtube.com/watch?v=t6hptekOR7s) provides details on this mechanism. 

This package requires Julia 1.8+, and only covers the forwarding of BLAS and LAPACK routines in Julia to MKL. Other packages like [IntelVectorMath.jl](https://github.com/JuliaMath/IntelVectorMath.jl), [Pardiso.jl](https://github.com/JuliaSparse/Pardiso.jl), etc. wrap more of MKL's functionality. The [oneAPI.jl](https://github.com/JuliaGPU/oneAPI.jl) package provides support for Intel OneAPI and Intel GPUs.

## Usage

If you want to use `MKL.jl` in your project, make sure it is the first package you load before any other package. It is essential that MKL be loaded before other packages so that it can find the Intel OMP library and avoid [issues resulting out of GNU OMP being loaded first](https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/700).

## To Install:

Adding the package will replace the system BLAS and LAPACK with MKL provided ones at runtime. Note that the MKL package has to be loaded in every new Julia process. Upon quitting and restarting, Julia will start with the default OpenBLAS.
```julia
julia> using Pkg; Pkg.add("MKL")
```
***Hint:*** On Windows the installation might fail due to a missing library with the name `VCRUNTIME140.dll`. To install it, download and execute https://aka.ms/vs/17/release/vc_redist.x64.exe .

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

## Threading control

To set or get the global number of threads used by `MKL`, use `MKL.{set/get}_num_threads`. This does not affect specific domains where the number of threads is set with [`mkl_domain_set_num_threads`](https://www.intel.com/content/www/us/en/docs/onemkl/developer-reference-c/2025-0/mkl-domain-set-num-threads.html). Calling `LinearAlgebra.BLAS.{set/get}_num_threads` is domain-specific and only refers to the `BLAS` domain (unlike other backends, where the number of threads used by `LAPACK` is also modified).

## NOTE: Using MKL with Distributed

If you are using `Distributed` for parallelism on a single node, set MKL to single threaded mode to [avoid over subcribing](https://github.com/JuliaLinearAlgebra/MKL.jl/issues/122) the CPUs. 

```julia
MKL.set_num_threads(1)
```

## NOTE: MKL on Intel Macs
MKL for Intel Macs is discontinued as of MKL 2024. Thus, in order to use MKL on Intel Macs, you will need to install the right version of `MKL_jll` and possibly also pin it.

```julia
julia> Pkg.add(name="MKL_jll", version="2023");
   Resolving package versions...
    Updating `~/.julia/environments/v1.10/Project.toml`
⌃ [856f044c] + MKL_jll v2023.2.0+0
  No Changes to `~/.julia/environments/v1.10/Manifest.toml`

julia> Pkg.pin(name="MKL_jll", version="2023");
   Resolving package versions...
    Updating `~/.julia/environments/v1.10/Project.toml`
⌃ [856f044c] ~ MKL_jll v2023.2.0+0 ⇒ v2023.2.0+0 ⚲
    Updating `~/.julia/environments/v1.10/Manifest.toml`
⌃ [856f044c] ~ MKL_jll v2023.2.0+0 ⇒ v2023.2.0+0 ⚲
        Info Packages marked with ⌃ have new versions available and may be upgradable.
```

MKL seems to have [some issues](https://github.com/JuliaLinearAlgebra/MKL.jl/issues/129) on Intel Macs when multi-threading is enabled. Threading can be disabled in such cases with:

```julia
MKL.set_threading_layer(THREADING_SEQUENTIAL)
```
