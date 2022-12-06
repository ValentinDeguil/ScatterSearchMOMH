
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
    for i in 1:size(linksTermS1)
        if (linksTermS1[i] != linksTermS2[i])
            return false
        end
    end

    linksConcS1 = S1.linksLevel1Level2
    linksConcS2 = S2.linksLevel1Level2
    for i in 1:size(linksTermS1)
        if (linksConcS1[i] != linksConcS2[i])
            return false
        end
    end

    return true
end