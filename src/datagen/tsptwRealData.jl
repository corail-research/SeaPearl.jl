using SeaPearl
using Random
"""
    struct TsptwGeneratorFromRealData <: SeaPearl.AbstractModelGenerator

    This generator is a variant of the TsptwGenerator developped by Kim Rioux-Paradis based on real data to generate instances of size less than or equal to 500. 

    However, this generator cannot be used exactly like TsptwGenerator since we do not have access to the absolute positions of the nodes but only to the distance matrix. Therefore it is not possible to fill the model.adhocInfos exactly as TsptwGenerator does. It is therefore not possible to reuse the functions using its information (TsptwReward for example)
    However, there are several methods to generate an approximation (up to a rotation) of this position matrix. See : https://math.stackexchange.com/questions/156161/finding-the-coordinates-of-points-from-distance-matrix
    
"""
struct TsptwGeneratorFromRealData <: SeaPearl.AbstractModelGenerator
    n_city::Int
    max_tw_gap::Int # Maximum time windows gap allowed between the cities constituing the feasible tour
    max_tw::Int # Maximum time windows upper bound
    pourcent_max_tw::Int64
    file::String
    pruning::Bool
end

TsptwGeneratorFromRealData(n_city::Int, max_tw_gap::Int, max_tw::Int, pourcent_max_tw::Int64, file::String) = TsptwGeneratorFromRealData(n_city, max_tw_gap, max_tw, pourcent_max_tw, file, true)

