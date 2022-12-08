#=
TabuSearch:
- Julia version:
- Author: mathey
- Date: 2022-12-03
=#
using DataStructures


mutable struct solution
    setSelectedLevel1::Vector{Int64}
    linksTerminalLevel1::Vector{Int64}
    setSelectedLevel2::Vector{Int64}
    linksLevel1Level2::Vector{Int64}
    valueObj1::Float64
    valueObj2::Float64
end

function TabuSearch(f::Int64,sol::solution ,costOpeningLevel1::Vector{Float64}, costOpeningLevel2::Vector{Float64}, distancesConcentrators::Matrix{Float32},linkConcentratorsCosts::Matrix{Float32},linkCosts::Matrix{Float32})

    tempSolution = copy(sol)

    nbrIteration = 5
    listeTabou = []
    k = 0

    bestVoisin = copy(sol) #meilleur voisin trouvé
    voisinTempSolution = copy(sol) #voisin local

    while k < 10
        boolAmelioration = false #booleen vrai si le voisin améliore la solution faux sinon

        # Création du voisinage

        #bestVoisinTemp permet de sauvegarder le meilleur swap local, ce voisin est choisi lorsque aucun swap améliore la solution
        #bestVoisinTemp = copy(voisinTempSolution)
        #bestVoisinTemp.valueObj1=Inf()
        #bestVoisinTemp.valueObj1=-Inf()

        ############################### Swap pour les Concentrateurs de niveau 1##################################
        i=1
        while (i <= length(voisinTempSolution.setSelectedLevel1) && !boolAmelioration)
            j = 1
            while (j <= length(costOpeningLevel1) && !boolAmelioration)
                if (!(j in voisinTempSolution.setSelectedLevel1) && !(j in listeTabou)) #Possible amélioration avec tri et Dichotomie
                    if (f == 1) # f = 1 pour objectif 1
                        tempValueObj = differenceObjectif1(i,j,voisinTempSolution.linksTerminalLevel1,linkCosts,costOpeningLevel1) #différence entre les solutions
                        if (tempObj<0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                            #Mise A Jour des Variables
                            boolAmelioration = true
                            push!(listeTabou, i)
                            voisinTempSolution.valueObj1 += tempValueObj
                            voisinTempSolution.setSelectedLevel1[findfirst(x -> x==i,voisinTempSolution.setSelectedLevel1)] = j
                            push!(voisinTempSolution.setSelectedLevel1,j)
                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                                if (voisinTempSolution.linksTerminalLevel1[k] == i)
                                    voisinTempSolution.linksTerminalLevel1[k] = j
                                end
                            end
                            voisinTempSolution.ValueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)


