"These fonctions are based on the package https://github.com/cormullion/TickTock.jl and are used to compute the elapsed time during a search."

"""
    tic()
Start a timer.
"""
function tic()
    t0 = time_ns()
    task_local_storage(:TIMERS, (t0, get(task_local_storage(), :TIMERS, ())))
end

"""
    peektimer()
Return the elapsed seconds counted by the most recent timer, without stopping it.
"""
function peektimer()
    t1 = time_ns()
    timers = get(task_local_storage(), :TIMERS, ())
    if timers === ()
        error("Use `tick()` to start a timer.")
    end
    t0 = timers[1]::UInt64
    return (t1 - t0)/1e9
end