using PackageCompiler
using MKL_jll

# ENV["USE_INTEL_MKL"] decides whether we are
# enabling MKL (true, default) or OpenBLAS (false).
const USEINTELMKL = parse(Bool,get(ENV, "USE_INTEL_MKL","true"))

# ENV["USE_BLAS64"] decides wheter we use 64 bit (true) or 32 bit (false, default) BLAS.
# If USEINTELMKL == false, i.e. we are enabling OpenBLAS, the user setting
# is overwritten and we always USEBLAS64 = true.
const USEBLAS64 = USEINTELMKL ? parse(Bool,get(ENV, "USE_BLAS64","false")) : true

include("../src/install.jl")

if USEINTELMKL
	@info "Enabling Intel MKL...."
	enable_mkl_startup()
else
	@info "Enabling OpenBLAS...."
	enable_openblas_startup()
end