#                        elseif ((voisinTempSolution.valueObj1 + tempValueObj) < bestVoisinTemp.valueObj1) #Si le swap à permis une amélioration par rapport à bestVoisinTemp
#
#                            #Mise A Jour des Variables
#                            bestVoisinTemp.valueObj1 += tempValueObj
#                            deleteat!(bestVoisinTemp.setSelectedLevel1,findall(x -> x==i,bestVoisinTemp.setSelectedLevel1))
#                            push!(bestVoisinTemp.setSelectedLevel1,j)
#                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
#                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
#                                    bestVoisinTemp.linksTerminalLevel1[k] = j
#                                end
#                            end
#                            bestVoisinTemp.valueObj2 = calculObj2(bestVoisinTemp.setSelectedLevel1,bestVoisinTemp.setSelectedLevel2,distancesConcentrators)
                        end

                    else # f = 2 pour objectif 2
                        tempSetSelectedLevel1 = copy(voisinTempSolution.setSelectedLevel1)
                        deleteat!(tempSetSelectedLevel1,findall(x -> x==i,tempSetSelectedLevel1))
                        push!(tempSetSelectedLevel1,j)
                        tempValueObj = calculObj2(tempSetSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                        if (voisinTempSolution.valueObj2 < tempValueObj)
                            boolAmelioration = true
                            push!(listeTabou, i)
                            voisinTempSolution.ValueObj1 += differenceObjectif1(i,j,voisinTempSolution.linksTerminalLevel1,linkCosts,costOpeningLevel1)
                            voisinTempSolution.ValueObj2 = tempValueObj
                            voisinTempSolution.setSelectedLevel1 = tempSetSelectedLevel1
                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                                if (voisinTempSolution.linksTerminalLevel1[k] == i)
                                    voisinTempSolution.linksTerminalLevel1[k] = j
                                end
                            end

#                        elseif (tempValueObj > bestVoisinTemp.valueObj2)
#                            bestVoisinTemp.ValueObj1 += differenceObjectif1(i,j,voisinTempSolution.linksTerminalLevel1,linkCosts,costOpeningLevel1)
#                            bestVoisinTemp.ValueObj2 = tempValueObj
#                            bestVoisinTemp.setSelectedLevel1 = tempSetSelectedLevel1
#                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
#                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
#                                    bestVoisinTemp.linksTerminalLevel1[k] = j
#                                end
#                            end
                        end
                    end
                end
                j +=1
            end
        end
        ##########################################################################################################

        ############################### Swap pour les Concentrateurs de niveau 2##################################
        i=1
        while(i <= length(voisinTempSolution.setSelectedLevel2) && !boolAmelioration)
            j = 1
            while(j <= length(costOpeningLevel2) && !boolAmelioration)
                if (!(j in voisinTempSolution.setSelectedLevel2) && !(j in listeTabou)) #Possible amélioration avec tri et Dichotomie
                    if (f == 1) # f = 1 pour objectif 1
                        tempValueObj = differenceObjectif1Level2(i,j,voisinTempSolution.linksLevel1Level2,linkConcentratorsCosts,costOpeningLevel2) #différence entre les solutions
                        if (tempObj<0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                            #Mise A Jour des Variables
                            boolAmelioration = true
                            push!(listeTabou, i)
                            voisinTempSolution.valueObj1 += tempValueObj
                            deleteat!(voisinTempSolution.setSelectedLevel2,findall(x -> x==i,voisinTempSolution.setSelectedLevel1))
                            push!(voisinTempSolution.setSelectedLevel2,j)
                            for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                                if (voisinTempSolution.linksLevel1Level2[k] == i)
                                    voisinTempSolution.linksLevel1Level2[k] = j
                                end
                            end
                            voisinTempSolution.ValueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)


#                        elseif ((voisinTempSolution.valueObj1 + tempValueObj) < bestVoisinTemp.valueObj1) #Si le swap à permis une amélioration par rapport à bestVoisinTemp
#
#                            #Mise A Jour des Variables
#                            bestVoisinTemp.valueObj1 += tempValueObj
#                            deleteat!(bestVoisinTemp.setSelectedLevel2,findall(x -> x==i,bestVoisinTemp.setSelectedLevel2))
#                            push!(bestVoisinTemp.setSelectedLevel2,j)
#                            for k in 1:length(bestVoisinTemp.linksLevel1Level2)  # Mise à jour des affectations
#                                if (bestVoisinTemp.linksLevel1Level2[k] == i)
#                                    bestVoisinTemp.linksLevel1Level2[k] = j
#                                end
#                            end
#                            bestVoisinTemp.valueObj2 = calculObj2(bestVoisinTemp.setSelectedLevel1,bestVoisinTemp.setSelectedLevel2,distancesConcentrators)
                        end

                    else # f = 2 pour objectif 2
                        tempSetSelectedLevel2 = copy(voisinTempSolution.setSelectedLevel2)
                        deleteat!(tempSetSelectedLevel2,findall(x -> x==i,tempSetSelectedLevel2))
                        push!(tempSetSelectedLevel2,j)
                        tempValueObj = calculObj2(voisinTempSolution.setSelectedLevel1,tempSetSelectedLevel2,distancesConcentrators)
                        if (voisinTempSolution.valueObj2 < tempValueObj)
                            boolAmelioration = true
                            push!(listeTabou, i)
                            voisinTempSolution.ValueObj1 += differenceObjectif1Level2(i,j,voisinTempSolution.linksLevel1Level2,linkConcentratorsCosts,costOpeningLevel2)
                            voisinTempSolution.ValueObj2 = tempValueObj
                            voisinTempSolution.setSelectedLevel2 = tempSetSelectedLevel2
                            for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                                if (voisinTempSolution.linksLevel1Level2[k] == i)
                                    voisinTempSolution.linksLevel1Level2[k] = j
                                end
                            end

#                        elseif (tempValueObj > bestVoisinTemp.valueObj2)
#                            bestVoisinTemp.ValueObj1 += differenceObjectif1Level2(i,j,voisinTempSolution.linksLevel1Level2,costOpeningLevel2)
#                            bestVoisinTemp.ValueObj2 = tempValueObj
#                            bestVoisinTemp.setSelectedLevel2 = tempSetSelectedLevel2
#                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
#                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
#                                    bestVoisinTemp.linksTerminalLevel1[k] = j
#                                end
#                            end
                        end
                    end
                end
                j +=1
            end
        end

           ##########################Critère d'aspiration###################################

        if !boolAmelioration
            #bestVoisinTemp permet de sauvegarder le meilleur swap local, ce voisin est choisi lorsque aucun swap améliore la solution
            bestVoisinTemp = copy(voisinTempSolution)
            bestVoisinTemp.valueObj1=Inf()
            bestVoisinTemp.valueObj1=-Inf()
            i=1

            while(i <= length(length(listeTabu)) && !boolAmelioration)
                if(listeTabu[i] in setSelectedLevel1)
                    setSelectedLevel = voisinTempSolution.setSelectedLevel1
                    bestTempSetSelectedLevel = bestVoisinTemp.setSelectedLevel1
                    costOpening = costOpeningLevel1
                    links = voisinTempSolution.linksTerminalLevel1
                    bestTempLinks = bestVoisinTemp.linksTerminalLevel1
                else
                    setSelectedLevel = voisinTempSolution.setSelectedLevel2
                    bestTempSetSelectedLevel = bestVoisinTemp.setSelectedLevel2
                    costOpening = costOpeningLevel2
                    links = voisinTempSolution.linksLevel1Level2
                    bestTempLinks = bestVoisinTemp.linksLevel1Level2
                end
                j = 1
                while(j <= length(costOpening) && !boolAmelioration)
                    if ((j in setSelectedLevel) && !(j in listeTabou)) #Possible amélioration avec tri et Dichotomie
                        if (f == 1) # f = 1 pour objectif 1
                            if(listeTabu[i] in setSelectedLevel1)
                                tempValueObj = differenceObjectif1(i,j,links,linkCosts,costOpening) #différence entre les solutions
                            else
                                tempValueObj = differenceObjectif1Level2(i,j,links,linkConcentratorsCosts,costOpening) #différence entre les solutions
                            end
                            if (tempObj < bestVoisin.valueObj1) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                                #Mise A Jour des Variables
                                boolAmelioration = true
                                deleteat!(listeTabou,findfirst(x->x==i,listeTabou))
                                voisinTempSolution.valueObj1 += tempValueObj
                                deleteat!(setSelectedLevel,findall(x -> x==i,setSelectedLevel))
                                push!(setSelectedLevel,j)
                                for k in 1:length(links)  # Mise à jour des affectations
                                    if (links[k] == i)
                                        links[k] = j
                                    end
                                end
                                voisinTempSolution.ValueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)


                            elseif ((voisinTempSolution.valueObj1 + tempValueObj) < bestVoisinTemp.valueObj1) #Si le swap à permis une amélioration par rapport à bestVoisinTemp

                                #Mise A Jour des Variables
                                bestVoisinTemp.valueObj1 += tempValueObj
                                deleteat!(bestTempSetSelectedLevel,findfirst(x -> x==i,bestTempSetSelectedLevel))
                                push!(bestTempSetSelectedLevel,j)
                                for k in 1:length(bestTempLinks)  # Mise à jour des affectations
                                    if (bestTempLinks == i)
                                        bestTempLinks = j
                                    end
                                end
                                bestVoisinTemp.valueObj2 = calculObj2(bestVoisinTemp.setSelectedLevel1,bestVoisinTemp.setSelectedLevel2,distancesConcentrators)
                            end

                        else # f = 2 pour objectif 2
                            tempSetSelectedLevel = copy(setSelectedLevel)
                            deleteat!(tempSetSelectedLevel,findall(x -> x==i,tempSetSelectedLevel))
                            push!(tempSetSelectedLevel,j)
                            tempValueObj = calculObj2(voisinTempSolution.setSelectedLevel1,tempSetSelectedLevel2,distancesConcentrators)
                            if (voisinTempSolution.valueObj2 < tempValueObj)
                                boolAmelioration = true
                                deleteat!(listeTabou,findfirst(x->x==i,listeTabou))
                                if(listeTabu[i] in setSelectedLevel1)
                                    tempValueObj1 = differenceObjectif1(i,j,links,linkCosts,costOpening) #différence entre les solutions
                                else
                                    tempValueObj1 = differenceObjectif1Level2(i,j,links,linkConcentratorsCosts,costOpening) #différence entre les solutions
                                end
                                voisinTempSolution.ValueObj1 += tempValueObj1
                                voisinTempSolution.ValueObj2 = tempValueObj
                                setSelectedLevel = tempSetSelectedLevel
                                for k in 1:length(links)  # Mise à jour des affectations
                                    if (links[k] == i)
                                        links[k] = j
                                    end
                                end

                            elseif (tempValueObj > bestVoisinTemp.valueObj2)

                                if(listeTabu[i] in setSelectedLevel1)
                                    tempValueObj1 = differenceObjectif1(i,j,links,linkCosts,costOpening) #différence entre les solutions
                                else
                                    tempValueObj1 = differenceObjectif1Level2(i,j,links,linkConcentratorsCosts,costOpening) #différence entre les solutions
                                end

                                bestVoisinTemp.ValueObj1 += tempValueObj1
                                bestVoisinTemp.ValueObj2 = tempValueObj
                                bestTempSetSelectedLevel = tempSetSelectedLevel
                                for k in 1:length(bestTempLinks)  # Mise à jour des affectations
                                    if (bestTempLinks == i)
                                        bestTempLinks = j
                                    end
                                end
                            end
                        end
                    end
                    j +=1
                end
            end
        end


        # Si il y a une amélioration de la solution courante on regarde si cette solution est meilleur que la meilleur solution trouver jusqu'a maintenant
        if boolAmelioration
            if f == 1
                if(voisinTempSolution.valueObj1 < bestVoisin.valueObj1)
                    bestVoisin = copy(voisinTempSolution)
                end
                k = 0
            else
                if(voisinTempSolution.valueObj2 > bestVoisin.valueObj2)
                    bestVoisin = copy(voisinTempSolution)
                end
                k = 0
            end

        else # cas ou aucune solution améliorante est trouvé
            voisinTempSolution = copy(bestVoisinTemp)
            k+=1
        end
    end
