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

function generatePopulation(sizePopulation::Int, concentrators::Matrix{Float32}, Q::Int, numberLevel1::Int, numberLevel2::Int, n::Int, terminals::Matrix{Float32})
    # here, we'll use several occurences of GRASP to generate individuals of our population

    # first we'll use GRASP to select which level 1 concentrators we open
    population = Array{Array{Int}}
    numberConcentrators = numberLevel1 + numberLevel2

    # we determine how many level 1 concentrators will at least be in the solution
    minimumLevel1::Int = ceil(n/Q)
    # then we flip a coin, we add a concentrator for each head until we get a tail
    while(rand()<0.5)
        minimumLevel1 += 1
        println("yo")
    end
    numberSelectedLevel1 = min(minimumLevel1, numberLevel1)

    # now, we launch the GRASP until we get this number of level 1 concentrators, for the first objective
    # the first one is selected randomly
    randomLevel1 = rand(1:numberLevel1)
    setOfSelectedConcentrators = [randomLevel1]
    # the other ones are chosen by GRASP with an alpha of 0.7
    for c1 in 2:numberSelectedLevel1

    end

    #for i in 1:numberConcentrators
    #    push!(setOfConcentrators, i)
    #end

    #for i in 1:(Int)(floor(sizePopulation/2))
    #    # pick a random facility
    #    randConcentrator = rand(1:numberConcentrators)
    #    println("randFacility = ", randConcentrator)
    #    solution = [randConcentrator]
    #    # we add other facility with a metaheuristic based on GRASP
    #    CL = copy(setOfConcentrators) # candidate list
    #    splice!(CL,randConcentrator)
    #    RCL = [] # restricted candidate list
#
    #end
    for i in (Int)(floor(sizePopulation/2))+1:sizePopulation

    end
end

function main(pathToInstance::String, sizePopulation::Int)

    println("")
    println("Instance of the problem")

    # opening the instance
    m, n, p, r, concentrators, terminals = loadInstance(pathToInstance)
    println("m = ", m, " (# concentrators)")
    println("n = ", n, " (# terminals)")
    println("p = ", p, " (# concentrators to open (level 1 & 2)")
    println("r = ", r)

    # for our constraints we chose the capacitated concentrators
    # so, we have a maximum of 7 links to each concentrator (level 1 & 2)
    Q = 7

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

    #TODO genreate random costs between level 1 and level 2 concentrators

    # we want to divide the set of concentrators in two levels
    # here, we have 4/5 of level 1 and 1/5 of level 2 concentrators
    ratioLevelOne::Float32 = 4/5;
    numberLevel1 = (Int)(m*ratioLevelOne)
    numberLevel2 = m - numberLevel1
    println("numberLevel1 = ", numberLevel1, " (# level 1 concentrators)")
    println("numberLevel2 = ", numberLevel2, " (# level 2 concentrators)")

    println("")
    println("-----------------------------")
    println("")

    # we generate our first population of solution
    # half is good for the first objective the other is good for the second one
    generatePopulation(sizePopulation, concentrators, Q, numberLevel1, numberLevel2, n, terminals)
end

main("Instances/verySmall1.txt", 10)