#!/bin/bash
set -ev

julia --color=yes -e "if VERSION < v\"0.7.0-DEV.5183\"; Pkg.clone(pwd()); Pkg.build(\"${JL_PKG}\"); else using Pkg; if VERSION >= v\"1.1.0-rc1\"; Pkg.build(verbose=true); else Pkg.build(); end; end"
travis_wait julia --check-bounds=yes --color=yes -e "if VERSION < v\"0.7.0-DEV.5183\"; Pkg.test(\"${JL_PKG}\", coverage=true); else using Pkg; Pkg.test(coverage=true); end"