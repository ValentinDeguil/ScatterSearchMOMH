include("Tools.jl")

function generateSolutionObj1(linkCosts::Matrix{Float32}, linkConcentratorsCosts::Matrix{Float32}, potentials::Array{Float32}, distancesConcentrators::Matrix{Float32},
    Q::Int, numberLevel1::Int, numberLevel2::Int, n::Int, costOpeningLevel1, costOpeningLevel2)

    valueObj1 = 0
    valueObj2 = 0
    numberConcentrators = numberLevel1 + numberLevel2

    # here, we'll use several occurences of GRASP to generate individuals of our population

    # we determine how many level 1 concentrators will be in the solution
    numberSelectedLevel1 = (Int)(ceil(n/Q))
    valueObj1 += numberSelectedLevel1*costOpeningLevel1

    # now, we launch the GRASP until we get this number of level 1 concentrators, for the first objective
    # the first one is selected randomly
    alphaC1 = 0.7
    randomLevel1 = rand(1:numberLevel1)
    setSelectedLevel1 = [randomLevel1]
    remainingLevel1 = []
    for i in 1:numberLevel1
        append!(remainingLevel1, i)
    end
    deleteat!(remainingLevel1, randomLevel1)

    # the other ones are chosen by GRASP with an alpha of 0.7
    for c1 in 2:numberSelectedLevel1
        # we seek the best and the worst potential
        best = potentials[remainingLevel1[1]]
        worst = best

        for i in 2:size(remainingLevel1,1)
            pot = potentials[remainingLevel1[i]]
            if pot < best
                best = pot
            end
            if pot > worst
                worst = pot
            end
        end

        threshold = worst - alphaC1*(worst-best)
        #println("best = ", best)
        #println("worst = ", worst)
        #println("threshold = ", threshold)

        RCL = []
        for i in 1:size(remainingLevel1,1)
            candidate = remainingLevel1[i]
            #println("on teste si [", candidate, "] ", potentials[candidate], " <= ", threshold)
            if potentials[candidate] <= threshold
                append!(RCL,candidate)
            end
        end
        #println("donc RCL = ", RCL)
        newConcentrator = RCL[rand(1:size(RCL,1))]
        append!(setSelectedLevel1,newConcentrator)
        deleteat!(remainingLevel1, findall(x->x==newConcentrator,remainingLevel1))
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

    for k in 2:n
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
        min = Inf
        for j in 1:(i-1)
            dist = distancesConcentrators[allConcentrators[i],allConcentrators[j]]
            if dist < min
                min = dist
            end
        end
        for j in (i+1):nbConcentrators
            dist = distancesConcentrators[allConcentrators[i],allConcentrators[j]]
            if dist < min
                min = dist
            end
        end
        valueObj2 += min
    end

    println("costOpeningLevel1 = ", costOpeningLevel1)
    println("costOpeningLevel2 = ", costOpeningLevel2)
    println("selectedLevel1 = ", setSelectedLevel1)
    println("links = ", linksTerminalLevel1)
    println("selectedLevel2 = ", setSelectedLevel2)
    println("linksLevel1Level2 = ", linksLevel1Level2)

    println("valueObj1 = ", valueObj1)
    println("valueObj2 = ", valueObj2)

    solutionReturn = solution(setSelectedLevel1,linksTerminalLevel1,setSelectedLevel2,linksLevel1Level2,valueObj1,valueObj2)
    return solutionReturn
    #println((valueObj1))
    #println(valueObj2)

end