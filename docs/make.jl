using Documenter
using CPRL

makedocs(
    sitename = "CPRL",
    doctest = VERSION >= v"1.4",
    format = Documenter.HTML(),
    modules = [CPRL],
    pages = ["Home" => "index.md",
    "Building Models" =>
      ["Basics" => "models/basics.md"],
    "Community" => "community.md"],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
