"""

He we can create new useful hooks than our users could directly use. 
One can also create a new personalised hook thanks to RL package 
interface and use it. 
"""

struct MyNewHook <: RL.AbstractHook
    name::String
end