"""
    fill_with_generator!(cpmodel::CPModel, gen::TsptwGeneratorFromRealData)::CPModel    
Fill a CPModel with the variables and constraints generated. We fill it directly instead of 
creating temporary files for efficiency purpose !

Basicaly finds positions with a uniform distributions, then sets the time windows by creating a feasible tour and adding
some randomness by using uniform distributions with gap and the length of the time windows.

A seed must be specified by the user to generate a specific instance. As long as Random.seed!(seed) is called at the beginning of the function, every random-based operations with be deterministic. Caution : this is not the seed that must be specified in order to generate a same set of evaluation instances across experiment, in that case, the user must call Random.seed! only once, at the beginning of the experiment. 
"""
function fill_with_generator!(cpmodel::SeaPearl.CPModel, gen::TsptwGeneratorFromRealData; rng::Union{Nothing,AbstractRNG} = nothing, dist = nothing, timeWindows=nothing)

    rng = isnothing(rng) ? MersenneTwister() : rng

    lines = ""
    open(gen.file, "r") do openedFile
        input = read(openedFile, String)
        lines = split(input, '\n')
    end
    max_city = parse(Int64, lines[1])
    distance = zeros(Int64, max_city, max_city)
    timeWindow = zeros(Int64, max_city, 2)
    for i in 1:max_city
        di = split(lines[i + 1], " ")
        for j in 1:max_city
            distance[i,j] = parse(Int64, di[j])
        end
    end

    for i in 1:max_city
        ti = split(lines[i + 1 + max_city], " ")
        ti = filter!(e->e≠"",ti)
        timeWindow[i,1] = parse(Int64, ti[1])
        timeWindow[i,2] = parse(Int64, ti[2])
    end
    
    perm  = shuffle(rng, 1:max_city)
    randomCity = randperm!(rng, perm)[1:gen.n_city]
    dist = zeros(Int64, gen.n_city, gen.n_city)
    timeWindows = zeros(Int64, gen.n_city, 2)
    maxTW = floor(Int, gen.pourcent_max_tw * gen.n_city / 100)
    for i in 1:gen.n_city
        for j in 1:gen.n_city
            dist[i, j] = distance[randomCity[i], randomCity[j]]
        end     
    end
    maxValue = sum(dist[i,j] for i in 1:gen.n_city, j in 1:gen.n_city)

    for i in 1:maxTW
        timeWindows[i, 1] = timeWindow[randomCity[i], 1]
        timeWindows[i, 2] = timeWindow[randomCity[i], 2]
    end
    for i in maxTW+1:gen.n_city
        timeWindows[i, 1] = 0
        timeWindows[i, 2] = maxValue
    end

    random_solution = [1, shuffle(rng, Vector(2:gen.n_city))]

    #TODO need to find a way to retrieve coordinates of points from 
    #x_pos = zeros(gen.n_city)
    #y_pos = zeros(gen.n_city)
    #grid_size = 0
    #cpmodel.adhocInfo = dist, timeWindows, hcat(x_pos, y_pos), grid_size

    max_upper_tw = maxValue

    ### Filling the CPModel
    ## Creating variables
    m = [SeaPearl.IntSetVar(1, gen.n_city, "m_"*string(i), cpmodel.trailer) for i in 1:gen.n_city] # Remaining cities to visit
    v = [SeaPearl.IntVar(1, gen.n_city, "v_"*string(i), cpmodel.trailer) for i in 1:gen.n_city] # Last customer
    t = [SeaPearl.IntVar(0, max_upper_tw, "t_"*string(i), cpmodel.trailer) for i in 1:gen.n_city] # Current time
    a = [SeaPearl.IntVar(1, gen.n_city, "a_"*string(i), cpmodel.trailer) for i in 1:(gen.n_city-1)] # Action: serving customer a_i at stage i
    c = [SeaPearl.IntVar(0, max_upper_tw, "c_"*string(i), cpmodel.trailer) for i in 1:gen.n_city] # Current cost
    total_cost = SeaPearl.IntVar(0, max_upper_tw, "total_cost", cpmodel.trailer)
    SeaPearl.addVariable!(cpmodel, total_cost; branchable=false)
    for i in 1:gen.n_city
        SeaPearl.addVariable!(cpmodel, m[i]; branchable=false)
        SeaPearl.addVariable!(cpmodel, v[i]; branchable=false)
        SeaPearl.addVariable!(cpmodel, t[i]; branchable=false)
        if i != gen.n_city
            SeaPearl.addVariable!(cpmodel, a[i]; branchable=true)
        end
        SeaPearl.addVariable!(cpmodel, c[i]; branchable=false)
    end
    

    ## Intermediaries
    d = [SeaPearl.IntVar(0, Base.maximum(dist), "d_"*string(i), cpmodel.trailer) for i in 1:gen.n_city] # d[v_i, a_i]
    lowers = [SeaPearl.IntVar(0, max_upper_tw, "td_"*string(i), cpmodel.trailer) for i in 1:(gen.n_city-1)] # t + d[v_i, a_i]
    lower_ai = [SeaPearl.IntVar(0, max_upper_tw, "lower_ai_"*string(i), cpmodel.trailer) for i in 1:(gen.n_city-1)] # timeWindows[i, 1]
    upper_tw_minus_1 = [SeaPearl.IntVar(timeWindows[i, 2] - 1, timeWindows[i, 2] - 1, "upper_tw_"*string(i), cpmodel.trailer) for i in 1:gen.n_city] # timeWindows[i, 2] + 1
    one_var = SeaPearl.IntVar(1, 1, "one", cpmodel.trailer)
    upper_ai = [SeaPearl.IntVar(0, max_upper_tw, "upper_ai_"*string(i), cpmodel.trailer) for i in 1:(gen.n_city-1)] # timeWindows[a_i, 2]
    j_index = [SeaPearl.IntVarViewMul(one_var, j, "index_"*string(j)) for j in 1:gen.n_city]

    still_time = Array{SeaPearl.BoolVar, 2}(undef, (gen.n_city, gen.n_city))
    j_in_m_i = Array{SeaPearl.BoolVar, 2}(undef, (gen.n_city, gen.n_city))
    for i in 1:gen.n_city
        for j in 1:gen.n_city
            still_time[i, j] = SeaPearl.BoolVar("s_t_"*string(i)*"_"*string(j), cpmodel.trailer) # t_i < upper_bound[j]
            j_in_m_i[i, j] = SeaPearl.BoolVar(string(j)*"_in_m_"*string(i), cpmodel.trailer) # t_i < upper_bound[j]
        end
    end

    SeaPearl.addVariable!(cpmodel, one_var; branchable=false)
    for i in 1:gen.n_city
        SeaPearl.addVariable!(cpmodel, d[i]; branchable=false)
        SeaPearl.addVariable!(cpmodel, upper_tw_minus_1[i]; branchable=false)
        if gen.pruning
            SeaPearl.addVariable!(cpmodel, j_index[i]; branchable=false)
        end
        if i != gen.n_city
            SeaPearl.addVariable!(cpmodel, lower_ai[i]; branchable=false)
            SeaPearl.addVariable!(cpmodel, upper_ai[i]; branchable=false)
            SeaPearl.addVariable!(cpmodel, lowers[i]; branchable=false)
        end
        for j in 1:gen.n_city
            if gen.pruning
                SeaPearl.addVariable!(cpmodel, j_in_m_i[i, j]; branchable=false)
                SeaPearl.addVariable!(cpmodel, still_time[i, j]; branchable=false)
            end
        end
    end

    ## Constraints
    # Initialization
    SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(t[1], 0, cpmodel.trailer))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(v[1], 1, cpmodel.trailer))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.EqualConstant(c[1], 0, cpmodel.trailer))
    SeaPearl.addConstraint!(cpmodel, SeaPearl.SetEqualConstant(m[1], Set{Int}(collect(2:gen.n_city)), cpmodel.trailer))

    # Variable definition
    for i in 1:(gen.n_city - 1)
        # m[i+1] = m[i] \ a[i]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.SetDiffSingleton(m[i+1], m[i], a[i], cpmodel.trailer))

        # v[i+1] = a[i]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Equal(v[i+1], a[i], cpmodel.trailer))

        # t[i+1] = max(lowers[i], lower_ai[i])
        SeaPearl.addConstraint!(cpmodel, SeaPearl.BinaryMaximumBC(t[i+1], lowers[i], lower_ai[i], cpmodel.trailer))

        # c[i + 1] = c[i] + d[i]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(SeaPearl.AbstractIntVar[c[i], d[i], SeaPearl.IntVarViewOpposite(c[i+1], "-c_"*string(i+1))], cpmodel.trailer))

        # upper_ai = timeWindows[a_i, 2]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Element1D(timeWindows[:, 2], a[i], upper_ai[i], cpmodel.trailer))

        # lower_ai = timeWindows[a_i, 1]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Element1D(timeWindows[:, 1], a[i], lower_ai[i], cpmodel.trailer))

        # d[i] = dist[v[i], a[i]]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.Element2D(dist, v[i], a[i], d[i], cpmodel.trailer))
        # lowers[i] = t[i] + d[i]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(SeaPearl.AbstractIntVar[t[i], d[i], SeaPearl.IntVarViewOpposite(lowers[i], "-td_"*string(i))], cpmodel.trailer))
    end
    # d[n] = dist[a[n-1], 1]
    SeaPearl.addConstraint!(cpmodel, SeaPearl.Element2D(dist, a[gen.n_city-1], one_var, d[gen.n_city], cpmodel.trailer))
    # total_cost = c[n] + d[n]
    SeaPearl.addConstraint!(cpmodel, SeaPearl.SumToZero(SeaPearl.AbstractIntVar[c[gen.n_city], d[gen.n_city], SeaPearl.IntVarViewOpposite(total_cost, "-total_cost")], cpmodel.trailer))

    # Validity constraints
    for i in 1:(gen.n_city - 1)
        # a[i] ∈ m[i]
        SeaPearl.addConstraint!(cpmodel, SeaPearl.InSet(a[i], m[i], cpmodel.trailer))

        # lowers[i] <= upper_ai
        SeaPearl.addConstraint!(cpmodel, SeaPearl.LessOrEqual(lowers[i], upper_ai[i], cpmodel.trailer))
    end

    # Pruning constraints
    if gen.pruning
        for i in 1:gen.n_city
            for j in 1:gen.n_city
                # still_time[i, j] = t[i] < upper_tw[j]
                SeaPearl.addConstraint!(cpmodel, SeaPearl.isLessOrEqual(still_time[i, j], t[i], upper_tw_minus_1[j], cpmodel.trailer))

                # j_in_m_i[i, j] = j_index[j] ∈ m[i]
                SeaPearl.addConstraint!(cpmodel, SeaPearl.ReifiedInSet(j_index[j], m[i], j_in_m_i[i, j], cpmodel.trailer))

                # t[i] >= upper[j] ⟹ j ∉ m[i]
                # ≡ t[i] < upper[j] ⋁ j ∉ m[i]
                # ≡ still_time[i, j] ⋁ ¬j_in_m_i[i, j]
                SeaPearl.addConstraint!(cpmodel, SeaPearl.BinaryOr(still_time[i, j], SeaPearl.BoolVarViewNot(j_in_m_i[i, j], "¬"*string(j)*"_in_m_"*string(i)), cpmodel.trailer))
            end
        end
    end

    # Objective function: min total_cost
    SeaPearl.addObjective!(cpmodel,total_cost)
    return dist, timeWindows
end
