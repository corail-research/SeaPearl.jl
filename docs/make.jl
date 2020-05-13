using Documenter
using CPRL

makedocs(
    sitename = "CPRL",
    format = Documenter.HTML(),
    modules = [CPRL]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