end

function differenceObjectif1(i,j,affectationLevel1,affectationLevel2,linkCostsTerminal,linkCostsConcentrator,openingCost)
    valeur = openingCost[j] - openingCost[i]
    listeAffectationLevel1 = findall(x -> x==i,affectationLevel1)
    for a in listeAffecation
        valeur += linkCostsTerminal[j,a] - linkCostsTerminal[i,a]
    end
    indAffectationLevel2 = [affectationLevel2[i]]
    for a in listeAffecation
        valeur += linkCostsConcentrator[j,indAffectationLevel2] - linkCostsConcentrator[i,indAffectationLevel2]
    end
    return valeur
end

function differenceObjectif1Level2(i,j,affectation,linkCosts,openingCost)
    valeur = openingCost[j] - openingCost[i]
    listeAffectation = findall(x -> x==i,affectation)
    for a in listeAffecation
        valeur += linkCosts[a,j] - linkCosts[a,i]
    end
    return valeur
end


function calculObj2(setSelectedLevel1,setSelectedLevel2,distancesConcentrators::Matrix{Float32})

    allConcentrators = vcat(setSelectedLevel1, setSelectedLevel2)
    nbConcentrators = length(allConcentrators)
    for i in 1:nbConcentrators
        min = Inf
        for j in 1:(i-1)
            dist = distancesConcentrators[allConcentrators[1],allConcentrators[2]]
            if dist < min
                min = dist
            end
        end
        for j in (i+1):nbConcentrators
            dist = distancesConcentrators[allConcentrators[1],allConcentrators[2]]
            if dist < min
                min = dist
            end
        end
        valueObj2 += min
    end

    return valueObj2
