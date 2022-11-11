using Random

function loadInstance(fname)
    f=open(fname)
    # read the parameters of the instance, here m, n, p and r
    m, n, p, r = parse.(Int, split(readline(f)) )

    # read the location of the m facilities
    concentrators=zeros(Float32, m, 2)
    for i=1:m
        values = split(readline(f))
        for j in 1:2
            coordinate = parse(Float32,values[j])
            concentrators[i,j]= coordinate
        end
    end

    # read the location of the n demands
    terminals=zeros(Float32, n, 3)
    for i=1:n
        values = split(readline(f))
        for j in 1:3
            coordinate = parse(Float32,values[j])
            terminals[i,j]= coordinate
        end
    end


    close(f)
    return m, n, p, r, concentrators, terminals
end

function generatePopulation(sizePopulation::Int, concentrators::Matrix{Float32}, p::Int)
    solutions = Array{Array{Int}}
    numberConcentrators = size(concentrators,1)
    setOfConcentrators = []
    for i in 1:numberConcentrators
        push!(setOfConcentrators, i)
    end

    for i in 1:(Int)(floor(sizePopulation/2))
        # pick a random facility
        randConcentrator = rand(1:numberConcentrators)
        println("randFacility = ", randConcentrator)
        solution = [randConcentrator]
        # we add other facility with a metaheuristic based on GRASP
        CL = copy(setOfConcentrators) # candidate list
        splice!(CL,randConcentrator)
        RCL = [] # restricted candidate list
        for i in 1:(p-1)

        end
    end
    for i in (Int)(floor(sizePopulation/2))+1:sizePopulation

    end
end

function main(pathToInstance::String, sizePopulation::Int)

    # opening the instance
    m, n, p, r, concentrators, demands = loadInstance(pathToInstance)
    println("m = ", m, " (# concentrators)")
    println("n = ", n, " (# terminals)")
    println("p = ", p, " (# concentrators to open (level 1 & 2)")
    println("r = ", r)

    # here, we shuffle concentrators to avoid bias during the picking
    tempArray = Array{Int}(1:m)
    shuffle!(tempArray)
    newConcentrators = zeros(Float32, m, 2)
    for i in 1:m
        newConcentrators[i,1:2] = concentrators[tempArray[i],1:2]
    end
    concentrators = deepcopy(newConcentrators)

    # we generate randomized costs for linking terminals to concentrators
    costs = zeros(m,n)
    for i in 1:m
        for j in 1:n
            randCost = rand(1:50)
            costs[i,j] = randCost
        end
    end

    # we generate the distance matrix between terminals and concentrators
    distances = zeros(m,n)
    for i in 1:m
        for j in 1:n
            randDist = rand(20:70)
            distances[i,j] = randDist
        end
    end

    # we want to divide the set of concentrators in two levels
    # here, we have 4/5 of level 1 and 1/5 of level 2 concentrators
    p1 = (Int)(4*p/5)
    p2 = p - p1
    println("p1 = ", p1, " (# level 1 concentrators)")
    println("p2 = ", p2, " (# level 2 concentrators)")

    # we generate our first population of solution
    # half is good for the first objective the other is good for the second one
    generatePopulation(sizePopulation, concentrators, p)
end

main("Instances/verySmall1.txt", 10)