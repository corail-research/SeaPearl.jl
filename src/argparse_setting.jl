using ArgParse
using Random

using SeaPearl

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
        "--random_seed", "-s"
            help = "seed to intialize the random number generator"
            arg_type = Int
            default = 0
            # required = true
        "--time_limit", "-t"
            help = "total CPU time (in seconds) allowed"
            arg_type = Int
            default = nothing # moddify to take into account the capacity of the computer 
            # required = true
        "--memory_limit", "-m"
            help = "total amount of memory (in MiB) allowed"
            arg_type = Int
            default = nothing # moddify to take into account the capacity of the computer 
            # required = true
        "--nb_core", "-c"
            help = "number of processing units allocated"
            arg_type = Int
            default = nothing # moddify to take into account the capacity of the computer 
            # required = true
        "--tmp_dir", "-d"
            help = "directory where temporary files can be read/write"
            arg_type = String
            # required = true
        "--dir"
            help = "directory where the solver files are located"
            arg_type = String
            # required = true
    end
    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()

    bench_name = parsed_args["bench_name"]
    random_seed = parsed_args["random_seed"]
    time_limit = parsed_args["time_limit"]
    memory_limit = parsed_args["memory_limit"]
    nb_core = parsed_args["nb_core"]
    tmp_dir = parsed_args["tmp_dir"]
    dir = parsed_args["dir"]

    println("Parsed args:")
    println("bench_name : ", bench_name)
    println("random_seed : ", random_seed)
    println("time_limit : ", time_limit)
    println("memory_limit : ", memory_limit)
    println("nb_core : ", nb_core)
    println("tmp_dir : ", tmp_dir)
    println("dir : ", dir) # /Documents/CORAIL/SeaPearl/instancesXCSP22/xml/MiniCSP

    println("GC live: ", Base.gc_live_bytes()/2^20, " MiB\n")

    if isnothing(tmp_dir)
        tmp_dir = ""
    end

    if isnothing(dir)
        dir = ""
    end

    # device = nb_core # TODO

    Random.seed!(random_seed)

    model = SeaPearl.solve_XCSP3_instance(bench_name, time_limit, memory_limit)
end

main()

# julia --project src/argparse_setting.jl -b "instancesXCSP22/xml/MiniCOP/ClockTriplet-03-12_c22.xml" -s 42 -t 120 -m 1000 -c 0 -d "" --dir ""