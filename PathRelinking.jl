include("Tools.jl")

function PathRelinking(initialingSol, guidingSol, n, linkCosts, linkConcentratorsCosts, distancesConcentrators)

    newSols = []
    numberLevel1 = length(initialingSol.setSelectedLevel1)
    numberLevel2 = length(initialingSol.setSelectedLevel2)
    usedPorts = zeros(Int, numberLevel1+numberLevel1)
    for i in 1:n
        usedPorts[initialingSol.linksTerminalLevel1[i]] += 1
    end
    for i in 1:numberLevel1
        usedPorts[initialingSol.setSelectedLevel1[i]] += 1
    end

    # we determine In, the set of level 1 to add and Out the set of level 1 to remove
    In, Out = getSetInOutLevel1(S1, S2)

    # now we generate new solutions from the initialing sol to the guiding sol
    numberIter = length(In)
    currentSol = copy!(initialingSol)
    for i in j:numberIter

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
                currentSol.setSelectedLevel1[i] == randIn
            end
        end
        # then we transfer the terminals linked to the randOut level 1 to the randIn level 1
        deltaObj1 = 0
        for i in 1:length(currentSol.linksTerminalLevel1)
            if currentSol.linksTerminalLevel1[i] == randOut
                deltaObj1 -= linkCosts[randOut,i]
                deltaObj1 += linkCosts[randIn,i]
                currentSol.linksTerminalLevel1[i] == randIn
            end
        end
        temp = usedPorts[randOut]
        usedPorts[randOut] = randIn
        usedPorts[randIn] = temp
        currentSol.valueObj1 += deltaObj1
        append!(newSols, currentSol)
    end

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #

    # we do the same for the level 2 concentrators
    In, Out = getSetInOutLevel2(S1, S2)
    numberIter = length(In)
    for i in j:numberIter

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
                currentSol.setSelectedLevel2[i] == randIn
            end
        end
        # then we transfer the terminals linked to the randOut level 1 to the randIn level 1
        deltaObj1 = 0
        for i in 1:length(currentSol.setSelectedLevel1)
            if currentSol.setSelectedLevel1[i] == randOut
                deltaObj1 -= linkConcentratorsCosts[randOut,i]
                deltaObj1 += linkConcentratorsCosts[randIn,i]
                currentSol.linksTerminalLevel1[i] == randIn
            end
        end
        temp = usedPorts[randOut]
        usedPorts[randOut] = randIn
        usedPorts[randIn] = temp
        currentSol.valueObj1 += deltaObj1
        append!(newSols, currentSol)
    end

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #



    # now, we want the same links between terminals and level 1 in the initiating and the guiding
    # we add a number of update before we return a new solution, otherwise, we have too much solutions to compute and improve
    stop = 0
    max = 10
    for i in 1:n
        # if a terminal is not correctly linked
        level1 = currentSol.linksTerminalLevel1[i]
        if level1 != currentSol.linksTerminalLevel1[j]
            # we look for another free place or we swap two links
            found = false
            j = 1
            while !found && j <= n
                if()
            end
        end
    end

    # trouver les diff entre les sets de concentrateurs de niv 2

    # faire les mouvements

    return newSols
end