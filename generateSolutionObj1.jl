
function generateSolutionObj1(obj::Int, linkCosts::Matrix{Float64}, linkConcentratorsCosts::Matrix{Float64}, potentials::Array{Float32}, distancesConcentrators::Matrix{Float32},
    Q::Int, numberLevel1::Int, numberLevel2::Int, n::Int, costOpeningLevel1::Int64, costOpeningLevel2::Int64)

    valueObj1 = 0
    valueObj2 = 0
    # here, we'll use several occurences of GRASP to generate individuals of our population

    # first we'll use GRASP to select which level 1 concentrators we open
    population = Array{Array{Int}}
    numberConcentrators = numberLevel1 + numberLevel2
    alphaC1 = 0.7

    # we determine how many level 1 concentrators will be in the solution
    numberSelectedLevel1 = (Int)(ceil(n/Q))
    valueObj1 += numberSelectedLevel1*costOpeningLevel1

    # now, we launch the GRASP until we get this number of level 1 concentrators, for the first objective
    # the first one is selected randomly
    randomLevel1 = rand(1:numberLevel1)
    setSelectedLevel1 = [randomLevel1]
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

        sizeRCL = 0
        for i in 1:size(initialCL,1)
            if initialCL[i][1] <= threshold
                sizeRCL += 1
            end
        end
        newConcentrator = rand(1:sizeRCL)
        append!(setSelectedLevel1,initialCL[newConcentrator][2])
        deleteat!(initialCL, newConcentrator)
    end

    # now, we determine which links between terminals and level 1 concentrators are active
    # the second GRASP starts with a randomly chosen link
    alphaLinks = 0.7
    linksTerminalLevel1 = zeros(Int,n)
    randTerminal = rand(1:n)
    randLevel1 = setSelectedLevel1[rand(1:numberSelectedLevel1)]
    linksTerminalLevel1[randTerminal] = randLevel1
    usedPorts = zeros(Int, numberLevel1+numberLevel2)
    usedPorts[randLevel1] += 1
    valueObj1 += linkCosts[randLevel1, randTerminal]


    remainingTerminals = []
    for i in 1:n
        append!(remainingTerminals, i)
    end
    deleteat!(remainingTerminals, randTerminal)

    remainingLevel1 = copy(setSelectedLevel1)

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

        newLink = RCL[rand(1:size(RCL,1))]
        selectedLevel1 = newLink[1]
        linksTerminalLevel1[newLink[2]] = selectedLevel1
        usedPorts[selectedLevel1] += 1
        if usedPorts[selectedLevel1] == Q
            deleteat!(remainingLevel1, findall(x->x==selectedLevel1,remainingLevel1))
        end
        deleteat!(remainingTerminals, findall(x->x==newLink[2],remainingTerminals))
        valueObj1 += linkCosts[selectedLevel1, newLink[2]]
    end

    # the third GRASP will determine which level2 concentrator is used

    alphaC2 = 0.7
    numberSelectedLevel2 = (Int)(ceil(numberSelectedLevel1/Q))
    valueObj1 += numberSelectedLevel2*costOpeningLevel2
    remainingLevel2 = []
    for i in (numberLevel1+1):numberConcentrators
        append!(remainingLevel2, i)
    end

    setSelectedLevel2 = []

    for i in 1:numberSelectedLevel2
        best = potentials[remainingLevel2[1]]
        worst = best
        for j in 2:size(remainingLevel2,1)
            candidatePot = potentials[remainingLevel2[j]]
            if candidatePot < best
                best = candidatePot
            end
            if candidatePot > worst
                worst = candidatePot
            end
        end
        threshold = worst - alphaC2*(worst-best)
        RCL = []
        for j in 1:size(remainingLevel2,1)
            candidatePot = potentials[remainingLevel2[j]]
            if candidatePot <= threshold
                append!(RCL,j)
            end
        end
        newLevel2Concentrator = remainingLevel2[RCL[rand(1:(size(RCL,1)))]]
        append!(setSelectedLevel2,newLevel2Concentrator)
        deleteat!(remainingLevel2, findall(x->x==newLevel2Concentrator,remainingLevel2))
    end

    # forth and last GRASP to determine which links between level1 & level2 concentrators are used
    alphaLinks2 = 0.7
    linksLevel1Level2 = zeros(Int,numberSelectedLevel1)
    remainingLevel2 = copy(setSelectedLevel2)
    # first, we select a random link to add diversity
    randLevel1 = rand(1:numberSelectedLevel1)
    randLevel2 = setSelectedLevel2[rand(1:numberSelectedLevel2)]
    linksLevel1Level2[randLevel1] = randLevel2
    usedPorts[randLevel2] += 1
    valueObj1 += linkConcentratorsCosts[setSelectedLevel1[randLevel1], randLevel2]

    for i in 1:numberSelectedLevel1
        if(i != randLevel1)
            level1 = setSelectedLevel1[i]
            best = linkConcentratorsCosts[level1, remainingLevel2[1]]
            worst = best
            for j in 1:size(remainingLevel2,1)
                candidate = linkConcentratorsCosts[level1, remainingLevel2[j]]
                if candidate < best
                    best = candidate
                end
                if candidate > worst
                    worst = candidate
                end
            end

            threshold = worst - alphaLinks2*(worst-best)
            RCL = []
            for j in 1:size(remainingLevel2,1)
                candidate = linkConcentratorsCosts[level1, remainingLevel2[j]]
                if (candidate <= threshold)
                    append!(RCL, remainingLevel2[j])
                end
            end
            selectedLevel2 = RCL[rand(1:size(RCL,1))]
            linksLevel1Level2[i] = selectedLevel2
            usedPorts[selectedLevel2] += 1
            if(usedPorts[selectedLevel2] >= Q)
                deleteat!(remainingLevel2, findall(x->x==selectedLevel2,remainingLevel2))

            end
            valueObj1 += linkConcentratorsCosts[setSelectedLevel1[i],selectedLevel2]
        end
    end

    allConcentrators = vcat(setSelectedLevel1, setSelectedLevel2)
    nbConcentrators = numberSelectedLevel1 + numberSelectedLevel2
    for i in 1:nbConcentrators
        for j in 1:nbConcentrators
            valueObj2 += distancesConcentrators[allConcentrators[i],allConcentrators[j]]
        end
    end

    println("selectedLevel1 = ", setSelectedLevel1)
    println("links = ", linksTerminalLevel1)
    println("selectedLevel2 = ", setSelectedLevel2)
    println("linksLevel1Level2 = ", linksLevel1Level2)

    println("valueObj1 = ", valueObj1)
    println("valueObj2 = ", valueObj2)

end