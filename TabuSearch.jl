#=
TabuSearch:
- Julia version:
- Author: mathey
- Date: 2022-12-03
=#
using DataStructures.jl


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
    listeTabou = Stack{Int}()
    k = 0

    bestVoisin = copy(sol) #meilleur voisin trouvé
    voisinTempSolution = copy(sol) #voisin local

    while k < 10
        boolAmelioration = false #booleen vrai si le voisin améliore la solution faux sinon

        # Création du voisinage

        #bestVoisinTemp permet de sauvegarder le meilleur swap local, ce voisin est choisi lorsque aucun swap améliore la solution
        bestVoisinTemp = copy(voisinTempSolution)
        bestVoisinTemp.valueObj1=Inf()
        bestVoisinTemp.valueObj1=-Inf()

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
                            voisinTempSolution.valueObj1 += tempValueObj
                            deleteat!(voisinTempSolution.setSelectedLevel1,findall(x -> x==i,voisinTempSolution.setSelectedLevel1))
                            push!(voisinTempSolution.setSelectedLevel1,j)
                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                                if (voisinTempSolution.linksTerminalLevel1[k] == i)
                                    voisinTempSolution.linksTerminalLevel1[k] = j
                                end
                            end
                            voisinTempSolution.ValueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)


                        elseif ((voisinTempSolution.valueObj1 + tempValueObj) < bestVoisinTemp.valueObj1) #Si le swap à permis une amélioration par rapport à bestVoisinTemp

                            #Mise A Jour des Variables
                            bestVoisinTemp.valueObj1 += tempValueObj
                            deleteat!(bestVoisinTemp.setSelectedLevel1,findall(x -> x==i,bestVoisinTemp.setSelectedLevel1))
                            push!(bestVoisinTemp.setSelectedLevel1,j)
                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
                                    bestVoisinTemp.linksTerminalLevel1[k] = j
                                end
                            end
                            bestVoisinTemp.valueObj2 = calculObj2(bestVoisinTemp.setSelectedLevel1,bestVoisinTemp.setSelectedLevel2,distancesConcentrators)
                        end

                    else # f = 2 pour objectif 2
                        tempSetSelectedLevel1 = copy(voisinTempSolution.setSelectedLevel1)
                        deleteat!(tempSetSelectedLevel1,findall(x -> x==i,tempSetSelectedLevel1))
                        push!(tempSetSelectedLevel1,j)
                        tempValueObj = calculObj2(tempSetSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                        if (voisinTempSolution.valueObj2 < tempValueObj)
                            boolAmelioration = true
                            voisinTempSolution.ValueObj1 += differenceObjectif1(i,j,voisinTempSolution.linksTerminalLevel1,linkCosts,costOpeningLevel1)
                            voisinTempSolution.ValueObj2 = tempValueObj
                            voisinTempSolution.setSelectedLevel1 = tempSetSelectedLevel1
                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                                if (voisinTempSolution.linksTerminalLevel1[k] == i)
                                    voisinTempSolution.linksTerminalLevel1[k] = j
                                end
                            end

                        elseif (tempValueObj > bestVoisinTemp.valueObj2)
                            bestVoisinTemp.ValueObj1 += differenceObjectif1(i,j,voisinTempSolution.linksTerminalLevel1,linkCosts,costOpeningLevel1)
                            bestVoisinTemp.ValueObj2 = tempValueObj
                            bestVoisinTemp.setSelectedLevel1 = tempSetSelectedLevel1
                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
                                    bestVoisinTemp.linksTerminalLevel1[k] = j
                                end
                            end
                        end
                    end
                end
                j +=1
            end
        end
        ##########################################################################################################

        ############################### Swap pour les Concentrateurs de niveau 2##################################
        i=1
        while (i <= length(voisinTempSolution.setSelectedLevel2) && !boolAmelioration)
            j = 1
            while (j <= length(costOpeningLevel2) && !boolAmelioration)
                if (!(j in voisinTempSolution.setSelectedLevel2) && !(j in listeTabou)) #Possible amélioration avec tri et Dichotomie
                    if (f == 1) # f = 1 pour objectif 1
                        tempValueObj = differenceObjectif1Level2(i,j,voisinTempSolution.linksLevel1Level2,costOpeningLevel2) #différence entre les solutions
                        if (tempObj<0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                            #Mise A Jour des Variables
                            boolAmelioration = true
                            voisinTempSolution.valueObj1 += tempValueObj
                            deleteat!(voisinTempSolution.setSelectedLevel2,findall(x -> x==i,voisinTempSolution.setSelectedLevel1))
                            push!(voisinTempSolution.setSelectedLevel2,j)
                            for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                                if (voisinTempSolution.linksLevel1Level2[k] == i)
                                    voisinTempSolution.linksLevel1Level2[k] = j
                                end
                            end
                            voisinTempSolution.ValueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)


                        elseif ((voisinTempSolution.valueObj1 + tempValueObj) < bestVoisinTemp.valueObj1) #Si le swap à permis une amélioration par rapport à bestVoisinTemp

                            #Mise A Jour des Variables
                            bestVoisinTemp.valueObj1 += tempValueObj
                            deleteat!(bestVoisinTemp.setSelectedLevel2,findall(x -> x==i,bestVoisinTemp.setSelectedLevel2))
                            push!(bestVoisinTemp.setSelectedLevel2,j)
                            for k in 1:length(bestVoisinTemp.linksLevel1Level2)  # Mise à jour des affectations
                                if (bestVoisinTemp.linksLevel1Level2[k] == i)
                                    bestVoisinTemp.linksLevel1Level2[k] = j
                                end
                            end
                            bestVoisinTemp.valueObj2 = calculObj2(bestVoisinTemp.setSelectedLevel1,bestVoisinTemp.setSelectedLevel2,distancesConcentrators)
                        end

                    else # f = 2 pour objectif 2
                        tempSetSelectedLevel2 = copy(voisinTempSolution.setSelectedLevel2)
                        deleteat!(tempSetSelectedLevel2,findall(x -> x==i,tempSetSelectedLevel2))
                        push!(tempSetSelectedLevel2,j)
                        tempValueObj = calculObj2(voisinTempSolution.setSelectedLevel1,tempSetSelectedLevel2,distancesConcentrators)
                        if (voisinTempSolution.valueObj2 < tempValueObj)
                            boolAmelioration = true
                            voisinTempSolution.ValueObj1 += differenceObjectif1Level2(i,j,voisinTempSolution.linksLevel1Level2,costOpeningLevel2)
                            voisinTempSolution.ValueObj2 = tempValueObj
                            voisinTempSolution.setSelectedLevel2 = tempSetSelectedLevel2
                            for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                                if (voisinTempSolution.linksLevel1Level2[k] == i)
                                    voisinTempSolution.linksLevel1Level2[k] = j
                                end
                            end

                        elseif (tempValueObj > bestVoisinTemp.valueObj2)
                            bestVoisinTemp.ValueObj1 += differenceObjectif1Level2(i,j,voisinTempSolution.linksLevel1Level2,costOpeningLevel2)
                            bestVoisinTemp.ValueObj2 = tempValueObj
                            bestVoisinTemp.setSelectedLevel2 = tempSetSelectedLevel2
                            for k in 1:length(bestVoisinTemp.linksTerminalLevel1)  # Mise à jour des affectations
                                if (bestVoisinTemp.linksTerminalLevel1[k] == i)
                                    bestVoisinTemp.linksTerminalLevel1[k] = j
                                end
                            end
                        end
                    end
                end
                j +=1
            end
        end

           ##########################Critère d'aspiration###################################

        if !boolAmelioration
                i=1
                while i <= length(length(listeTabu)) && !boolAmelioration

                    j = 1
                    while j <= length(costOpeningLevel1) && !boolAmelioration
                        end

                end
        end

        # Si il y a une amélioration de la solution courante on regarde si cette solution est meilleur que la meilleur solution trouver jusqu'a maintenant
        if boolAmelioration
            if f == 1
                if(tempSolution.valueObj1 > bestVoisin.valueObj1)
                    bestVoisin = tempSolution
                    k = -1
                end
            else
                if(tempSolution.valueObj2 > bestVoisin.valueObj2)
                    bestVoisin = tempSolution
                    k = -1
                end
            end
        end







        bestneighboorObj = 1
        for i in 2:lenght(voisinTempValueObj)
            if voisinTempValueObj[bestneighboorObj] < voisinTempValueObj[i]
               bestneighboorObj = i
            end
        end

        if voisinTempValueObj[bestneighboorObj] > tempValueObj
            tempSetSelectedLevel1   = voisinTempSetSelectedLevel1[bestneighboorObj]
            tempLinksTerminalLevel1 = voisinTempLinksTerminalLevel1[bestneighboorObj]
            tempSetSelectedLevel2   = voisinTempSetSelectedLevel2[bestneighboorObj]
            tempLinksLevel1Level2   = voisinTempLinksLevel1Level2[bestneighboorObj]
            tempValueObj            = voisinTempValueObj[bestneighboorObj]

        else
            k = 10
        end
    end
end

function differenceObjectif1(i,j,affectation,linkCosts,openingCost)
    valeur = openingCost[j] - openingCost[i]
    listeAffectation = findall(x -> x==i,affectation)
    for a in listeAffecation
        valeur += linkCosts[j,a] - linkCosts[i,a]
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

