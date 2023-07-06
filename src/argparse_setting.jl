import ArgParse.ArgParseSettings
import ArgParse.@add_arg_table
import ArgParse.parse_args

using Random
using JSON 

function read_parameters(file_path)
    parameters = nothing
    try
        file = open(file_path, "r")
        json_data = read(file, String)
        close(file)
        parameters = JSON.parse(json_data)
    catch e
        error("Error reading parameter file: $e")
    end

    return parameters
end

include_time = @elapsed begin 
    include("using_seapearl.jl")
end


function parse_commandline()
    """
    Parse the command line arguments and return a dictionary containing the values
    """
    s = ArgParseSettings()

    @add_arg_table s begin
        "--bench_name", "-b"
            help = "name of the file conataining the XCSP instance to solve"
            arg_type = String
            required = false
        "--strat"
            help = "name of the search strategy to use, must be in ('dfs' 'dfwbs' 'ilds_d2' 'ilds_d5' 'ilds_d10' 'ilds_d20')"
            arg_type = String
            default = "dfs"
            required = false
        "--csv_path"
            help = "name of the csv file path for saving performance, if not found, nothing is saved"
            arg_type = String
            required = false
        "--random_seed", "-s"
            help = "seed to intialize the random number generator"
            arg_type = Int
            default = 0
            required = false
        "--time_limit", "-t"
            help = "total CPU time (in seconds) allowed"
            arg_type = Int
            default = 1000000
            required = false
        "--memory_limit", "-m"
            help = "total amount of memory (in MiB) allowed"
            arg_type = Int
            default = 1000000
            required = false
        "--nb_core", "-c"
            help = "number of processing units allocated"
            arg_type = Int
            default = Base.Sys.CPU_THREADS
            required = false
        "--path_json", "-j"
            help = "use a json file to set the parameters"
            arg_type = String
            default = nothing
            required = false
    end
    return parse_args(s)
end

function main()
    """
    Main function of the script
    """
    parsed_args = parse_commandline()

    if !isnothing(parsed_args["path_json"])
        parameters = read_parameters(parsed_args["path_json"])
        
        bench_name = parameters["bench_name"]
        strat = parameters["strat"]
        random_seed = parameters["random_seed"]
        time_limit = parameters["time_limit"]
        memory_limit = parameters["memory_limit"]
        nb_core = parameters["nb_core"]
        csv_path = parameters["csv_path"]
    else
        bench_name = parsed_args["bench_name"]
        strat = parsed_args["strat"]
        random_seed = parsed_args["random_seed"]
        time_limit = parsed_args["time_limit"]
        memory_limit = parsed_args["memory_limit"]
        nb_core = parsed_args["nb_core"]
        csv_path = parsed_args["csv_path"]
    end

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

    if isnothing(csv_path)
        csv_path = ""
        save_performance = false
    else
        save_performance = true
    end

    @eval(Base.Sys, CPU_THREADS=$nb_core)

    Random.seed!(random_seed)

    memory_limit += Int(ceil(Base.gc_total_bytes(Base.gc_num())/2^20))
    
    model = SeaPearl.solve_XCSP3_instance(bench_name, strat, time_limit, memory_limit, save_performance, csv_path, include_time)
end

main()
