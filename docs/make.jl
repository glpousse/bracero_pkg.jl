using bracero_pkg
using Documenter

DocMeta.setdocmeta!(bracero_pkg, :DocTestSetup, :(using bracero_pkg); recursive=true)

makedocs(;
    modules=[bracero_pkg],
    authors="glpousse <161320409+glpousse@users.noreply.github.com> and contributors",
    sitename="bracero_pkg.jl",
    format=Documenter.HTML(;
        canonical="https://glpousse.github.io/bracero_pkg.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/glpousse/bracero_pkg.jl",
    devbranch="main",
)
