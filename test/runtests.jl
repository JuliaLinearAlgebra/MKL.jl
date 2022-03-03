import LinearAlgebra

# Set up a debugging fallback function that prints out a stacktrace if the LinearAlgebra
# tests end up calling a function that we don't have forwarded.
function debug_missing_function()
    println("Missing BLAS/LAPACK function!")
    display(stacktrace())
end
LinearAlgebra.BLAS.lbt_set_default_func(@cfunction(debug_missing_function, Cvoid, ()))

using MKL_jll, MKL, Test, SpecialFunctions
@show LinearAlgebra.BLAS.get_config()

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

# Run all the LinearAlgebra stdlib tests
include(joinpath(Sys.STDLIB, "LinearAlgebra", "test", "runtests.jl"))
