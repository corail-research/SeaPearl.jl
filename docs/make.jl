using Documenter
using SeaPearl

makedocs(
    sitename = "SeaPearl.jl",
    doctest = VERSION >= v"1.4",
    format = Documenter.HTML(),
    modules = [SeaPearl],
    pages = ["Home" => "index.md",
    "Constraint Programming solver" => [
        "Constraints" => "CP/constraints.md",
        "Variables" => "CP/variables.md",
        "Trailer" => "CP/trailer.md",
        "Internals" => "CP/internals.md",
        "Search" => "CP/search.md",
        "Instance Generation" => "CP/datagen.md"
    ],
    "Reinforcement Learning" => "reinforcement_learning.md",
    # "Building Models" =>
    #   ["Basics" => "models/basics.md"],
    "Community" => "community.md"],
)

deploydocs(
    repo = "github.com/corail-research/SeaPearl.jl.git",
    push_preview = true,
)
