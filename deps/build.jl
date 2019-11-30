using Libdl
using PackageCompiler

include("build_IntelOpenMP.jl")
include("build_MKL.jl")
include("deps.jl")

include("../src/install.jl")
enable_mkl_startup(libmkl_rt)


julia_ = joinpath(Sys.BINDIR, Base.julia_exename())
cmd = `$julia_ fix_repl.jl`

run(cmd)
