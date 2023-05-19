var documenterSearchIndex = {"docs":
[{"location":"models/basics/#Building-a-model:-the-basics","page":"Basics","title":"Building a model: the basics","text":"","category":"section"},{"location":"models/basics/","page":"Basics","title":"Basics","text":"Using JuMP, you can create a really simple model.","category":"page"},{"location":"CP/performance_test/#Performance-test-Gecode-vs-SeaPearl","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"","category":"section"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"The objective is to compare the execution time between SeaPearl and a commercial CP Solver.","category":"page"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"We expect SeaPearl to be less efficient for 2 reasons:","category":"page"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"Information is collected on each node in order to do further analysis (RL).\nSome constraints algorithms are not state-of-the-art algorithms.","category":"page"},{"location":"CP/performance_test/#Method","page":"Performance test - Gecode vs SeaPearl","title":"Method","text":"","category":"section"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"The commercial CP solver used is Gecode and the model has been implemented using MiniZinc.  The problem used for the experience is the Kidney Exchange Problem (KEP) using 7 instances from size 5 to 35 (step size of 5).  A basic model has been implemented in MiniZinc and SeaPearl using the same logic (variables, constraints, heuristics...).","category":"page"},{"location":"CP/performance_test/#Results-and-conclusions","page":"Performance test - Gecode vs SeaPearl","title":"Results and conclusions","text":"","category":"section"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"The main observations from the experience are:","category":"page"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"The time of execution grows over-polynomially with the size of the instance. This result was expected for this combinatorial problem.\nFor instances with significant time of execution (more than 1 second), Gecode is on average 7.5 times faster than SeaPearl.","category":"page"},{"location":"CP/performance_test/#PS:-Tips-to-do-a-performance-test-with-SeaPearl","page":"Performance test - Gecode vs SeaPearl","title":"PS: Tips to do a performance test with SeaPearl","text":"","category":"section"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"Some tips to implement a model in MiniZinc and SeaPearl with similar behavior:","category":"page"},{"location":"CP/performance_test/","page":"Performance test - Gecode vs SeaPearl","title":"Performance test - Gecode vs SeaPearl","text":"In MiniZinc use these arguments for the search: first_fail, indomain_max, complete.\nIn SeaPearl use these arguments for the search: MinDomainVariableSelection, BasicHeuristic, DFSearch (by default).\nfirst_fail and MinDomainVariableSelection do not have the same behavior in the tie (many variables having the domain with the same minimum size). first_fail uses the input order for tie-breaker. Therefore, one option is to change MinDomainVariableSelection to have the same behavior (e.g. use a counter for the id of the variables and add a lexicographical tie-breaker in MinDomainVariableSelection).\nCheck the number of explored nodes in both models. One should have similar values for each instance. One can check this information in SeaPearl thanks to model.statistics.numberOfNodes and in MiniZinc by checking the output solving statistics checkbox in the configuration editor menu.","category":"page"},{"location":"CP/constraints/#Constraints","page":"Constraints","title":"Constraints","text":"","category":"section"},{"location":"CP/constraints/","page":"Constraints","title":"Constraints","text":"SeaPearl.Absolute","category":"page"},{"location":"CP/constraints/#SeaPearl.Absolute","page":"Constraints","title":"SeaPearl.Absolute","text":"Absolute(x::SeaPearl.AbstractIntVar, y::SeaPearl.AbstractIntVar, ::SeaPearl.Trailer)\n\nAbsolute value constraint, enforcing y = |x|.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/","page":"Constraints","title":"Constraints","text":"SeaPearl.AllDifferent","category":"page"},{"location":"CP/constraints/#SeaPearl.AllDifferent","page":"Constraints","title":"SeaPearl.AllDifferent","text":"AllDifferent(x::Array{<:AbstractIntVar}, trailer::SeaPearl.Trailer)\n\nAllDifferent constraint, enforcing ∀ i ≠ j ∈ ⟦1, length(x)⟧, x[i] ≠ x[j].\n\nThe implementation of this contraint is inspired by:  https://www.researchgate.net/publication/200034395AFilteringAlgorithmforConstraintsofDifferencein_CSPs Many of the functions below relate to algorithms depicted in the paper, and their documentation refer to parts of the overall algorithm.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/","page":"Constraints","title":"Constraints","text":"SeaPearl.BinaryEquivalence","category":"page"},{"location":"CP/constraints/#SeaPearl.BinaryEquivalence","page":"Constraints","title":"SeaPearl.BinaryEquivalence","text":"BinaryEquivalence(x::BoolVar, y::BoolVar, trailer::SeaPearl.Trailer)\n\nBinary equivalence constraint, states that x <=> y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/","page":"Constraints","title":"Constraints","text":"SeaPearl.BinaryImplication\nSeaPearl.BinaryMaximumBC\nSeaPearl.BinaryOr\nSeaPearl.BinaryXor\nSeaPearl.TableConstraint\nSeaPearl.BinaryImplication\nSeaPearl.Disjunctive\nSeaPearl.Element1D\nSeaPearl.Element2D\nSeaPearl.EqualConstant\nSeaPearl.GreaterOrEqualConstant\nSeaPearl.InSet\nSeaPearl.IntervalConstant\nSeaPearl.isBinaryAnd\nSeaPearl.isBinaryOr\nSeaPearl.isBinaryXor\nSeaPearl.isLessOrEqual\nSeaPearl.LessOrEqualConstant\nSeaPearl.LessOrEqual\nSeaPearl.MaximumConstraint\nSeaPearl.NotEqualConstant\nSeaPearl.NotEqual\nSeaPearl.ReifiedInSet\nSeaPearl.SetDiffSingleton\nSeaPearl.SetEqualConstant\nSeaPearl.SumGreaterThan\nSeaPearl.SumLessThan\nSeaPearl.SumToZero","category":"page"},{"location":"CP/constraints/#SeaPearl.BinaryImplication","page":"Constraints","title":"SeaPearl.BinaryImplication","text":"BinaryImplication(x::BoolVar, y::BoolVar, trailer::SeaPearl.Trailer)\n\nBinary implication constraint, states that x => y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.BinaryMaximumBC","page":"Constraints","title":"SeaPearl.BinaryMaximumBC","text":"BinaryMaximum(x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, trailer::SeaPearl.Trailer)\n\nBinaryMaximum constraint, states that x == max(y, z)\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.BinaryOr","page":"Constraints","title":"SeaPearl.BinaryOr","text":"BinaryOr(x::BoolVar, y::BoolVar, trailer::SeaPearl.Trailer)\n\nBinary Or constraint, states that x || y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.BinaryXor","page":"Constraints","title":"SeaPearl.BinaryXor","text":"BinaryXor(x::AbstractBoolVar, y::AbstractBoolVar, trailer::SeaPearl.Trailer)\n\nBinary Xor constraint, states that x ⊻ y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.TableConstraint","page":"Constraints","title":"SeaPearl.TableConstraint","text":"TableConstraint\n\nEfficient implentation of the constraint enforcing: ∃ j ∈ ⟦1,m⟧, such that ∀ i ∈ ⟦1,n⟧ xᵢ=table[i,j].\n\nThe datastructure and the functions using it are inspired by: Demeulenaere J. et al. (2016) Compact-Table: Efficiently Filtering Table Constraints with Reversible Sparse Bit-Sets. In: Rueher M. (eds) Principles and Practice of Constraint Programming. CP 2016. Lecture Notes in Computer Science, vol 9892. Springer, Cham. https://doi.org/10.1007/978-3-319-44953-1_14\n\nTableConstraint(scope, active, table, currentTable, modifiedVariables, unfixedVariables, supports, residues)\n\nTableConstraint default constructor.\n\nArguments\n\nscope::Vector{<:AbstractIntVar}: the ordered variables present in the table.\ntable::Matrix{Int}: the original table describing the constraint (impossible assignment are filtered).\ncurrentTable::RSparseBitSet{UInt64}: the reversible representation of the table.\nmodifiedVariables::Vector{Int}: vector with the indexes of the variables modified since the last propagation.\nunfixedVariables::Vector{Int}: vector with the indexes of the variables which are not binding.\nsupports::Dict{Pair{Int,Int},BitVector}: dictionnary which, for each pair (variable => value), gives the support of this pair.\nresidues::Dict{Pair{Int,Int},Int}: dictionnary which, for each pair (variable => value), gives the residue of this pair.\n\nTableConstraint(variables, table, supports, trailer)\n\nCreate a CompactTable constraint from the variables, with values given in table and supports given in supports.\n\nThis constructor gives full control on both table and supports. The attributes are not duplicated and remains linked to the variables given to the constructor. It should be used only to avoid duplication of table when using the same table constraint many times with different variables. WARNING: all variables must have the same domain; table and supports must be cleaned.\n\nArguments\n\nvariables::Vector{<:AbstractIntVar}: vector of variables of size (n, ).\ntable::Matrix{Int}: matrix of the constraint of size (n, m).\nsupports::Dict{Pair{Int,Int},BitVector}: for each assignment, a list of the tuples supporting this assignment.\ntrailer::Trailer: the trailer of the model.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.Disjunctive","page":"Constraints","title":"SeaPearl.Disjunctive","text":"Disjunctive(earliestStartingTime::Array{<:AbstractIntVar},  processingTime::Array{Int}, trailer, filteringAlgorithm::Array{filteringAlgorithmTypes} = [algoTimeTabling])::Disjunctive\n\nConstraint that insure that no task are executed in the same time range.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.Element2D","page":"Constraints","title":"SeaPearl.Element2D","text":"Element2D(matrix::Array{Int, 2}, x::AbstractIntVar, y::AbstractIntVar, z::AbstractIntVar, SeaPearl.trailer)\n\nElement2D constraint, states that matrix[x, y] == z\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.EqualConstant","page":"Constraints","title":"SeaPearl.EqualConstant","text":"EqualConstant(x::SeaPearl.AbstractIntVar, v::Int, SeaPearl.trailer)\n\nEquality constraint, putting a constant value v for the variable x i.e. x == v.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.GreaterOrEqualConstant","page":"Constraints","title":"SeaPearl.GreaterOrEqualConstant","text":"GreaterOrEqualConstant(x::SeaPearl.AbstractIntVar, v::Int)\n\nInequality constraint, x >= v\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.InSet","page":"Constraints","title":"SeaPearl.InSet","text":"InSet(x::AbstractIntVar, s::IntSetVar, trailer::SeaPearl.Trailer)\n\nInSet constraint, states that x ∈ s\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.IntervalConstant","page":"Constraints","title":"SeaPearl.IntervalConstant","text":"IntervalConstant(x::SeaPearl.IntVar, lower::Int, upper::Int, trailer::SeaPearl.Trailer)\n\nInequality constraint, lower <= x <= upper\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.isBinaryAnd","page":"Constraints","title":"SeaPearl.isBinaryAnd","text":"isBinaryAnd(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer::SeaPearl.Trailer)\n\nIs And constraint, states that b <=> x and y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.isBinaryOr","page":"Constraints","title":"SeaPearl.isBinaryOr","text":"isBinaryOr(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer::SeaPearl.Trailer)\n\nIs Or constraint, states that b <=> x or y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.isBinaryXor","page":"Constraints","title":"SeaPearl.isBinaryXor","text":"isBinaryXor(b::AbstractBoolVar, x::AbstractBoolVar, y::AbstractBoolVar, trailer::SeaPearl.Trailer)\n\nIs Xor constraint, states that b <=> x ⊻ y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.isLessOrEqual","page":"Constraints","title":"SeaPearl.isLessOrEqual","text":"isLessOrEqual(b::AbstractBoolVar, x::AbstractIntVar, y::AbstractIntVar, trailer::SeaPearl.Trailer)\n\nEquivalence between a boolean variable and the inequality between variables, states that b ⟺ x ≤ y\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.LessOrEqualConstant","page":"Constraints","title":"SeaPearl.LessOrEqualConstant","text":"LessOrEqualConstant(x::SeaPearl.AbstractIntVar, v::Int, trailer::SeaPearl.Trailer)\n\nInequality constraint, x <= v\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.MaximumConstraint","page":"Constraints","title":"SeaPearl.MaximumConstraint","text":"MaximumConstraint(x::Array{<:AbstractIntVar},y::AbstractIntVar, trailer::SeaPearl.Trailer) <: Constraint\n\nMaximum constraint, states that y = max(x)\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.NotEqualConstant","page":"Constraints","title":"SeaPearl.NotEqualConstant","text":"NotEqualConstant(x::SeaPearl.IntVar, v::Int)\n\nInequality constraint, x != v\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.NotEqual","page":"Constraints","title":"SeaPearl.NotEqual","text":"NotEqual(x::SeaPearl.IntVar, y::SeaPearl.IntVar)\n\nInequality constraint between two variables, stating that x != y.\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.ReifiedInSet","page":"Constraints","title":"SeaPearl.ReifiedInSet","text":"ReifiedInSet(x::AbstractIntVar, s::IntSetVar, b::BoolVar, trailer::Trailer)\n\nReifiedInSet contrainst, states that b ⟺ x ∈ s\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.SetDiffSingleton","page":"Constraints","title":"SeaPearl.SetDiffSingleton","text":"SetDiffSingleton(a::IntSetVar, b::IntSetVar, x::AbstractIntVar, trailer::Trailer)\n\nSetDiffSingleton constraint, states that a = b - {x}\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.SetEqualConstant","page":"Constraints","title":"SeaPearl.SetEqualConstant","text":"SetEqualConstant(s::IntSetVar, c::Set{Int}, trailer::Trailer)\n\nSetEqualConstant constraint, states that s == c\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.SumGreaterThan","page":"Constraints","title":"SeaPearl.SumGreaterThan","text":"SumGreaterThan(x<:AbstractIntVar, v::Int)\n\nSumming constraint, states that x[1] + x[2] + ... + x[length(x)] >= lower\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.SumLessThan","page":"Constraints","title":"SeaPearl.SumLessThan","text":"SumLessThan(x<:AbstractIntVar, v::Int)\n\nSumming constraint, states that x[1] + x[2] + ... + x[length(x)] <= v\n\n\n\n\n\n","category":"type"},{"location":"CP/constraints/#SeaPearl.SumToZero","page":"Constraints","title":"SeaPearl.SumToZero","text":"SumToZero(x<:AbstractIntVar, v::Int)\n\nSumming constraint, states that x[1] + x[2] + ... + x[length(x)] == 0\n\n\n\n\n\n","category":"type"},{"location":"community/#Community","page":"Community","title":"Community","text":"","category":"section"},{"location":"community/","page":"Community","title":"Community","text":"Everyone is welcome to contribute to this project, by opening issues or PR on the Github repository.","category":"page"},{"location":"#SeaPearl:-A-Julia-hybrid-CP-solver-enhanced-by-Reinforcement-Learning-techniques","page":"Home","title":"SeaPearl: A Julia hybrid CP solver enhanced by Reinforcement Learning techniques","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SeaPearl was created as a way for researchers to have a constraint programming solver that can integrate seamlessly with Reinforcement Learning technologies, using them as heuristics for value selection during branching.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The paper accompanying this solver can be found on the arXiv. If you use SeaPearl in your research, please cite our work.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The Julia language was chosen for this project as we believe it is one of the few languages that can be used for Constraint Programming as well as Machine/Deep Learning.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The constraint programming part, whose architecture is heavily inspired from Mini-CP framework, is focused on readability. The code was meant to be clear and modulable so that researchers could easily get access to CP data and use it as input for their ML model.","category":"page"},{"location":"","page":"Home","title":"Home","text":"SeaPearl comes with a set of examples that can be found in the SeaPearlZoo repository.","category":"page"},{"location":"CP/trailer/#Trailer:-backtrack-easily-and-efficiently","page":"Trailer","title":"Trailer: backtrack easily and efficiently","text":"","category":"section"},{"location":"CP/trailer/","page":"Trailer","title":"Trailer","text":"The trailer is the object that keeps track of anything you want to keep track of. Some objects will take a trailer as a parameter in their constructor. When it does, it means that their state can be saved and restored on demand using the functions described below.","category":"page"},{"location":"CP/trailer/#State-manipulation","page":"Trailer","title":"State manipulation","text":"","category":"section"},{"location":"CP/trailer/","page":"Trailer","title":"Trailer","text":"Those functions are used to change the current state, save and or restore it.","category":"page"},{"location":"CP/trailer/","page":"Trailer","title":"Trailer","text":"Note that during your \"state exploration\", you can only restore higher. It is not possible to restore some deeper state, or state that could be in the same level. For example, if you have a state A at some point, you call SeaPearl.saveState! to store it. You edit some SeaPearl.StateObject, making you at some state B. Then you call SeaPearl.restoreState! that will restore every SeaPearl.StateObject to the state A. At that point, there is no way to go back to the state B using the trailer.","category":"page"},{"location":"CP/trailer/","page":"Trailer","title":"Trailer","text":"SeaPearl.StateObject\r\nSeaPearl.StateEntry\r\nSeaPearl.trail!\r\nSeaPearl.setValue!\r\nSeaPearl.saveState!\r\nSeaPearl.restoreState!\r\nSeaPearl.withNewState!\r\nSeaPearl.restoreInitialState!","category":"page"},{"location":"CP/trailer/#SeaPearl.StateObject","page":"Trailer","title":"SeaPearl.StateObject","text":"StateObject{T}(value::T, trailer::Trailer)\n\nA reversible object of value value that has a type T, storing its modification into trailer.\n\n\n\n\n\n","category":"type"},{"location":"CP/trailer/#SeaPearl.StateEntry","page":"Trailer","title":"SeaPearl.StateEntry","text":"StateEntry{T}(value::T, object::StateObject{T})\n\nAn entry that can be stacked in the trailer, containing the former value of the object, and a reference to theobject` so that it can be restored by the trailer.\n\n\n\n\n\n","category":"type"},{"location":"CP/trailer/#SeaPearl.trail!","page":"Trailer","title":"SeaPearl.trail!","text":"trail!(var::StateObject{T})\n\nStore the current value of var into its trailer.\n\n\n\n\n\n","category":"function"},{"location":"CP/trailer/#SeaPearl.setValue!","page":"Trailer","title":"SeaPearl.setValue!","text":"setValue!(var::StateObject{T}, value::T) where {T}\n\nChange the value of var, replacing it with value, and if needed, store the former value into var's trailer.\n\n\n\n\n\n","category":"function"},{"location":"CP/trailer/#SeaPearl.saveState!","page":"Trailer","title":"SeaPearl.saveState!","text":"saveState!(trailer::Trailer)\n\nStore the current state into the trailer, replacing the current stack with an empty one.\n\n\n\n\n\n","category":"function"},{"location":"CP/trailer/#SeaPearl.restoreState!","page":"Trailer","title":"SeaPearl.restoreState!","text":"restoreState!(trailer::Trailer)\n\nIterate over the last state to restore every former value, used to backtrack every change  made after the last call to saveState!.\n\n\n\n\n\n","category":"function"},{"location":"CP/trailer/#SeaPearl.withNewState!","page":"Trailer","title":"SeaPearl.withNewState!","text":"withNewState!(func, trailer::Trailer)\n\nCall the func function with a new state, restoring it after. Aimed to be used with the do block syntax.\n\nExamples\n\nusing SeaPearl\ntrailer = SeaPearl.Trailer()\nreversibleInt = SeaPearl.StateObject{Int}(3, trailer)\nSeaPearl.withNewState!(trailer) do\n    SeaPearl.setValue!(reversibleInt, 5)\nend\nreversibleInt.value # 3\n\n\n\n\n\n","category":"function"},{"location":"CP/trailer/#SeaPearl.restoreInitialState!","page":"Trailer","title":"SeaPearl.restoreInitialState!","text":"restoreInitialState!(trailer::Trailer)\n\nRestore every linked object to its initial state. Basically call restoreState! until not possible.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#Variables","page":"Variables","title":"Variables","text":"","category":"section"},{"location":"CP/int_variable/#Integer-variables","page":"Variables","title":"Integer variables","text":"","category":"section"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"The implementation of integer variables in SeaPearl is heavily inspired on MiniCP. If you have some troubles understanding how it works, you can get more visual explanations by reading their slides.","category":"page"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"The integer variables are all a subset of AbstractIntVar.","category":"page"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"Every AbstractIntVar must have a unique id that you can retrieve with id.","category":"page"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"SeaPearl.id\r\nSeaPearl.isbound\r\nSeaPearl.assign!(::SeaPearl.AbstractIntVar, ::Int)\r\nSeaPearl.assignedValue","category":"page"},{"location":"CP/int_variable/#SeaPearl.id","page":"Variables","title":"SeaPearl.id","text":"function id(x::AbstractVar)\n\nReturn the string identifier of x. Every variable must be assigned a unique identifier upon creation, that will be used as a key to identify the variable in the CPModel object.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.isbound","page":"Variables","title":"SeaPearl.isbound","text":"isbound(x::AbstractIntVar)\n\nCheck whether x has an assigned value.\n\n\n\n\n\nisbound(x::AbstractBoolVar)\n\nCheck whether x has an assigned value.\n\n\n\n\n\nisbound(x::IntSetVar)\n\nCheck whether x has an assigned value (meaning its domain only contains one subset)\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.assign!-Tuple{SeaPearl.AbstractIntVar, Int64}","page":"Variables","title":"SeaPearl.assign!","text":"assign!(x::AbstractIntVar, value::Int)\n\nRemove everything from the domain of x but value.\n\n\n\n\n\n","category":"method"},{"location":"CP/int_variable/#SeaPearl.assignedValue","page":"Variables","title":"SeaPearl.assignedValue","text":"assignedValue(x::AbstractIntVar)\n\nReturn the assigned value of x. Throw an error if x is not bound.\n\n\n\n\n\nassignedValue(x::BoolVar)\n\nReturn the assigned value of x. Throw an error if x is not bound.\n\n\n\n\n\nassignedValue(x::IntSetVar)\n\nReturn the assigned value of x, i.e. the only subset it contains. Throw an error if x is not bound.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#IntVar","page":"Variables","title":"IntVar","text":"","category":"section"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"SeaPearl.IntVar\r\nSeaPearl.IntVar(::Int, ::Int, ::String, ::SeaPearl.Trailer)","category":"page"},{"location":"CP/int_variable/#SeaPearl.IntVar","page":"Variables","title":"SeaPearl.IntVar","text":"struct IntVar <: AbstractIntVar\n\nA \"simple\" integer variable, whose domain can be any set of integers. The constraints that affect this variable are stored in the onDomainChange array.\n\n\n\n\n\n","category":"type"},{"location":"CP/int_variable/#SeaPearl.IntVar-Tuple{Int64, Int64, String, SeaPearl.Trailer}","page":"Variables","title":"SeaPearl.IntVar","text":"function IntVar(min::Int, max::Int, id::String, trailer::Trailer)\n\nCreate an IntVar with a domain being the integer range [min, max] with the id string identifier and that will be backtracked by trailer.\n\n\n\n\n\n","category":"method"},{"location":"CP/int_variable/#IntDomain","page":"Variables","title":"IntDomain","text":"","category":"section"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"SeaPearl.AbstractIntDomain\r\nSeaPearl.IntDomain\r\nSeaPearl.IntDomain(::SeaPearl.Trailer, ::Int, ::Int)\r\nSeaPearl.isempty\r\nSeaPearl.length\r\nSeaPearl.isempty\r\nBase.in(::Int, ::SeaPearl.IntDomain)\r\nSeaPearl.remove!\r\nSeaPearl.removeAll!\r\nSeaPearl.removeAbove!\r\nSeaPearl.removeBelow!\r\nSeaPearl.assign!\r\nBase.iterate(::SeaPearl.IntDomain)\r\nSeaPearl.updateMaxFromRemovedVal!\r\nSeaPearl.updateMinFromRemovedVal!\r\nSeaPearl.updateBoundsFromRemovedVal!\r\nSeaPearl.minimum\r\nSeaPearl.maximum","category":"page"},{"location":"CP/int_variable/#SeaPearl.AbstractIntDomain","page":"Variables","title":"SeaPearl.AbstractIntDomain","text":"abstract type AbstractIntDomain end\n\nAbstract domain type. Every integer domain must inherit from this type.\n\n\n\n\n\n","category":"type"},{"location":"CP/int_variable/#SeaPearl.IntDomain","page":"Variables","title":"SeaPearl.IntDomain","text":"struct IntDomain <: AbstractIntDomain\n\nSparse integer domain. Can contain any set of integer.\n\nYou must note that this implementation takes as much space as the size of the initial domain. However, it can be pretty efficient in accessing and editing. Operation costs are detailed for each method.\n\n\n\n\n\n","category":"type"},{"location":"CP/int_variable/#SeaPearl.IntDomain-Tuple{SeaPearl.Trailer, Int64, Int64}","page":"Variables","title":"SeaPearl.IntDomain","text":"IntDomain(trailer::Trailer, n::Int, offset::Int)\n\nCreate an integer domain going from ofs + 1 to ofs + n. Will be backtracked by the given trailer.\n\n\n\n\n\n","category":"method"},{"location":"CP/int_variable/#Base.isempty","page":"Variables","title":"Base.isempty","text":"isempty(dom::IntDomain)\n\nReturn true iff dom is an empty set. Done in constant time.\n\n\n\n\n\nisempty(dom::BoolDomain)\n\nReturn true iff dom is an empty set. Done in constant time.\n\n\n\n\n\nisempty(dom::IntDomainView)\n\nReturn true iff dom is an empty set.\n\n\n\n\n\nisempty(dom::BoolDomainView)\n\nReturn true iff dom is an empty set.\n\n\n\n\n\nBase.isempty(model::CPModel)::Bool\n\nReturn a boolean describing if the model is empty or not.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#Base.length","page":"Variables","title":"Base.length","text":"length(dom::IntDomain)\n\nReturn the size of dom. Done in constant time.\n\n\n\n\n\nlength(dom::BoolDomain)\n\nReturn the size of dom. Done in constant time.\n\n\n\n\n\nlength(dom::IntDomainView)\n\nReturn the size of dom.\n\n\n\n\n\nlength(dom::BoolDomainView)\n\nReturn the size of dom.\n\n\n\n\n\nlength(dom::IntDomain)\n\nReturn the size of dom. Done in constant time.\n\n\n\n\n\nBase.length(set::SetModification)\n\na generic function length is needed for all modifications. \n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#Base.in-Tuple{Int64, SeaPearl.IntDomain}","page":"Variables","title":"Base.in","text":"Base.in(value::Int, dom::IntDomain)\n\nCheck if an integer is in the domain. Done in constant time.\n\n\n\n\n\n","category":"method"},{"location":"CP/int_variable/#SeaPearl.remove!","page":"Variables","title":"SeaPearl.remove!","text":"remove!(dom::IntDomain, value::Int)\n\nRemove value from dom. Done in constant time.\n\n\n\n\n\nremove!(dom::BoolDomain, value::Bool)\n\nRemove value from dom. Done in constant time.\n\n\n\n\n\nremove!(dom::BoolDomain, value::Int)\n\nRemove value from dom. Done in constant time.\n\n\n\n\n\nremove!(dom::IntDomainView, value::Int)\n\nRemove value from dom.\n\n\n\n\n\nremove!(dom::BoolDomainViewNot, value::Bool)\n\nRemove value from dom.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.removeAll!","page":"Variables","title":"SeaPearl.removeAll!","text":"removeAll!(dom::IntDomain)\n\nRemove every value from dom. Return the removed values. Done in constant time.\n\n\n\n\n\nremoveAll!(dom::BoolDomain)\n\nRemove every value from dom. Return the removed values. Done in constant time.\n\n\n\n\n\nremoveAll!(dom::IntDomainView)\n\nRemove every value from dom. Return the removed values.\n\n\n\n\n\nremoveAll!(dom::BoolDomainViewNot)\n\nRemove every value from dom. Return the removed values.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.removeAbove!","page":"Variables","title":"SeaPearl.removeAbove!","text":"removeAbove!(dom::IntDomain, value::Int)\n\nRemove every integer of dom that is strictly above value. Done in linear time.\n\n\n\n\n\nremoveAbove!(dom::IntDomain, value::Int)\n\nRemove every integer of dom that is strictly above value. Done in linear time.\n\n\n\n\n\nremoveAbove!(dom::IntDomainView, value::Int)\n\nRemove every integer of dom that is strictly above value.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.removeBelow!","page":"Variables","title":"SeaPearl.removeBelow!","text":"removeBelow!(dom::IntDomain, value::Int)\n\nRemove every integer of dom that is strictly below value. Return the pruned values. Done in linear time.\n\n\n\n\n\nremoveBelow!(dom::IntDomain, value::Int)\n\nRemove every integer of dom that is strictly below value. Return the pruned values. Done in linear time.\n\n\n\n\n\nremoveBelow!(dom::IntDomainView, value::Int)\n\nRemove every integer of dom that is strictly below value. Return the pruned values.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.assign!","page":"Variables","title":"SeaPearl.assign!","text":"assign!(dom::IntDomain, value::Int)\n\nRemove everything from the domain but value. Return the removed values. Return the pruned values. Done in constant time.\n\n\n\n\n\nassign!(x::AbstractIntVar, value::Int)\n\nRemove everything from the domain of x but value.\n\n\n\n\n\nassign!(dom::BoolDomain, value::Bool)\n\nRemove everything from the domain but value. Return the removed values. Return the pruned values. Done in constant time.\n\n\n\n\n\nassign!(dom::BoolDomain, value::Int)\n\nRemove everything from the domain but value. Return the removed values. Return the pruned values. Done in constant time.\n\n\n\n\n\nassign!(x::BoolVar, value::Bool)\n\nRemove everything from the domain of x but value.\n\n\n\n\n\nassign!(dom::IntDomainView, value::Int)\n\nRemove everything from the domain but value. Return the removed values. Return the pruned values.\n\n\n\n\n\nassign!(dom::BoolDomainViewNot, value::Bool)\n\nRemove everything from the domain but value. Return the removed values. Return the pruned values.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#Base.iterate-Tuple{SeaPearl.IntDomain}","page":"Variables","title":"Base.iterate","text":"Base.iterate(dom::IntDomain, state=1)\n\nIterate over the domain in an efficient way. The order may not be consistent. WARNING: Do NOT update the domain you are iterating on.\n\n\n\n\n\n","category":"method"},{"location":"CP/int_variable/#SeaPearl.updateMaxFromRemovedVal!","page":"Variables","title":"SeaPearl.updateMaxFromRemovedVal!","text":"updateMaxFromRemovedVal!(dom::IntDomain, v::Int)\n\nKnowing that v just got removed from dom, update dom's maximum value. Done in constant time.\n\n\n\n\n\nupdateMaxFromRemovedVal!(dom::IntDomainView, v::Int)\n\nKnowing that v just got removed from dom, update dom's maximum value.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.updateMinFromRemovedVal!","page":"Variables","title":"SeaPearl.updateMinFromRemovedVal!","text":"updateMinFromRemovedVal!(dom::IntDomain, v::Int)\n\nKnowing that v just got removed from dom, update dom's minimum value. Done in constant time.\n\n\n\n\n\nupdateMinFromRemovedVal!(dom::IntDomainView, v::Int)\n\nKnowing that v just got removed from dom, update dom's minimum value.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.updateBoundsFromRemovedVal!","page":"Variables","title":"SeaPearl.updateBoundsFromRemovedVal!","text":"updateBoundsFromRemovedVal!(dom::AbstractIntDomain, v::Int)\n\nKnowing that v just got removed from dom, update dom's minimum and maximum value. Done in constant time.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.minimum","page":"Variables","title":"SeaPearl.minimum","text":"minimum(dom::IntDomain)\n\nReturn the minimum value of dom. Done in constant time.\n\n\n\n\n\nminimum(dom::BoolDomain)\n\nReturn the minimum value of dom. Done in constant time.\n\n\n\n\n\nminimum(dom::IntDomainView)\n\nReturn the minimum value of dom.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/#SeaPearl.maximum","page":"Variables","title":"SeaPearl.maximum","text":"maximum(dom::IntDomain)\n\nReturn the maximum value of dom. Done in constant time.\n\n\n\n\n\nmaximum(dom::BoolDomain)\n\nReturn the maximum value of dom. Done in constant time.\n\n\n\n\n\nmaximum(dom::IntDomainView)\n\nReturn the maximum value of dom.\n\n\n\n\n\n","category":"function"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"If you want to express some variations of an integer variable x (for example -x or a x with a  0) in a constraint, you can use the IntVarView types:","category":"page"},{"location":"CP/int_variable/#IntVarView","page":"Variables","title":"IntVarView","text":"","category":"section"},{"location":"CP/int_variable/","page":"Variables","title":"Variables","text":"SeaPearl.IntVarViewMul\r\nSeaPearl.IntVarViewMul(x::SeaPearl.AbstractIntVar, a::Int, id::String)\r\nSeaPearl.IntVarViewOpposite\r\nSeaPearl.IntVarViewOpposite(x::SeaPearl.AbstractIntVar, id::String)\r\nSeaPearl.IntVarViewOffset\r\nSeaPearl.IntVarViewOffset(x::SeaPearl.AbstractIntVar, id::String)","category":"page"}]
}