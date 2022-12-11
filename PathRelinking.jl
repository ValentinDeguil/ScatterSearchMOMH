include("Tools.jl")

function PathRelinking(initialingSol, guidingSol, n, m, Q, linkCosts, linkConcentratorsCosts, distancesConcentrators)

    newSols = []
    numberLevel1 = length(initialingSol.setSelectedLevel1)
    numberLevel2 = length(initialingSol.setSelectedLevel2)
    usedPorts = zeros(Int, m)
    for i in 1:n
        usedPorts[initialingSol.linksTerminalLevel1[i]] += 1
    end
    for i in 1:numberLevel1
        usedPorts[initialingSol.linksLevel1Level2[i]] += 1
    end

    # we determine In, the set of level 1 to add and Out the set of level 1 to remove
    In, Out = getSetInOutLevel1(initialingSol, guidingSol)

    # now we generate new solutions from the initialing sol to the guiding sol
    numberIter = length(In)
    currentSol = solution(copy(initialingSol.setSelectedLevel1), copy(initialingSol.linksTerminalLevel1), copy(initialingSol.setSelectedLevel2), copy(initialingSol.linksLevel1Level2), initialingSol.valueObj1, initialingSol.valueObj2, initialingSol.index)
    for i in 1:numberIter

        # we select a random move
        randInIndex = rand(1:length(In))
        randIn = In[randInIndex]
        deleteat!(In, randInIndex)

        randOutIndex = rand(1:length(Out))
        randOut = Out[randOutIndex]
        deleteat!(Out, randOutIndex)

        # we edit our previous solution to get a new one closer to the guiding sol
        # first we close the randOut level 1 and open the randIn level 1
        for i in 1:length(currentSol.setSelectedLevel1)
            if currentSol.setSelectedLevel1[i] == randOut
                currentSol.setSelectedLevel1[i] = randIn
            end
        end

        # then we transfer the terminals linked to the randOut level 1 to the randIn level 1
        deltaObj1::Float32 = 0
        for i in 1:length(currentSol.linksTerminalLevel1)
            if currentSol.linksTerminalLevel1[i] == randOut
                deltaObj1 -= linkCosts[randOut,i]
                deltaObj1 += linkCosts[randIn,i]
                currentSol.linksTerminalLevel1[i] = randIn
            end
        end
        temp = usedPorts[randOut]
        usedPorts[randOut] = usedPorts[randIn]
        usedPorts[randIn] = temp
        currentSol.valueObj1 += deltaObj1
        obj2 = getValueObj2(currentSol, distancesConcentrators)
        currentSol.valueObj2 = obj2
        newValue = CalculCoutLink(linkCosts,currentSol.linksTerminalLevel1) + CalculCoutLinkConcentrators(linkConcentratorsCosts,currentSol.setSelectedLevel1,currentSol.linksLevel1Level2)
        currentSol.valueObj1 = newValue
        push!(newSols, solution(copy(currentSol.setSelectedLevel1), copy(currentSol.linksTerminalLevel1), copy(currentSol.setSelectedLevel2), copy(currentSol.linksLevel1Level2), currentSol.valueObj1, currentSol.valueObj2, currentSol.index))
    end

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #

    # we do the same for the level 2 concentrators
    In, Out = getSetInOutLevel2(currentSol, guidingSol)
    numberIter = length(In)
    for i in 1:numberIter

        # we select a random move
        randInIndex = rand(1:length(In))
        randIn = In[randInIndex]
        deleteat!(In, randInIndex)

        randOutIndex = rand(1:length(Out))
        randOut = Out[randOutIndex]
        deleteat!(Out, randOutIndex)

        # we edit our previous solution to get a new one closer to the guiding sol
        # first we close the randOut level 2 and open the randIn level 2
        for i in 1:length(currentSol.setSelectedLevel2)
            if currentSol.setSelectedLevel2[i] == randOut
                currentSol.setSelectedLevel2[i] = randIn
            end
        end
        # then we transfer the level1 linked to the randOut level 2 to the randIn level 2
        deltaObj1 = 0
        for i in 1:length(currentSol.linksLevel1Level2)
            if currentSol.linksLevel1Level2[i] == randOut
                deltaObj1 -= linkConcentratorsCosts[randOut,currentSol.setSelectedLevel1[i]]
                deltaObj1 += linkConcentratorsCosts[randIn,currentSol.setSelectedLevel1[i]]
                currentSol.linksLevel1Level2[i] = randIn
            end
        end

        temp = usedPorts[randOut]
        usedPorts[randOut] = usedPorts[randIn]
        usedPorts[randIn] = temp
        currentSol.valueObj1 += deltaObj1
        obj2 = getValueObj2(currentSol, distancesConcentrators)
        currentSol.valueObj2 = obj2
        newValue = CalculCoutLink(linkCosts,currentSol.linksTerminalLevel1) + CalculCoutLinkConcentrators(linkConcentratorsCosts,currentSol.setSelectedLevel1,currentSol.linksLevel1Level2)
        currentSol.valueObj1 = newValue
        push!(newSols, solution(copy(currentSol.setSelectedLevel1), copy(currentSol.linksTerminalLevel1), copy(currentSol.setSelectedLevel2), copy(currentSol.linksLevel1Level2), currentSol.valueObj1, currentSol.valueObj2, currentSol.index))
    end

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #

    # now, we want the same links between terminals and level 1 in the initiating and the guiding
    # we add a number of update before we return a new solution, otherwise, we have too much solutions to compute and improve
    nbModif = 0
    maxModif = 10
    for i in 1:n
        linkCurrent = currentSol.linksTerminalLevel1[i]
        linkGuiding = guidingSol.linksTerminalLevel1[i]
        # if a terminal is well linked, we do nothing
        if(linkCurrent != linkGuiding)
            # if the terminal can just be moved, we do this
            if usedPorts[linkGuiding] < Q
                currentSol.linksTerminalLevel1[i] = linkGuiding
                deltaObj = 0
                deltaObj1 = -linkCosts[linkCurrent, i]
                deltaObj1 += linkCosts[linkGuiding, i]
                currentSol.valueObj1 += deltaObj1
                usedPorts[linkGuiding] += 1
                usedPorts[linkCurrent] -= 1
                nbModif += 1
            else
                j = i+1
                found = false
                # we look for another bad linked terminal
                while !found && j <= n
                    testLinkCurrent = currentSol.linksTerminalLevel1[j]
                    if(testLinkCurrent == linkGuiding && guidingSol.linksTerminalLevel1[j] != linkGuiding)
                        # we invert them
                        found = true
                        deltaObj1 = 0
                        deltaObj1 = -linkCosts[linkCurrent, i]
                        deltaObj1 -= linkCosts[testLinkCurrent, j]
                        deltaObj1 += linkCosts[linkGuiding, i]
                        deltaObj1 += linkCosts[linkCurrent, j]
                        currentSol.valueObj1 += deltaObj1
                        currentSol.linksTerminalLevel1[i] = linkGuiding
                        currentSol.linksTerminalLevel1[j] = linkCurrent
                        nbModif += 1
                    else
                        # we look for another one bad linked terminal
                        j += 1
                    end
                end
            end
        end

        if nbModif == maxModif
            newValue = CalculCoutLink(linkCosts,currentSol.linksTerminalLevel1) + CalculCoutLinkConcentrators(linkConcentratorsCosts,currentSol.setSelectedLevel1,currentSol.linksLevel1Level2)
            currentSol.valueObj1 = newValue
            push!(newSols, solution(copy(currentSol.setSelectedLevel1), copy(currentSol.linksTerminalLevel1), copy(currentSol.setSelectedLevel2), copy(currentSol.linksLevel1Level2), currentSol.valueObj1, currentSol.valueObj2, currentSol.index))
            nbModif = 0
        end
    end

    return newSols
end