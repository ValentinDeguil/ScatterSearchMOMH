
function distanceSolutions(S1, S2)
    concentratorsS1 = vcat(S1.setSelectedLevel1,S1.setSelectedLevel2)
    concentratorsS2 = vcat(S2.setSelectedLevel1,S2.setSelectedLevel2)
    dist = 0
    for i in 1:size(concentratorsS1,1)
        c = concentratorsS1[i]
        j = 1
        found = false
        while !found && j <= size(concentratorsS2,1)
            if(concentratorsS2[j] == c)
                found = true
            end
            j += 1
        end
        if !found
            dist += 1
        end
    end

    return dist
end

function isDifferent(S1, S2)
    linksTermS1 = S1.linksTerminalLevel1
    linksTermS2 = S2.linksTerminalLevel1
    for i in 1:length(linksTermS1)
        if (linksTermS1[i] != linksTermS2[i])
            return false
        end
    end

    linksConcS1 = S1.linksLevel1Level2
    linksConcS2 = S2.linksLevel1Level2
    for i in 1:length(linksConcS1)
        if (linksConcS1[i] != linksConcS2[i])
            return false
        end
    end

    return true
end

function getSetInOutLevel1(S1, S2)
    concentratorsS1 = S1.setSelectedLevel1
    concentratorsS2 = S2.setSelectedLevel1

    Out = setdiff(concentratorsS1,concentratorsS2)
    In = setdiff(concentratorsS2,concentratorsS1)

    return In, Out
end

function getSetInOutLevel2(S1, S2)
    concentratorsS1 = S1.setSelectedLevel2
    concentratorsS2 = S2.setSelectedLevel2

    Out = setdiff(concentratorsS1,concentratorsS2)
    In = setdiff(concentratorsS2,concentratorsS1)

    return In, Out
end

function getValueObj2(S, distancesConcentrators)
    allConcentrators = vcat(S.setSelectedLevel1, S.setSelectedLevel2)
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
end