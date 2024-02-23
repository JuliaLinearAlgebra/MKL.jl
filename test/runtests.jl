import LinearAlgebra, Pkg

# Set up a debugging fallback function that prints out a stacktrace if the LinearAlgebra
# tests end up calling a function that we don't have forwarded.
function debug_missing_function()
    println("Missing BLAS/LAPACK function!")
    display(stacktrace())
end
LinearAlgebra.BLAS.lbt_set_default_func(@cfunction(debug_missing_function, Cvoid, ()))

using MKL_jll, MKL, Test, SpecialFunctions, Pkg
@show LinearAlgebra.BLAS.get_config()

if Sys.isapple() && Sys.ARCH == :x86_64
    Pkg.add(name="MKL_jll", version="2023");
end

if !MKL_jll.is_available()
    @warn "MKL_jll is not available/installed. Exiting."
    exit()
end

@testset "Sanity Tests" begin
    @test LinearAlgebra.BLAS.get_config().loaded_libs[1].libname == libmkl_rt
    @test LinearAlgebra.peakflops() > 0
end

@testset "CBLAS dot test" begin
    a = ComplexF64[
        1 + 1im,
        2 - 2im,
        3 + 3im
    ]
    @test LinearAlgebra.BLAS.dotc(a, a) ≈ ComplexF64(28)
    @test LinearAlgebra.BLAS.dotu(a, a) ≈ ComplexF64(12im)

    a = Float32[1, 2, 3]
    @test LinearAlgebra.BLAS.dot(a, a) ≈ 14f0
end

# Test #98 - issues with multi-threaded MKL on mac
# Test https://github.com/JuliaLang/julia/issues/40787

@testset "Threading nondeterminism test" begin
    A = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5 -5; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 -5; -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -5 -5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];

    B = [1 0 0 0 0; 0 1 0 0 0; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0];

    for i=1:10
        @test sum(abs, A \ B) ≈ 24.772054506344045
    end
end

# Run all the LinearAlgebra stdlib tests, but with MKL.  We still
# use `Base.runtests()` to get multithreaded, distributed execution
# to cut down on CI times, and also to restart workers that trip over
# the testing RSS limit.  In order for distributed workers to use MKL,
# we'll modify the test source code so that it imports MKL:
mktempdir() do dir
    cp(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "test"), dir; force=true)

    # Prepend `using MKL` to `testdefs.jl`, so that all test workers load MKL
    testdefs_path = joinpath(dir, "testdefs.jl")
    chmod(testdefs_path, 0o644)
    testdefs_content = String(read(testdefs_path))
    open(testdefs_path, write=true) do io
        println(io, "using MKL")
        println(io, testdefs_content)
    end

    run(`$(Base.julia_cmd()) --project=$(Base.active_project()) $(dir)/runtests.jl LinearAlgebra/blas LinearAlgebra/lapack`)
end
