using Libdl
using PackageCompiler

include("build_IntelOpenMP.jl")
include("build_MKL.jl")
include("deps.jl")

# Read the build_h.jl file
fname = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base", "build_h.jl")
lines = open(fname) do f
    readlines(f, keep = true)
end

# Write path to MKL
lines = map(lines) do l
    if occursin(r"libblas_name", l)
        return "const libblas_name = $(repr(libmkl_rt))\n"
    elseif occursin(r"liblapack_name", l)
        return "const liblapack_name = $(repr(libmkl_rt))\n"
    else
        return l
    end
end

# Write the modified lines to the file
open(fname, "w") do f
    for l in lines
        write(f, l)
    end
end

sysimgpath = PackageCompiler.sysimgbackup_folder("native")
if ispath(sysimgpath)
    rm(sysimgpath, recursive=true)
end

force_native_image!()
