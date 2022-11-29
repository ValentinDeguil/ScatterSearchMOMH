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

function generatePopulation(sizePopulation::Int, concentrators::Matrix{Float32}, linkCosts::Matrix{Float64}, potentials::Array{Float32},
     distances::Matrix{Float32}, Q::Int, numberLevel1::Int, numberLevel2::Int, n::Int, terminals::Matrix{Float32})
    # here, we'll use several occurences of GRASP to generate individuals of our population

    # first we'll use GRASP to select which level 1 concentrators we open
    population = Array{Array{Int}}
    numberConcentrators = numberLevel1 + numberLevel2
    alphaC1 = 0.7

    # we determine how many level 1 concentrators will at least be in the solution
    minimumLevel1::Int = ceil(n/Q)
    # then we flip a coin, we add a concentrator for each head until we get a tail
    while(rand()<0.5)
        minimumLevel1 += 1
    end
    numberSelectedLevel1 = min(minimumLevel1, numberLevel1)

    # now, we launch the GRASP until we get this number of level 1 concentrators, for the first objective
    # the first one is selected randomly
    randomLevel1 = rand(1:numberLevel1)
    setOfSelectedConcentrators = [randomLevel1]
    initialCL = [Int[] for _=1:numberLevel1]
    for i in 1:numberLevel1
        initialCL[i] = [potentials[i],i]
    end
    deleteat!(initialCL,randomLevel1)
    sort!(initialCL)

    # the other ones are chosen by GRASP with an alpha of 0.7
    for c1 in 2:numberSelectedLevel1
        # we seek the best and the worst potential
        best = initialCL[1,1]
        worst = initialCL[size(initialCL,1),1]
        threshold = worst[1] - alphaC1*(worst[1]-best[1])
        RCL = []

        sizeRCL = 0
        for i in 1:size(initialCL,1)

            if initialCL[i][1] <= threshold
                sizeRCL += 1
            end
        end
        newConcentrator = rand(1:sizeRCL)
        append!(setOfSelectedConcentrators,initialCL[newConcentrator][2])
        deleteat!(initialCL, newConcentrator)
    end

    println("setOfSelectedConcentrators = ", setOfSelectedConcentrators)

    println("debut debug")

    # now, we determine which links between terminals and level 1 concentrators are active
    # the second GRASP starts with a randomly chosen link
    alphaLinks = 0.7
    randTerminal = rand(1:n)
    randLevel1 = setOfSelectedConcentrators[rand(1:numberSelectedLevel1)]
    linksTerminalLevel1 = [[randLevel1, randTerminal]]
    usedPorts = zeros(Int, size(concentrators,1))
    usedPorts[randLevel1] += 1
    #println("linksTerminalLevel1 = ", linksTerminalLevel1)

    remainingTerminals = []
    for i in 1:n
        append!(remainingTerminals, i)
    end
    deleteat!(remainingTerminals, randTerminal)

    remainingLevel1 = copy(setOfSelectedConcentrators)

    RCL = Vector{Vector{Int}}()

    for i in 2:n

        best = linkCosts[remainingLevel1[1], remainingTerminals[1]]
        worst = best

        for i in 1:size(remainingLevel1, 1)
            for j in 1:size(remainingTerminals, 1)
                costCandidate = linkCosts[remainingLevel1[i],remainingTerminals[j]]
                if costCandidate < best
                    best = costCandidate
                end
                if costCandidate > worst
                    worst = costCandidate
                end
            end
        end

        threshold = worst - alphaLinks*(worst-best)
        empty!(RCL)

        for i in 1:size(remainingLevel1, 1)
            for j in 1:size(remainingTerminals, 1)
                cost = linkCosts[remainingLevel1[i],remainingTerminals[j]]
                if cost <= threshold
                    newCandidate = [remainingLevel1[i],remainingTerminals[j]]
                    append!(RCL, [newCandidate])
                end
            end
        end
        #println("RCL après boucle = ", RCL)
        #println("best = ", best)
        #println("worst = ", worst)
        #println("threshold = ", threshold)
        for i in 1:size(RCL, 1)

        end
        newLink = RCL[rand(1:size(RCL,1))]
        append!(linksTerminalLevel1,[newLink])
        selectedLevel1 = newLink[1]
        usedPorts[selectedLevel1] += 1
        if usedPorts[selectedLevel1] == Q
            deleteat!(remainingLevel1, findall(x->x==selectedLevel1,remainingLevel1))
        end
        deleteat!(remainingTerminals, findall(x->x==newLink[2],remainingTerminals))
    end

    println("links = ", linksTerminalLevel1)

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
    linkCosts = zeros(m,n)
    for i in 1:m
        for j in 1:n
            randCost = rand(10:50)
            linkCosts[i,j] = randCost
        end
    end

    # we generate the distance matrix between terminals and concentrators
    distances = zeros(Float32, m, n)
    for i in 1:m
        for j in 1:n
            dist = (concentrators[i,1]-terminals[j,1])^2 + (concentrators[i,2]-terminals[j,2])^2
            dist = dist^0.5
            distances[i,j] = dist
        end
    end

    # we estimate the potential of each concentrator
    potentials = zeros(Float32, m)
    for i in 1:m
        for j in 1:n
            potentials[i] += linkCosts[i,j]
        end
    end

    #TODO generate random costs between level 1 and level 2 concentrators

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
    @time for i in 1:1
        generatePopulation(sizePopulation, concentrators, linkCosts, potentials, distances, Q, numberLevel1, numberLevel2, n, terminals)
    end
end

main("Instances/verySmall1.txt", 10)