end




linkCosts = Float32[55.67826 71.51636 71.47873 25.356148 92.56394 84.08742 70.355705 81.14982 84.52917 45.02583 118.64744 95.2246 39.518963 97.81885 32.461338 29.066725 60.576553 54.1026 99.94057 83.55967; 21.845207 34.98082 24.587273 53.937286 18.002775 51.62166 27.010826 7.1050444 16.187544 55.367527 43.243954 19.951218 43.294807 40.57621 56.689056 46.440624 15.055889 21.914392 24.797445 18.608528; 40.39705 5.835802 53.428715 49.668575 33.641468 20.851921 5.771271 28.527946 46.644882 37.901314 59.91465 42.52695 57.558308 22.880806 69.381325 49.067146 29.290394 37.28265 46.669685 49.4152; 61.695423 21.013346 74.140396 65.34291 47.52717 8.067118 26.951843 46.45624 65.167 47.539448 68.99132 57.282356 78.125465 19.827524 89.334694 67.38302 50.598087 58.518314 60.43311 68.34805; 19.394474 25.910826 30.51875 44.67695 25.158499 43.681416 18.015678 14.097728 26.774422 44.445015 52.397057 29.8143 39.798344 38.26009 52.913307 38.646782 8.482959 17.463058 34.70027 28.68901; 46.34897 68.21749 60.81627 23.63934 84.76561 82.65598 65.80569 73.29639 74.84249 46.23179 109.9555 86.538574 28.432182 93.36242 20.72885 22.1898 52.702168 45.333668 91.1289 73.580894; 66.0438 25.5965 81.7871 59.015987 61.737003 10.852447 33.569904 58.05286 76.24693 37.59204 85.46825 71.181244 78.510796 37.427322 87.89337 64.117714 56.060844 62.32689 74.91004 78.96919; 35.77797 76.04548 20.787273 66.76548 58.27254 94.21284 68.4566 51.44652 36.345146 81.85571 69.89193 52.35111 36.68271 85.911674 43.25728 54.89566 45.13879 39.72845 54.412094 32.663; 36.363434 33.25715 56.146545 13.610057 61.466297 45.779114 33.413963 51.074993 61.51504 12.288326 89.192856 66.93514 37.779236 60.131794 44.06456 19.76224 33.59544 32.688084 71.818825 62.19056; 51.915966 19.64762 61.155453 65.0567 31.129448 21.930122 20.297506 31.546614 50.05957 52.162186 52.76914 40.910866 70.96669 7.536587 83.36132 64.10235 40.641094 49.423138 43.902058 53.459938]
linkConcentratorsCosts = Float32[0.0 75.46801 74.98314 90.39114 67.60152 11.744454 82.55212 75.060936 38.57145 90.36625; 75.46801 0.0 30.889326 50.485138 10.972422 67.1624 60.386707 45.37073 47.57856 36.677547; 74.98314 30.889326 0.0 21.31018 22.94696 70.91073 29.60655 73.62956 37.3012 15.388252; 90.39114 50.485138 21.31018 0.0 43.9452 88.227104 17.917376 94.60151 51.846706 16.595814; 67.60152 10.972422 22.94696 43.9452 0.0 60.35769 51.494392 50.703342 37.12261 32.703075; 11.744454 67.1624 70.91073 88.227104 60.35769 0.0 82.6502 63.410484 37.10929 86.09539; 82.55212 60.386707 29.60655 17.917376 51.494392 82.6502 0.0 101.19753 45.61901 32.77711; 75.060936 45.37073 73.62956 94.60151 50.703342 63.410484 101.19753 0.0 69.983444 81.925606; 38.57145 47.57856 37.3012 51.846706 37.12261 37.10929 45.61901 69.983444 0.0 52.600933; 90.36625 36.677547 15.388252 16.595814 32.703075 86.09539 32.77711 81.925606 52.600933 0.0]
potentials = Float32[1392.6587, 641.218, 786.65607, 1082.7428, 633.839, 1250.573, 1207.3602, 1104.8982, 365.13226, 392.52902]
distancesConcentrators = Float32[0.0 75.46801 74.98314 90.39114 67.60152 11.744454 82.55212 75.060936 38.57145 90.36625; 75.46801 0.0 30.889326 50.485138 10.972422 67.1624 60.386707 45.37073 47.57856 36.677547; 74.98314 30.889326 0.0 21.31018 22.94696 70.91073 29.60655 73.62956 37.3012 15.388252; 90.39114 50.485138 21.31018 0.0 43.9452 88.227104 17.917376 94.60151 51.846706 16.595814; 67.60152 10.972422 22.94696 43.9452 0.0 60.35769 51.494392 50.703342 37.12261 32.703075; 11.744454 67.1624 70.91073 88.227104 60.35769 0.0 82.6502 63.410484 37.10929 86.09539; 82.55212 60.386707 29.60655 17.917376 51.494392 82.6502 0.0 101.19753 45.61901 32.77711; 75.060936 45.37073 73.62956 94.60151 50.703342 63.410484 101.19753 0.0 69.983444 81.925606; 38.57145 47.57856 37.3012 51.846706 37.12261 37.10929 45.61901 69.983444 0.0 52.600933; 90.36625 36.677547 15.388252 16.595814 32.703075 86.09539 32.77711 81.925606 52.600933 0.0]
selectedLevel1 = [5, 2, 3]
links = [5, 3, 2, 5, 5, 3, 3, 5, 2, 3, 2, 3, 2, 3, 2, 5, 5, 2, 2, 5]
selectedLevel2 = Any[9]
linksLevel1Level2 = [9, 9, 9]
valueObj1 = 667.6313
valueObj2 = 43.889687

