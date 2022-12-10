#=
TabuSearch:
- Julia version:
- Author: mathey
- Date: 2022-12-03
=#
using DataStructures
include("Tools.jl")

function TabuSearch(f::Int64,sol::solution, distancesConcentrators::Matrix{Float32},linkConcentratorsCosts::Matrix{Float32},linkCosts::Matrix{Float32},numberLevel1::Int64, numberLevel2::Int64)

    nbrIteration::Int32 = 5
    listeTabou::Vector{Int64} = []
    iter::Int32 = 0

    bestVoisin::solution = deepcopy(sol) #meilleur voisin trouvé
    voisinTempSolution::solution = deepcopy(sol) #voisin local

    #println("bestVoisin.setSelectedLevel1 = ", bestVoisin.setSelectedLevel1)
    #println("bestVoisin.setSelectedLevel2 = ", bestVoisin.setSelectedLevel2)
    #println("bestVoisin.valueObj1 = ", bestVoisin.valueObj1)
    #println("bestVoisin.valueObj2 = ", bestVoisin.valueObj2)
    #println("bestVoisin.linksTerminalLevel1 = ", bestVoisin.linksTerminalLevel1)
    #println("bestVoisin.linksLevel1Level2 = ", bestVoisin.linksLevel1Level2)

    while iter < nbrIteration
        boolAmelioration::Bool = false #booleen vrai si le voisin améliore la solution faux sinon

        #println("bestVoisin.setSelectedLevel1 = ", bestVoisin.setSelectedLevel1)
        #println("bestVoisin.setSelectedLevel2 = ", bestVoisin.setSelectedLevel2)
        #println("bestVoisin.valueObj1 = ", bestVoisin.valueObj1)
        #println("bestVoisin.valueObj2 = ", bestVoisin.valueObj2)
        #println("bestVoisin.linksTerminalLevel1 = ", bestVoisin.linksTerminalLevel1)
        #println("bestVoisin.linksLevel1Level2 = ", bestVoisin.linksLevel1Level2)
        # Création du voisinage

        ############################### Swap pour les Concentrateurs de niveau 1##################################
        i=1
        while (i <= length(voisinTempSolution.setSelectedLevel1) && !boolAmelioration)
            j = 1
            while (j <= numberLevel1 && !boolAmelioration)
                if (!(j in voisinTempSolution.setSelectedLevel1) && !(j in listeTabou)) #Possible amélioration avec tri et Dichotomie
                    if (f == 1) # f = 1 pour objectif 1
                        #println("test1")
                        tempValueObj::Float64 = differenceObjectif1(voisinTempSolution.setSelectedLevel1[i],j,i,voisinTempSolution.linksTerminalLevel1,voisinTempSolution.linksLevel1Level2,linkCosts,linkConcentratorsCosts) #différence entre les solutions
                        if (tempValueObj<0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                            #Mise A Jour des Variables
                            #println("indice modif i = ",voisinTempSolution.setSelectedLevel1[i],"   j = ",j)
                            boolAmelioration = true
                            push!(listeTabou, voisinTempSolution.setSelectedLevel1[i])
                            voisinTempSolution.valueObj1 += tempValueObj
                            #println("voisinTempSolution.setSelectedLevel1 ",voisinTempSolution.setSelectedLevel1)
                            #println("findfirst ",findfirst(x -> x==voisinTempSolution.setSelectedLevel1[i],voisinTempSolution.setSelectedLevel1))
                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                                if (voisinTempSolution.linksTerminalLevel1[k] == voisinTempSolution.setSelectedLevel1[i])
                                    voisinTempSolution.linksTerminalLevel1[k] = j
                                end
                            end
                            voisinTempSolution.setSelectedLevel1[findfirst(x -> x==voisinTempSolution.setSelectedLevel1[i],voisinTempSolution.setSelectedLevel1)] = j
                            voisinTempSolution.valueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                        end

                    else # f = 2 pour objectif 2
                        #println("test1")
                        tempSetSelectedLevel1 = copy(voisinTempSolution.setSelectedLevel1)
                        tempSetSelectedLevel1[findfirst(x -> x==voisinTempSolution.setSelectedLevel1[i],voisinTempSolution.setSelectedLevel1)] = j
                        tempValueObj = calculObj2(tempSetSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                        if (voisinTempSolution.valueObj2 < tempValueObj)
                            #println("test11")
                            #println("indice modif i = ",voisinTempSolution.setSelectedLevel1[i],"   j = ",j)
                            boolAmelioration = true
                            push!(listeTabou, voisinTempSolution.setSelectedLevel1[i])
                            voisinTempSolution.valueObj1 += differenceObjectif1(voisinTempSolution.setSelectedLevel1[i],j,i,voisinTempSolution.linksTerminalLevel1,voisinTempSolution.linksLevel1Level2,linkCosts,linkConcentratorsCosts)
                            #println("test11")
                            voisinTempSolution.valueObj2 = tempValueObj

                            for k in 1:length(voisinTempSolution.linksTerminalLevel1)  # Mise à jour des affectations
                                #println("voisinTempSolution.linksTerminalLevel1[k] ", voisinTempSolution.linksTerminalLevel1[k] )
                                #println("voisinTempSolution.setSelectedLevel1[i] ",voisinTempSolution.setSelectedLevel1[i])
                                if(voisinTempSolution.linksTerminalLevel1[k] == voisinTempSolution.setSelectedLevel1[i])
                                    #println("jaj")
                                    voisinTempSolution.linksTerminalLevel1[k] = j
                                end
                            end
                            voisinTempSolution.setSelectedLevel1 = tempSetSelectedLevel1
                            #println("voisinTempSolution.linksTerminalLevel1",voisinTempSolution.linksTerminalLevel1)
                            #println("test11")
                        end
                    end
                end
                j +=1
            end
            i+=1
        end
        ##########################################################################################################

        ############################### Swap pour les Concentrateurs de niveau 2##################################
        i=1
        while(i <= length(voisinTempSolution.setSelectedLevel2) && !boolAmelioration)
            j = numberLevel1+1
            while(j <= numberLevel2+numberLevel1 && !boolAmelioration)
                if (!(j in voisinTempSolution.setSelectedLevel2) && !(j in listeTabou)) #Possible amélioration avec tri et Dichotomie
                    if (f == 1) # f = 1 pour objectif 1
                        #println("test2")
                        tempValueObj = differenceObjectif1Level2(voisinTempSolution.setSelectedLevel2[i],j,voisinTempSolution.linksLevel1Level2,linkConcentratorsCosts) #différence entre les solutions
                        if (tempValueObj<0) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                            #println("indice modif i = ",voisinTempSolution.setSelectedLevel2[i],"   j = ",j)
                            #Mise A Jour des Variables
                            boolAmelioration = true
                            push!(listeTabou, voisinTempSolution.setSelectedLevel2[i])
                            voisinTempSolution.valueObj1 += tempValueObj
                            for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                                if (voisinTempSolution.linksLevel1Level2[k] == voisinTempSolution.setSelectedLevel2[i])
                                    voisinTempSolution.linksLevel1Level2[k] = j
                                end
                            end
                            voisinTempSolution.setSelectedLevel2[findfirst(x -> x==voisinTempSolution.setSelectedLevel2[i],voisinTempSolution.setSelectedLevel2)] = j
                            voisinTempSolution.ValueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)
                        end

                    else # f = 2 pour objectif 2
                        #println("test2")
                        tempSetSelectedLevel2 = copy(voisinTempSolution.setSelectedLevel2)
                        tempSetSelectedLevel2[findfirst(x -> x==tempSetSelectedLevel2[i],tempSetSelectedLevel2)] = j
                        tempValueObj = calculObj2(voisinTempSolution.setSelectedLevel1,tempSetSelectedLevel2,distancesConcentrators)
                        if (voisinTempSolution.valueObj2 < tempValueObj)
                            #println("indice modif i = ",voisinTempSolution.setSelectedLevel2[i],"   j = ",j)
                            boolAmelioration = true
                            push!(listeTabou, i)
                            voisinTempSolution.valueObj1 += differenceObjectif1Level2(i,j,voisinTempSolution.linksLevel1Level2,linkConcentratorsCosts)
                            voisinTempSolution.valueObj2 = tempValueObj
                            for k in 1:length(voisinTempSolution.linksLevel1Level2)  # Mise à jour des affectations
                                if (voisinTempSolution.linksLevel1Level2[k] == voisinTempSolution.setSelectedLevel2[i])
                                    voisinTempSolution.linksLevel1Level2[k] = j
                                end
                            end
                            voisinTempSolution.setSelectedLevel2 = tempSetSelectedLevel2
                        end
                    end
                end
                j +=1
            end
            i+=1
        end

           ##########################Critère d'aspiration###################################

        if !boolAmelioration
            #bestVoisinTemp permet de sauvegarder le meilleur swap local, ce voisin est choisi lorsque aucun swap améliore la solution
            bestVoisinTemp = deepcopy(voisinTempSolution)
            bestVoisinTemp.valueObj1=Inf
            bestVoisinTemp.valueObj1=-Inf
            i=1
            while(i <= length(listeTabou) && !boolAmelioration)
                if(listeTabou[i] in voisinTempSolution.setSelectedLevel1)
                    setSelectedLevel = voisinTempSolution.setSelectedLevel1
                    bestTempSetSelectedLevel = bestVoisinTemp.setSelectedLevel1
                    links = voisinTempSolution.linksTerminalLevel1
                    bestTempLinks = bestVoisinTemp.linksTerminalLevel1
                    j = 1
                    nbLevel = numberLevel1
                else
                    setSelectedLevel = voisinTempSolution.setSelectedLevel2
                    bestTempSetSelectedLevel = bestVoisinTemp.setSelectedLevel2
                    links = voisinTempSolution.linksLevel1Level2
                    bestTempLinks = bestVoisinTemp.linksLevel1Level2
                    j = numberLevel1 +1
                    nbLevel = numberLevel1 + numberLevel2
                end
                while(j <= nbLevel && !boolAmelioration)
                    if ((j in setSelectedLevel) && !(j in listeTabou)) #Possible amélioration avec tri et Dichotomie
                        if (f == 1) # f = 1 pour objectif 1
                            if(listeTabou[i] in setSelectedLevel)
                                tempValueObj = differenceObjectif1(j,listeTabou[i],i,voisinTempSolution.linksTerminalLevel1,voisinTempSolution.linksLevel1Level2,linkCosts,linkConcentratorsCosts) #différence entre les solutions
                            else
                                tempValueObj = differenceObjectif1Level2(j,listeTabou[i],links,linkConcentratorsCosts) #différence entre les solutions
                            end
                            if (tempValueObj < bestVoisin.valueObj1) # Si le swap à permis une amélioration par rapport à voisinTempSolution
                                #Mise A Jour des Variables
                                boolAmelioration = true
                                voisinTempSolution.valueObj1 += tempValueObj
                                #println("listeTabou ", listeTabou)
                                #println("setSelectedLevel ", setSelectedLevel)
                                setSelectedLevel[findfirst(x -> x==j,setSelectedLevel)] = listeTabou[i]
                                for k in 1:length(links)  # Mise à jour des affectations
                                    if (links[k] == j)
                                        links[k] = listeTabou[i]
                                    end
                                end
                                deleteat!(listeTabou,i)
                                voisinTempSolution.valueObj2 = calculObj2(voisinTempSolution.setSelectedLevel1,voisinTempSolution.setSelectedLevel2,distancesConcentrators)


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
                            tempValueObj = calculObj2(voisinTempSolution.setSelectedLevel1,tempSetSelectedLevel,distancesConcentrators)
                            if (voisinTempSolution.valueObj2 < tempValueObj)
                                boolAmelioration = true
                                deleteat!(listeTabou,findfirst(x->x==i,listeTabou))
                                if(listeTabu[i] in setSelectedLevel1)
                                    tempValueObj1 = differenceObjectif1(j,listeTabou[i],voisinTempSolution.linksTerminalLevel1,voisinTempSolution.linksLevel1Level2,linkCosts,linkConcentratorsCosts) #différence entre les solutions
                                else
                                    tempValueObj1 = differenceObjectif1Level2(i,j,links,linkConcentratorsCosts) #différence entre les solutions
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
                                    tempValueObj1 = differenceObjectif1(i,j,voisinTempSolution.linksTerminalLevel1,voisinTempSolution.linksLevel1Level2,linkCosts,linkConcentratorsCosts) #différence entre les solutions
                                else
                                    tempValueObj1 = differenceObjectif1Level2(i,j,links,linkConcentratorsCosts) #différence entre les solutions
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
                i+=1
            end
            #println("bestVoisin.setSelectedLevel1 = ", bestVoisin.setSelectedLevel1)
            #println("bestVoisin.setSelectedLevel2 = ", bestVoisin.setSelectedLevel2)
            #println("bestVoisin.valueObj1 = ", bestVoisin.valueObj1)
            #println("bestVoisin.valueObj2 = ", bestVoisin.valueObj2)
            #println("bestVoisin.linksTerminalLevel1 = ", bestVoisin.linksTerminalLevel1)
            #println("bestVoisin.linksLevel1Level2 = ", bestVoisin.linksLevel1Level2)


        end
        #println("test")

        # Si il y a une amélioration de la solution courante on regarde si cette solution est meilleur que la meilleur solution trouver jusqu'a maintenant
        if boolAmelioration
            if f == 1
                if(voisinTempSolution.valueObj1 < bestVoisin.valueObj1)
                    bestVoisin = deepcopy(voisinTempSolution)
                end
                iter = 0
            else
                if(voisinTempSolution.valueObj2 > bestVoisin.valueObj2)
                    bestVoisin = deepcopy(voisinTempSolution)
                end
                iter = 0
            end

        else # cas ou aucune solution améliorante est trouvé
            voisinTempSolution = deepcopy(bestVoisinTemp)
            iter+=1
            #println("iter : ",iter)
        end
        if(length(listeTabou)>=7)
            deleteat!(listeTabou,1)
        end
    end
    #println("-----------------------------------------------")
    #println("bestVoisin.setSelectedLevel1 = ", bestVoisin.setSelectedLevel1)
    #println("bestVoisin.setSelectedLevel2 = ", bestVoisin.setSelectedLevel2)
    #println("bestVoisin.valueObj1 = ", bestVoisin.valueObj1)
    #println("bestVoisin.valueObj2 = ", bestVoisin.valueObj2)
    #println("bestVoisin.linksTerminalLevel1 = ", bestVoisin.linksTerminalLevel1)
    #println("bestVoisin.linksLevel1Level2 = ", bestVoisin.linksLevel1Level2)
    return bestVoisin
end

function differenceObjectif1(i,j,indiceAffectationLevel2,affectationLevel1,affectationLevel2,linkCostsTerminal,linkCostsConcentrator)
    valeur::Float64 = 0.0
    listeAffectationLevel1 = findall(x -> x==i,affectationLevel1)
    for a in listeAffectationLevel1
        valeur += linkCostsTerminal[j,a] - linkCostsTerminal[i,a]
    end
    #println("test13")
    #println("i = ",i)
    #println("j = ",j)
    #println("affectationLevel1 = ",affectationLevel1)
    #println("affectationLevel2 = ",affectationLevel2)
    indAffectationLevel2 = affectationLevel2[indiceAffectationLevel2]
    #println("indAffectationLevel2", indAffectationLevel2)
    #println(size(linkCostsConcentrator))
    #println("linkCostsConcentrator[j,indAffectationLevel2][1] = ", linkCostsConcentrator[j,indAffectationLevel2])
    temp = (linkCostsConcentrator[j,indAffectationLevel2][1] - linkCostsConcentrator[i,indAffectationLevel2][1])
    valeur = valeur + temp
    #println("valeur :", valeur )
    return valeur
end

function differenceObjectif1Level2(i,j,affectation,linkCosts)
    valeur::Float64 = 0.0
    listeAffectation = findall(x -> x==i,affectation)
    for a in listeAffectation
        valeur += linkCosts[a,j] - linkCosts[a,i]
    end
    #println("valeur :", valeur )
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




#linkCosts = Float32[55.67826 71.51636 71.47873 25.356148 92.56394 84.08742 70.355705 81.14982 84.52917 45.02583 118.64744 95.2246 39.518963 97.81885 32.461338 29.066725 60.576553 54.1026 99.94057 83.55967; 21.845207 34.98082 24.587273 53.937286 18.002775 51.62166 27.010826 7.1050444 16.187544 55.367527 43.243954 19.951218 43.294807 40.57621 56.689056 46.440624 15.055889 21.914392 24.797445 18.608528; 40.39705 5.835802 53.428715 49.668575 33.641468 20.851921 5.771271 28.527946 46.644882 37.901314 59.91465 42.52695 57.558308 22.880806 69.381325 49.067146 29.290394 37.28265 46.669685 49.4152; 61.695423 21.013346 74.140396 65.34291 47.52717 8.067118 26.951843 46.45624 65.167 47.539448 68.99132 57.282356 78.125465 19.827524 89.334694 67.38302 50.598087 58.518314 60.43311 68.34805; 19.394474 25.910826 30.51875 44.67695 25.158499 43.681416 18.015678 14.097728 26.774422 44.445015 52.397057 29.8143 39.798344 38.26009 52.913307 38.646782 8.482959 17.463058 34.70027 28.68901; 46.34897 68.21749 60.81627 23.63934 84.76561 82.65598 65.80569 73.29639 74.84249 46.23179 109.9555 86.538574 28.432182 93.36242 20.72885 22.1898 52.702168 45.333668 91.1289 73.580894; 66.0438 25.5965 81.7871 59.015987 61.737003 10.852447 33.569904 58.05286 76.24693 37.59204 85.46825 71.181244 78.510796 37.427322 87.89337 64.117714 56.060844 62.32689 74.91004 78.96919; 35.77797 76.04548 20.787273 66.76548 58.27254 94.21284 68.4566 51.44652 36.345146 81.85571 69.89193 52.35111 36.68271 85.911674 43.25728 54.89566 45.13879 39.72845 54.412094 32.663; 36.363434 33.25715 56.146545 13.610057 61.466297 45.779114 33.413963 51.074993 61.51504 12.288326 89.192856 66.93514 37.779236 60.131794 44.06456 19.76224 33.59544 32.688084 71.818825 62.19056; 51.915966 19.64762 61.155453 65.0567 31.129448 21.930122 20.297506 31.546614 50.05957 52.162186 52.76914 40.910866 70.96669 7.536587 83.36132 64.10235 40.641094 49.423138 43.902058 53.459938]
#linkConcentratorsCosts = Float32[0.0 75.46801 74.98314 90.39114 67.60152 11.744454 82.55212 75.060936 38.57145 90.36625; 75.46801 0.0 30.889326 50.485138 10.972422 67.1624 60.386707 45.37073 47.57856 36.677547; 74.98314 30.889326 0.0 21.31018 22.94696 70.91073 29.60655 73.62956 37.3012 15.388252; 90.39114 50.485138 21.31018 0.0 43.9452 88.227104 17.917376 94.60151 51.846706 16.595814; 67.60152 10.972422 22.94696 43.9452 0.0 60.35769 51.494392 50.703342 37.12261 32.703075; 11.744454 67.1624 70.91073 88.227104 60.35769 0.0 82.6502 63.410484 37.10929 86.09539; 82.55212 60.386707 29.60655 17.917376 51.494392 82.6502 0.0 101.19753 45.61901 32.77711; 75.060936 45.37073 73.62956 94.60151 50.703342 63.410484 101.19753 0.0 69.983444 81.925606; 38.57145 47.57856 37.3012 51.846706 37.12261 37.10929 45.61901 69.983444 0.0 52.600933; 90.36625 36.677547 15.388252 16.595814 32.703075 86.09539 32.77711 81.925606 52.600933 0.0]
#potentials = Float32[1392.6587, 641.218, 786.65607, 1082.7428, 633.839, 1250.573, 1207.3602, 1104.8982, 365.13226, 392.52902]
#distancesConcentrators = Float32[0.0 75.46801 74.98314 90.39114 67.60152 11.744454 82.55212 75.060936 38.57145 90.36625; 75.46801 0.0 30.889326 50.485138 10.972422 67.1624 60.386707 45.37073 47.57856 36.677547; 74.98314 30.889326 0.0 21.31018 22.94696 70.91073 29.60655 73.62956 37.3012 15.388252; 90.39114 50.485138 21.31018 0.0 43.9452 88.227104 17.917376 94.60151 51.846706 16.595814; 67.60152 10.972422 22.94696 43.9452 0.0 60.35769 51.494392 50.703342 37.12261 32.703075; 11.744454 67.1624 70.91073 88.227104 60.35769 0.0 82.6502 63.410484 37.10929 86.09539; 82.55212 60.386707 29.60655 17.917376 51.494392 82.6502 0.0 101.19753 45.61901 32.77711; 75.060936 45.37073 73.62956 94.60151 50.703342 63.410484 101.19753 0.0 69.983444 81.925606; 38.57145 47.57856 37.3012 51.846706 37.12261 37.10929 45.61901 69.983444 0.0 52.600933; 90.36625 36.677547 15.388252 16.595814 32.703075 86.09539 32.77711 81.925606 52.600933 0.0]
#selectedLevel1 = [5, 2, 3]
#links = [5, 3, 2, 5, 5, 3, 3, 5, 2, 3, 2, 3, 2, 3, 2, 5, 5, 2, 2, 5]
#selectedLevel2 = Any[9]
#linksLevel1Level2 = [9, 9, 9]
#valueObj1 = 667.6313
#valueObj2 = 43.889687
#numberLevel1 = 8
#numberLevel2 = 2


#sol = solution(selectedLevel1,links,selectedLevel2,linksLevel1Level2,valueObj1,valueObj2)
#TabuSearch(2,sol::solution, distancesConcentrators,linkConcentratorsCosts,linkCosts,numberLevel1,numberLevel2)



