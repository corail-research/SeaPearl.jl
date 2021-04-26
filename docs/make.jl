using Documenter
using SeaPearl

makedocs(
    sitename = "SeaPearl",
    doctest = VERSION >= v"1.4",
    format = Documenter.HTML(),
    modules = [SeaPearl],
    pages = ["Home" => "index.md",
    "Constraint Programming solver" => [
        "Variables" => "CP/int_variable.md",
        "Trailer" => "CP/trailer.md",
    ],
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
