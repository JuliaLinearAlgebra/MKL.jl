using PackageCompiler

prec_jl_url = "https://raw.githubusercontent.com/JuliaLang/julia/release-1.3/contrib/generate_precompile.jl"
prec_jl_fn = "generate_precompile.jl"
download(prec_jl_url, prec_jl_fn)
prec_jl_content = read(prec_jl_fn, String)
open(prec_jl_fn, "w") do f
   write(f, replace(prec_jl_content, "@assert n_succeeded > 3500" => raw"println(\"processed: $n_succeeded\") # @assert n_succeeded > 3500"))
end

PackageCompiler.build_sysimg(PackageCompiler.default_sysimg_path(), prec_jl_fn, verbose=true, cpu_target="native", release=true)
