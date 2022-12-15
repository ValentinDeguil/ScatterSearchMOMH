#=
TabuSearch:
- Julia version:
- Author: mathey
- Date: 2022-12-03
=#
#using DataStructures
include("Tools.jl")

function TabuSearch(f::Int64,sol::solution, distancesConcentrators::Matrix{Float32},linkConcentratorsCosts::Matrix{Float32},linkCosts::Matrix{Float32},numberLevel1::Int64, numberLevel2::Int64)

    nbrIteration::Int32 = 5
    listeTabou::Vector{Int64} = []
    iter::Int32 = 0

    bestVoisin::solution = deepcopy(sol) #meilleur voisin trouvé
    voisinTempSolution::solution = deepcopy(sol) #voisin local

    while iter < nbrIteration
        boolAmelioration::Bool = false #booleen vrai si le voisin améliore la solution faux sinon

        tabVoisinNonSelectionneLvl1::Vector{Int64} = [i for i in 1:numberLevel1]
        tabVoisinNonSelectionneLvl2::Vector{Int64} = [i for i in numberLevel1+1:numberLevel1+numberLevel2]
        tabVoisinNonSelectionneLvl1 = setdiff(tabVoisinNonSelectionneLvl1,voisinTempSolution.setSelectedLevel1)
        tabVoisinNonSelectionneLvl2 = setdiff(tabVoisinNonSelectionneLvl2,voisinTempSolution.setSelectedLevel2)
        tabVoisinNonSelectionneLvl1 = setdiff(tabVoisinNonSelectionneLvl1,listeTabou)
        tabVoisinNonSelectionneLvl2 = setdiff(tabVoisinNonSelectionneLvl2,listeTabou)


        ############################### Swap pour les Concentrateurs de niveau 1##################################
        i=1
        while (i <= length(voisinTempSolution.setSelectedLevel1) && !boolAmelioration)
            j = 1
            while (j <= length(tabVoisinNonSelectionneLvl1) && !boolAmelioration)
                if (f == 1) # f = 1 pour objectif 1
                    tempValueObj::Float64 = differenceObjectif1(voisinTempSolution.setSelectedLevel1[i],tabVoisinNonSelectionneLvl1[j],i,voisinTempSolution.linksTerminalLevel1,voisinTempSolution.linksLevel1Level2,linkCosts,linkConcentratorsCosts) #différence entre les solutions
                    if (tempValueObj<0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                        #Mise A Jour des Variables
                        boolAmelioration = true
                        push!(listeTabou, voisinTempSolution.setSelectedLevel1[i])
                        voisinTempSolution.valueObj1 += tempValueObj
                        for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                            if (voisinTempSolution.linksTerminalLevel1[k] == voisinTempSolution.setSelectedLevel1[i])
                                voisinTempSolution.linksTerminalLevel1[k] = tabVoisinNonSelectionneLvl1[j]
                            end
                        end
                        voisinTempSolution.setSelectedLevel1[findfirst(x -> x==voisinTempSolution.setSelectedLevel1[i],voisinTempSolution.setSelectedLevel1)] = tabVoisinNonSelectionneLvl1[j]
                        voisinTempSolution.valueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                    end
                else # f = 2 pour objectif 2
                    tempSetSelectedLevel1 = copy(voisinTempSolution.setSelectedLevel1)
                    tempSetSelectedLevel1[findfirst(x -> x==voisinTempSolution.setSelectedLevel1[i],voisinTempSolution.setSelectedLevel1)] = tabVoisinNonSelectionneLvl1[j]
                    tempValueObj = calculObj2(tempSetSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                    if (voisinTempSolution.valueObj2 < tempValueObj)
                        boolAmelioration = true
                        push!(listeTabou, voisinTempSolution.setSelectedLevel1[i])
                        voisinTempSolution.valueObj1 += differenceObjectif1(voisinTempSolution.setSelectedLevel1[i],tabVoisinNonSelectionneLvl1[j],i,voisinTempSolution.linksTerminalLevel1,voisinTempSolution.linksLevel1Level2,linkCosts,linkConcentratorsCosts)
                        voisinTempSolution.valueObj2 = tempValueObj
                        for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                            if(voisinTempSolution.linksTerminalLevel1[k] == voisinTempSolution.setSelectedLevel1[i])
                                voisinTempSolution.linksTerminalLevel1[k] = tabVoisinNonSelectionneLvl1[j]
                            end
                        end
                        voisinTempSolution.setSelectedLevel1 = tempSetSelectedLevel1
                    end
                end
                j+=1
            end
            i+=1
        end
        ##########################################################################################################

        ############################### Swap pour les Concentrateurs de niveau 2##################################
        i=1
        while(i <= length(voisinTempSolution.setSelectedLevel2) && !boolAmelioration)
            j = 1
            while(j <= length(tabVoisinNonSelectionneLvl2) && !boolAmelioration)
                if (f == 1) # f = 1 pour objectif 1
                    tempValueObj = differenceObjectif1Level2(voisinTempSolution.setSelectedLevel2[i],tabVoisinNonSelectionneLvl2[j],voisinTempSolution.linksLevel1Level2,linkConcentratorsCosts) #différence entre les solutions
                    if (tempValueObj<0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                        #Mise A Jour des Variables
                        boolAmelioration = true
                        push!(listeTabou, voisinTempSolution.setSelectedLevel2[i])
                        voisinTempSolution.valueObj1 += tempValueObj
                        for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                            if (voisinTempSolution.linksLevel1Level2[k] == voisinTempSolution.setSelectedLevel2[i])
                                voisinTempSolution.linksLevel1Level2[k] = tabVoisinNonSelectionneLvl2[j]
                            end
                        end
                        voisinTempSolution.setSelectedLevel2[findfirst(x -> x==voisinTempSolution.setSelectedLevel2[i],voisinTempSolution.setSelectedLevel2)] = tabVoisinNonSelectionneLvl2[j]
                        voisinTempSolution.valueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                    end
                else # f = 2 pour objectif 2
                    tempSetSelectedLevel2 = copy(voisinTempSolution.setSelectedLevel2)
                    tempSetSelectedLevel2[findfirst(x -> x==tempSetSelectedLevel2[i],tempSetSelectedLevel2)] = tabVoisinNonSelectionneLvl2[j]
                    tempValueObj = calculObj2(voisinTempSolution.setSelectedLevel1,tempSetSelectedLevel2,distancesConcentrators)
                    if (voisinTempSolution.valueObj2 < tempValueObj)
                        boolAmelioration = true
                        push!(listeTabou, i)
                        voisinTempSolution.valueObj1 += differenceObjectif1Level2(voisinTempSolution.setSelectedLevel2[i],tabVoisinNonSelectionneLvl2[j],voisinTempSolution.linksLevel1Level2,linkConcentratorsCosts)
                        voisinTempSolution.valueObj2 = tempValueObj
                        for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                            if (voisinTempSolution.linksLevel1Level2[k] == voisinTempSolution.setSelectedLevel2[i])
                                voisinTempSolution.linksLevel1Level2[k] = tabVoisinNonSelectionneLvl2[j]
                            end
                        end
                        voisinTempSolution.setSelectedLevel2 = tempSetSelectedLevel2
                    end
                end
                j +=1
            end
            i+=1
        end

        # Si il y a une amélioration de la solution courante on regarde si cette solution est meilleur que la meilleur solution trouver jusqu'a maintenant
        if boolAmelioration
            if f == 1
                if(voisinTempSolution.valueObj1 < bestVoisin.valueObj1)
                    bestVoisin = deepcopy(voisinTempSolution)
                end
                iter = -1
            else
                if(voisinTempSolution.valueObj2 > bestVoisin.valueObj2)
                    bestVoisin = deepcopy(voisinTempSolution)
                end
                iter = -1
            end
        else
            if(length(listeTabou)>0)
                deleteat!(listeTabou,1)
            end
        end

        if(length(listeTabou)>=7)
            deleteat!(listeTabou,1)
        end
        iter+=1
    end
    return bestVoisin
end

function differenceObjectif1(i,j,indiceAffectationLevel2,affectationLevel1,affectationLevel2,linkCostsTerminal,linkCostsConcentrator)
    valeur::Float64 = 0.0
    listeAffectationLevel1 = findall(x -> x==i,affectationLevel1)
    for a in listeAffectationLevel1
        valeur += linkCostsTerminal[j,a] - linkCostsTerminal[i,a]
    end
    indAffectationLevel2 = affectationLevel2[indiceAffectationLevel2]
    temp = (linkCostsConcentrator[j,indAffectationLevel2] - linkCostsConcentrator[i,indAffectationLevel2])
    valeur = valeur + temp
    return valeur
end

function differenceObjectif1Level2(i,j,affectation,linkCosts)
    valeur::Float64 = 0.0
    listeAffectation = findall(x -> x==i,affectation)
    for a in listeAffectation
        valeur += linkCosts[a,j] - linkCosts[a,i]
    end
    return valeur
end


function calculObj2(setSelectedLevel1,setSelectedLevel2,distancesConcentrators::Matrix{Float32})

    allConcentrators = vcat(setSelectedLevel1, setSelectedLevel2)
    nbConcentrators = length(allConcentrators)
    valueObj2::Float64 = 0
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

    return valueObj2
end