sol = solution(selectedLevel1,links,selectedLevel2,linksLevel1Level2,valueObj1,valueObj2)

#TabuSearch(1,sol::solution ,costOpeningLevel1::Vector{Float64}, costOpeningLevel2::Vector{Float64}, distancesConcentrators::Matrix{Float32},linkConcentratorsCosts::Matrix{Float32},linkCosts::Matrix{Float32})



#function swap(bestVoisinTemp, voisinTempSolution, costOpeningLevel1, listeTabou)
#
#    boolAmelioration = false
#    i=1
#        while i <= length(voisinTempSolution.setSelectedLevel1) && !boolAmelioration
#            j = 1
#            while j <= length(costOpeningLevel1) && !boolAmelioration
#                if !(j in voisinTempSolution.setSelectedLevel1 && j in listeTabou) #Possible amélioration avec tri et Dichotomie
#                    if (f == 1) # f = 1 pour objectif 1
#                        tempValueObj = differenceObjectif(voisinTempSolution,i,j,costOpeningLevel1)
#                        if (tempObj>0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
#
#                            #Mise A Jour des Variables
#                            boolAmelioration = true
#                            voisinTempSolution.ValueObj1 += tempValueObj
#                            voisinTempSolution.ValueObj2 += differenceObjectif(f,voisinTempSolution,i,j,costOpeningLevel1)
#                            deleteat!(voisinTempSolution.setSelectedLevel1,findall(x -> x==i,setSelectedLevel1))
#                            push!(voisinTempSolution.setSelectedLevel1,j)
#                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
#                                if (voisinTempSolution.linksTerminalLevel1[k] == i)
#                                    voisinTempSolution.linksTerminalLevel1[k] = j
#                                end
#                            end
#
#                        elseif ((voisinTempSolution.valueObj1 + tempValueObj)>bestVoisinTemp.valueObj1) #Si le swap à permis une amélioration par rapport à bestVoisinTemp
#
#                            #Mise A Jour des Variables
#                            bestVoisinTemp.ValueObj1 += tempValueObj
#                            bestVoisinTemp.ValueObj2 += differenceObjectif(2,voisinTempSolution,i,j,costOpeningLevel1)
#                            deleteat!(bestVoisinTemp.setSelectedLevel1,findall(x -> x==i,setSelectedLevel1))
#                            push!(bestVoisinTemp.setSelectedLevel1,j)
#                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
#                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
#                                    bestVoisinTemp.linksTerminalLevel1[k] = j
#                                end
#                            end
#                        end
#
#
#                    else # f = 2 pour objectif 2
#                         tempValueObj = differenceObjectif(f,voisinTempSolution,i,j,costOpeningLevel1)
#                        if (tempObj>0)
#                            boolAmelioration = true
#                            voisinTempSolution.ValueObj1 += differenceObjectif(voisinTempSolution,i,j,costOpeningLevel1)
#                            voisinTempSolution.ValueObj2 += tempValueObj
#                            deleteat!(voisinTempSolution.setSelectedLevel1,findall(x -> x==i,setSelectedLevel1))
#                            push!(voisinTempSolution.setSelectedLevel1,j)
#                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
#                                if (voisinTempSolution.linksTerminalLevel1[k] == i)
#                                    voisinTempSolution.linksTerminalLevel1[k] = j
#                                end
#                            end
#                        elseif ((voisinTempSolution.valueObj2 + tempValueObj)>bestVoisinTemp.valueObj2)
#                            bestVoisinTemp.ValueObj1 += differenceObjectif(1,voisinTempSolution,i,j,costOpeningLevel1)
#                            bestVoisinTemp.ValueObj2 += tempValueObj
#                            deleteat!(bestVoisinTemp.setSelectedLevel1,findall(x -> x==i,setSelectedLevel1))
#                            push!(bestVoisinTemp.setSelectedLevel1,j)
#                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
#                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
#                                    bestVoisinTemp.linksTerminalLevel1[k] = j
#                                end
#                            end
#                        end
#
#                    end
#                end
#                j +=1
#            end
#        end
#end

