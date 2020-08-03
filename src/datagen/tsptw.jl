using Random
using Distributions

struct TsptwGenerator <: AbstractModelGenerator
    n_city::Int
    grid_size::Int # Maximum of positions
    max_tw_gap::Int # Maximum time windows gap allowed between the cities constituing the feasible tour
    max_tw::Int # Maximum time windows upper bound
end

"""
    fill_with_generator!(cpmodel::CPModel, gen::TsptwGenerator)::CPModel    

Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose ! Density should be more than 1.

It is the same generator as used in 
"Combining Reinforcement Learning and Constraint Programming for Combinatorial Optimization":
Quentin Cappart, Thierry Moisan, Louis-Martin Rousseau, Isabeau Prémont-Schwarz & Andre Cire
https://arxiv.org/abs/2006.01610

Basicaly finds positions with a uniform distributions, then sets the time windows by creating a feasible tour and adding
some randomness by using uniform distributions with gap and the length of the time windows.
"""
function fill_with_generator!(cpmodel::CPModel, gen::TsptwGenerator; seed=nothing)
    if !isnothing(seed)
        Random.seed!(seed)
    end

    ### Creating the TSPTW instance
    pos_distribution = Uniform(0, gen.grid_size)
    x_pos = rand(pos_distribution, gen.n_city)
    y_pos = rand(pos_distribution, gen.n_city)

    dist = zeros(Int64, gen.n_city, gen.n_city)
    for i in 1:gen.n_city
        for j in 1:gen.n_city
            dist[i, j] = round(sqrt((x_pos[i] - x_pos[j])^2 + (y_pos[i] - y_pos[j])^2))
        end
    end

    time_windows = zeros(Int64, gen.n_city, 2)
    time_windows[1, :] = [0 1000]

    random_solution = [1, shuffle(Vector(2:gen.n_city))...]

    for i in 2:gen.n_city
        prev_city = random_solution[i-1]
        cur_city = random_solution[i]

        cur_dist = dist[prev_city, cur_city]

        tw_lb_min = time_windows[prev_city, 1] + cur_dist

        rand_tw_lb = rand(Uniform(tw_lb_min, tw_lb_min + gen.max_tw_gap))
        rand_tw_ub = rand(Uniform(rand_tw_lb, rand_tw_lb + gen.max_tw))

        time_windows[cur_city, :] = [rand_tw_lb rand_tw_ub]
    end


    ### Filling the CPModel
    ## Creating variables
    m = [IntSetVar(1, gen.n_city, "m_"*string(i), cpmodel.trailer) for i in 1:gen.n_city] # Remaining cities to visit
    v = [IntVar(1, gen.n_city, "v_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # Last customer
    t = [IntVar(1, gen.max_tw, "t_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # Current time
    a = [IntVar(1, gen.n_city, "a_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # Action: serving customer a_i at stage i
    c = [IntVar(1, gen.max_tw, "c_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # Current cost
    addVariable!.(cpmodel, m)
    addVariable!.(cpmodel, v)
    addVariable!.(cpmodel, t)
    addVariable!.(cpmodel, a)
    addVariable!.(cpmodel, c)

    ## Intermediaries
    d = [IntVar(1, gen.grid_size, "d_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # d[v_i, a_i]
    lowers = [IntVar(1, gen.max_tw, "td_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # t + d[v_i, a_i]
    lower_tw = [IntVar(time_windows[i, 1], time_windows[i, 1], "low_tw_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # time_windows[i, 1]
    upper_tw_plus_1 = [IntVar(time_windows[i, 2] + 1, time_windows[i, 2] + 1, "upper_tw_"+string(i), cpmodel.trailer) for i in 1:gen.n_city] # time_windows[i, 2] + 1
    still_time = [BoolVar("s_t_"*string(i)*"_"*string(j), cpmodel.trailer) for i in 1:gen.n_city for j in 1:gen.n_city] # t_i < upper_bound[j]
    one_var = IntVar(1, 1, "one", cpmodel.trailer)
    j_index = [IntVarViewMul(one_var, j, "index_"*string(j)) for j in 1:gen.n_city]
    j_in_m_i = [BoolVar(string(j)*"_in_m_"*string(i), cpmodel.trailer) for i in 1:gen.n_city for j in 1:gen.n_city] # t_i < upper_bound[j]

    addVariable!.(cpmodel, d)
    addVariable!.(cpmodel, lowers)
    addVariable!.(cpmodel, lower_tw)
    addVariable!.(cpmodel, upper_tw_plus_1)
    addVariable!.(cpmodel, still_time)
    addVariable!(cpmodel, one_var)
    addVariable!.(cpmodel, j_index)
    addVariable!.(cpmodel, j_in_m_i)

    ## Constraints
    # Initialization
    push!(cpmodel.constraints, EqualConstant(t[1], 0, cpmodel.trailer))
    push!(cpmodel.constraints, EqualConstant(v[1], 1, cpmodel.trailer))
    push!(cpmodel.constraints, EqualConstant(c[1], 0, cpmodel.trailer))
    push!(cpmodel.constraints, SetEqualConstant(m[1], Set{Int}(collect(2:gen.n_city)), cpmodel.trailer))

    # Variable definition
    for i in 1:(gen.n_city - 1)
        # m[i+1] = m[i] \ a[i]
        push!(cpmodel.constraints, SetDiffSingleton(m[i+1], m[i], a[i], cpmodel.trailer))

        # v[i+1] = a[i]
        push!(cpmodel.constraints, Equal(v[i+1], a[i], cpmodel.trailer))

        # d[i] = dist[v[i], a[i]]
        push!(cpmodel.constraints, Element2D(dist, v[i], a[i], d[i], cpmodel.trailer))

        # lowers[i] = t[i] + d[i]
        push!(cpmodel.constraints, SumToZero(AbstractIntVar[t[i], d[i], IntVarViewOpposite(lowers[i], "-td_"+string(i))], cpmodel.trailer))

        # t[i+1] = max(lowers[i], lower_tw[i])
        push!(cpmodel.constraints, BinaryMaximumBC(t[i+1], lowers[i], lower_tw[i], cpmodel.trailer))

        # c[i + 1] = c[i] + d[i]
        push!(cpmodel.constraints, SumToZero(AbstractIntVar[c[i], d[i], IntVarViewOpposite(c[i+1], "-c_"+string(i+1))], cpmodel.trailer))
    end

    # Validity constraints
    for i in 1:gen.n_city
        # a[i] ∈ m[i]
        push!(cpmodel.constraints, InSet(a[i], m[i], cpmodel.trailer))

        # lowers[i] <= lower_bound[a[i]]
        push!(cpmodel.constraints, LessOrEqualConstant(lowers[i], time_windows[i, 2], trailer))
    end

    # Pruning constraints
    for i in 1:gen.n_city
        for j in 1:gen.n_city
            # still_time[i, j] = t[i] < upper_tw[j]
            push!(cpmodel.constraints, isLessOrEqual(still_time[i, j], t[i], upper_tw_plus_1[j], cpmodel.trailer))

            # j_in_m_i[i, j] = j_index[j] ∈ m[i]
            push!(cpmodel.constraints, ReifiedInSet(j_index[j], m[i], j_in_m_i[i, j]))

            # t[i] >= upper[j] ⟹ j ∉ m[i]
            # ≡ t[i] < upper[j] ⋁ j ∉ m[i]
            # ≡ still_time[i, j] ⋁ ¬j_in_m_i[i, j]
            push!(cpmodel.constraints, BinaryOr(still_time[i, j], BoolVarViewNot(j_in_m_i[i, j], "¬"*string(j)*"_in_m_"*string(i))))
        end
    end

    # Objective function: min c[n]
    cpmodel.objective = c[gen.n_city]

    nothing
end