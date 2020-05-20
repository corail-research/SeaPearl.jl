function parseInput!(input_data)
    lines = split(input_data, '\n')


    firstLine = split(lines[1], ' ')

    numberOfItems = parse(Int, firstLine[1])
    capacity = parse(Int, firstLine[2])

    items = Array{Union{Item}}(undef, numberOfItems);

    @assert numberOfItems + 2 <= length(lines)

    for i in 1:numberOfItems
        itemArray = split(lines[i+1], ' ')
        item = Item(i, parse(Int, itemArray[1]), parse(Int, itemArray[2]))
        items[i] = item
    end

    return InputData(items, Item[], numberOfItems, capacity)
end

function printSolution(solution::Solution)
    println(solution.value, " ", solution.optimality ? 1 : 0)
    for taken in solution.content
        print(taken ? 1 : 0, " ")
    end
    println()
end

function parseFile!(filename)

    if filename == ""
        throw(ArgumentError("You must specify a data file"))
    end

    toReturn = nothing

    open(filename, "r") do openedFile
        toReturn = parseInput!(read(openedFile, String))
    end
    
    return toReturn
end