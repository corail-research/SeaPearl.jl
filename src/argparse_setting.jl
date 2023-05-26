import ArgParse.ArgParseSettings
import ArgParse.@add_arg_table
import ArgParse.parse_args

# using Random

# using Revise
# using SeaPearl

include_time = @elapsed begin 
    include("using_seapearl.jl")
end

println("include time: $include_time s")


# function meminfo_julia()
#     # @printf "GC total:  %9.3f MiB\n" Base.gc_total_bytes(Base.gc_num())/2^20
#     # Total bytes (above) usually underreports, thus I suggest using live bytes (below)
#     @printf "GC live:   %9.3f MiB\n" Base.gc_live_bytes()/2^20
#     @printf "JIT:       %9.3f MiB\n" Base.jit_total_bytes()/2^20
#     @printf "Max. RSS:  %9.3f MiB\n" Sys.maxrss()/2^20
#   end


function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--bench_name", "-b"
            help = "name of the file conataining the XCSP instance to solve"
            arg_type = String
            required = true
        "--strat"
            help = "name of the search strategy to use, must be in ('dfs' 'dfwbs' 'ilds_d2' 'ilds_d5' 'ilds_d10' 'ilds_d20')"
            arg_type = String
            default = "dfs"
            required = false
        "--random_seed", "-s"
            help = "seed to intialize the random number generator"
            arg_type = Int
            default = 0
        "--time_limit", "-t"
            help = "total CPU time (in seconds) allowed"
            arg_type = Int
            default = nothing # moddify to take into account the capacity of the computer 
            # required = true
        "--memory_limit", "-m"
            help = "total amount of memory (in MiB) allowed"
            arg_type = Int
            default = nothing # moddify to take into account the capacity of the computer 
        "--nb_core", "-c"
            help = "number of processing units allocated"
            arg_type = Int
            default = nothing # moddify to take into account the capacity of the computer 
        "--tmp_dir", "-d"
            help = "directory where temporary files can be read/write"
            arg_type = String
        "--dir"
            help = "directory where the solver files are located"
            arg_type = String
    end
    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()

    bench_name = parsed_args["bench_name"]
    strat = parsed_args["strat"]
    random_seed = parsed_args["random_seed"]
    time_limit = parsed_args["time_limit"]
    memory_limit = parsed_args["memory_limit"]
    nb_core = parsed_args["nb_core"]
    tmp_dir = parsed_args["tmp_dir"]
    dir = parsed_args["dir"]

    # println("Parsed args:")
    println("strat : ", strat)
    println("bench_name : ", bench_name)
    # println("random_seed : ", random_seed)
    # println("time_limit : ", time_limit)
    # println("memory_limit : ", memory_limit)
    # println("nb_core : ", nb_core)
    # println("tmp_dir : ", tmp_dir)
    # println("dir : ", dir) # /Documents/CORAIL/SeaPearl/instancesXCSP22/xml/MiniCSP

    #println("GC live: ", Base.gc_live_bytes()/2^20, " MiB\n")

    if strat == "dfs"
        strat = SeaPearl.DFSearch()
    elseif strat == "dfwbs"
        strat = SeaPearl.DFWBSearch()
    elseif strat == "ilds_d2"
        strat = SeaPearl.ILDSearch(2)
    elseif strat == "ilds_d5"
        strat = SeaPearl.ILDSearch(5)
    elseif strat == "ilds_d10"
        strat = SeaPearl.ILDSearch(10)
    elseif strat == "ilds_d20"
        strat = SeaPearl.ILDSearch(20)
    else
        println("Error: unknown search strategy")
        return
    end

    if isnothing(tmp_dir)
        tmp_dir = ""
    end

    if isnothing(dir)
        dir = ""
    end

    # device = nb_core # TODO

    #Random.seed!(random_seed)

    model = SeaPearl.solve_XCSP3_instance(bench_name, strat, time_limit, memory_limit)
end

main()

# julia --project src/argparse_setting.jl -b "instancesXCSP22/xml/MiniCOP/ClockTriplet-03-12_c22.xml" -t 120 