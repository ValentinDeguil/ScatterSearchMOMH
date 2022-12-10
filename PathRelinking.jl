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
    #println("avant")
    #println("initialingSol level1 = ", initialingSol.setSelectedLevel1)
    #println("guidingSol level1 = ", guidingSol.setSelectedLevel1)
    #println("In = ", In, " Out = ", Out)
    #println("ValueObj1 Initiating = ", initialingSol.valueObj1)
    #println("ValueObj2 Initiating = ", initialingSol.valueObj2)
    #println("ValueObj1 Guiding = ", guidingSol.valueObj1)
    #println("ValueObj2 Guiding = ", guidingSol.valueObj2)

    # now we generate new solutions from the initialing sol to the guiding sol
    numberIter = length(In)
    currentSol = solution(copy(initialingSol.setSelectedLevel1), copy(initialingSol.linksTerminalLevel1), copy(initialingSol.setSelectedLevel2), copy(initialingSol.linksLevel1Level2), initialingSol.valueObj1, initialingSol.valueObj2)
    for i in 1:numberIter

        # we select a random move
        randInIndex = rand(1:length(In))
        randIn = In[randInIndex]
        deleteat!(In, randInIndex)

        randOutIndex = rand(1:length(Out))
        randOut = Out[randOutIndex]
        deleteat!(Out, randOutIndex)

        #println("random couple = ", randOut, " ", randIn)
        #println("avant transfert : ", currentSol.setSelectedLevel1)
        #println("avant transfert : ", currentSol.linksTerminalLevel1)

        # we edit our previous solution to get a new one closer to the guiding sol
        # first we close the randOut level 1 and open the randIn level 1
        for i in 1:length(currentSol.setSelectedLevel1)
            if currentSol.setSelectedLevel1[i] == randOut
                currentSol.setSelectedLevel1[i] = randIn
            end
        end

        # then we transfer the terminals linked to the randOut level 1 to the randIn level 1
        deltaObj1 = 0
        for i in 1:length(currentSol.linksTerminalLevel1)
            if currentSol.linksTerminalLevel1[i] == randOut
                deltaObj1 -= linkCosts[randOut,i]
                deltaObj1 += linkCosts[randIn,i]
                currentSol.linksTerminalLevel1[i] = randIn
            end
        end
        #println("après transfert : ", currentSol.setSelectedLevel1)
        #println("après transfert : ", currentSol.linksTerminalLevel1)
        temp = usedPorts[randOut]
        usedPorts[randOut] = usedPorts[randIn]
        usedPorts[randIn] = temp
        currentSol.valueObj1 += deltaObj1
        obj2 = getValueObj2(currentSol, distancesConcentrators)
        currentSol.valueObj2 = obj2
        push!(newSols, solution(copy(currentSol.setSelectedLevel1), copy(currentSol.linksTerminalLevel1), copy(currentSol.setSelectedLevel2), copy(currentSol.linksLevel1Level2), currentSol.valueObj1, currentSol.valueObj2))
    end

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    #println("on passe aux concentrateurs de level 2")
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

        #println("random couple = ", randOut, " ", randIn)
        #println("avant transfert : ", currentSol.setSelectedLevel2)
        #println("avant transfert : ", currentSol.linksLevel1Level2)

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
                deltaObj1 -= linkConcentratorsCosts[randOut,i]
                deltaObj1 += linkConcentratorsCosts[randIn,i]
                currentSol.linksLevel1Level2[i] = randIn
            end
        end
        #println("avant transfert : ", currentSol.setSelectedLevel2)
        #println("avant transfert : ", currentSol.linksLevel1Level2)
        temp = usedPorts[randOut]
        usedPorts[randOut] = usedPorts[randIn]
        usedPorts[randIn] = temp
        currentSol.valueObj1 += deltaObj1
        obj2 = getValueObj2(currentSol, distancesConcentrators)
        currentSol.valueObj2 = obj2
        push!(newSols, solution(copy(currentSol.setSelectedLevel1), copy(currentSol.linksTerminalLevel1), copy(currentSol.setSelectedLevel2), copy(currentSol.linksLevel1Level2), currentSol.valueObj1, currentSol.valueObj2))
    end

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    #println("on passe aux liens des terminaux")
    #println("usedPorts = ", usedPorts)
    #println("current selectedLevel1 = ", currentSol.setSelectedLevel1)
    #println("current linksTerminalLevel1 = ", currentSol.linksTerminalLevel1)
    #println("guiding linksTerminalLevel1 = ", guidingSol.linksTerminalLevel1)
    #println("current selectedLevel2 = ", currentSol.setSelectedLevel2)
    #println("current linksLevel1Level2 = ", currentSol.linksLevel1Level2)
    # now, we want the same links between terminals and level 1 in the initiating and the guiding
    # we add a number of update before we return a new solution, otherwise, we have too much solutions to compute and improve
    nbModif = 0
    maxModif = 10
    for i in 1:n
        linkCurrent = currentSol.linksTerminalLevel1[i]
        linkGuiding = guidingSol.linksTerminalLevel1[i]
        #println("new test, i = ", i)
        #println("linkCurrent = ", linkCurrent)
        #println("linkGuiding = ", linkGuiding)
        # if a terminal is well linked, we do nothing
        if(linkCurrent != linkGuiding)
            # if the terminal can just be moved, we do this
            if usedPorts[linkGuiding] < Q
                #println("on peut juste inverser")
                #println("current linksTerminalLevel1 = ", currentSol.linksTerminalLevel1)
                currentSol.linksTerminalLevel1[i] = linkGuiding
                deltaObj1 = -linkCosts[linkCurrent, i]
                deltaObj1 += linkCosts[linkGuiding, i]
                currentSol.valueObj1 += deltaObj1
                usedPorts[linkGuiding] += 1
                usedPorts[linkCurrent] -= 1
                nbModif += 1
                #println("current linksTerminalLevel1 = ", currentSol.linksTerminalLevel1)
                #println("guiding linksTerminalLevel1 = ", guidingSol.linksTerminalLevel1)
            else
                #println("ok plus compliqué")
                j = i+1
                found = false
                # we look for another bad linked terminal
                while !found && j <= n
                    testLinkCurrent = currentSol.linksTerminalLevel1[j]
                    if(testLinkCurrent == linkGuiding && guidingSol.linksTerminalLevel1[j] != linkGuiding)
                        # we invert them
                        found = true
                        deltaObj1 = -linkCosts[linkCurrent, i]
                        deltaObj1 -= linkCosts[testLinkCurrent, j]
                        deltaObj1 += linkCosts[linkGuiding, i]
                        deltaObj1 += linkCosts[linkCurrent, j]
                        #println("current linksTerminalLevel1 = ", currentSol.linksTerminalLevel1)
                        #println("AVANT OBJ1 ", currentSol.valueObj1)
                        #println("deltaObj1 = ", deltaObj1)
                        currentSol.valueObj1 += deltaObj1
                        #println("APRES OBJ1 ", currentSol.valueObj1)
                        currentSol.linksTerminalLevel1[i] = linkGuiding
                        currentSol.linksTerminalLevel1[j] = linkCurrent
                        #println("current linksTerminalLevel1 = ", currentSol.linksTerminalLevel1)
                        #println("guiding linksTerminalLevel1 = ", guidingSol.linksTerminalLevel1)
                        nbModif += 1
                    else
                        # we look for another one bad linked terminal
                        j += 1
                    end
                end
            end
        end
        #println("")

        if nbModif == maxModif
            #println("nouvelle solution car 10 modifs")
            #println("val Obj1 = ", currentSol.valueObj1)
            #println("val Obj2 = ", currentSol.valueObj2)
            #println("")
            push!(newSols, solution(copy(currentSol.setSelectedLevel1), copy(currentSol.linksTerminalLevel1), copy(currentSol.setSelectedLevel2), copy(currentSol.linksLevel1Level2), currentSol.valueObj1, currentSol.valueObj2))
            nbModif = 0
        end
    end

    # trouver les diff entre les sets de concentrateurs de niv 2

    # faire les mouvements

    #println("length = ", length(newSols))
    for i in 1:length(newSols)
        #println(newSols[i].valueObj1)
        #println(newSols[i].valueObj2)
        #println("")
    end
    return newSols
end