using Random
using Metaheuristics.PerformanceIndicators: hypervolume
using Plots
include("VoptModel.jl")
include("generateSolutionObj1.jl")
include("generateSolutionObj2.jl")
include("TabuSearch.jl")
include("PathRelinking.jl")
include("SkipList.jl")


function loadInstance(fname)
    f=open(fname)
    # read the parameters of the instance, here m, n, p and r
    m, n, p, r = parse.(Int, split(readline(f)) )

    # read the location of the m facilities
    concentrators=zeros(Float32, m, 2)
    for i=1:m
        values = split(readline(f))
        for j in 1:2
            coordinate = parse(Float32,values[j])
            concentrators[i,j]= coordinate
        end
    end

    # read the location of the n demands
    terminals=zeros(Float32, n, 3)
    for i=1:n
        values = split(readline(f))
        for j in 1:3
            coordinate = parse(Float32,values[j])
            terminals[i,j]= coordinate
        end
    end


    close(f)
    return m, n, p, r, concentrators, terminals
end



function main(pathToInstance::String)

    println("")
    println("Instance of the problem")

    # opening the instance
    m, n, p, r, concentrators, terminals = loadInstance(pathToInstance)
    println("m = ", m, " (# concentrators)")
    println("n = ", n, " (# terminals)")
    println("p = ", p, " (# concentrators to open (level 1 & 2)")
    println("r = ", r)

    # we want to divide the set of concentrators in two levels
    # here, we have 4/5 of level 1 and 1/5 of level 2 concentrators
    ratioLevelOne::Float32 = 4/5
    numberLevel1 = (Int)(m*ratioLevelOne)
    numberLevel2 = m - numberLevel1
    println("numberLevel1 = ", numberLevel1, " (# level 1 concentrators)")
    println("numberLevel2 = ", numberLevel2, " (# level 2 concentrators)")

    # for our constraints we chose the capacitated concentrators
    # so, we have a maximum of 7 links to each concentrator (level 1 & 2)
    Q = 7

    # here, we shuffle concentrators to avoid bias during the picking
    #######tempArray = Array{Int}(1:m)
    #######shuffle!(tempArray)
    #######newConcentrators = zeros(Float32, m, 2)
    #######for i in 1:m
    #######    newConcentrators[i,1:2] = concentrators[tempArray[i],1:2]
    #######end
    #######concentrators = deepcopy(newConcentrators)

    # we generate the distance matrix between terminals and concentrators
    distancesTerminalsConcentrators = zeros(Float32, m, n)
    for i in 1:m
        for j in 1:n
            dist = (concentrators[i,1]-terminals[j,1])^2 + (concentrators[i,2]-terminals[j,2])^2
            dist = dist^0.5
            distancesTerminalsConcentrators[i,j] = dist
        end
    end

    # we generate randomized costs for linking terminals to concentrators
    linkCosts = zeros(Float32, m,n)
    for i in 1:m
        for j in 1:n
            linkCosts[i,j] = distancesTerminalsConcentrators[i,j]
        end
    end

    # we generate the distance matrix between all concentrators
    distancesConcentrators = zeros(Float32, m, m)
    for i in 1:m
        for j in 1:m
            dist = (concentrators[i,1]-concentrators[j,1])^2 + (concentrators[i,2]-concentrators[j,2])^2
            dist = dist^0.5
            distancesConcentrators[i,j] = dist
        end
    end

    # we estimate the potential of each level1 concentrator
    potentials = zeros(Float32, m)
    for i in 1:numberLevel1
        for j in 1:n
            potentials[i] += linkCosts[i,j]
        end
    end

    # we generate random costs between level 1 and level 2 concentrators
    linkConcentratorsCosts = zeros(Float32, m,m)
    #for i in 1:numberLevel1
    #    for j in (numberLevel1+1):m
    #        randCost = rand(10:50)
    #        linkConcentratorsCosts[i,j] = randCost
    #    end
    #end
    linkConcentratorsCosts = copy(distancesConcentrators)

    # we estimate the potential of each level2 concentrator
    for i in (numberLevel1+1):m
        for j in 1:numberLevel1
            potentials[i] += linkConcentratorsCosts[j,i]
        end
    end

    println("")
    println("-----------------------------")
    println("")

    C1 = 0 #100
    C2 = 0 #200

    # we generate our first population of solution
    # half is good for the first objective the other is good for the second one
    archive = SkipList()
    solutionsGRASP=[]
    iterationGRASP = 16
    globalIndex = 1

    @time for i in 1:iterationGRASP
        baseSolution = generateSolutionObj1(linkCosts, linkConcentratorsCosts, potentials, distancesConcentrators, Q, numberLevel1, numberLevel2, n, C1, C2)
        improvedSolution = TabuSearch(1, baseSolution, distancesConcentrators, linkConcentratorsCosts, linkCosts, numberLevel1, numberLevel2)
        improvedSolution.index = globalIndex
        globalIndex += 1
        addArchive(archive, [improvedSolution.valueObj1, improvedSolution.valueObj2])
        push!(solutionsGRASP, improvedSolution)
    end
    @time for i in 1:iterationGRASP
        baseSolution = generateSolutionObj2(linkCosts, linkConcentratorsCosts, distancesConcentrators, Q, numberLevel1, numberLevel2, n, C1, C2)
        improvedSolution = TabuSearch(2, baseSolution, distancesConcentrators, linkConcentratorsCosts, linkCosts, numberLevel1, numberLevel2)
        improvedSolution.index = globalIndex
        globalIndex += 1
        addArchive(archive, [improvedSolution.valueObj1, improvedSolution.valueObj2])
        push!(solutionsGRASP, improvedSolution)
    end

    # building the initial refSets of size beta
    refSet1 = []
    refSet2 = []
    beta = 8

    # first, we add the best beta/2 solutions for each objective of respective refsets
    for i in 1:beta/2
        bestObj1 = Inf
        indexBestObj1 = -1
        for j in 1:length(solutionsGRASP)
            valCandidate = solutionsGRASP[j].valueObj1
            if  valCandidate < bestObj1
                bestObj1 = valCandidate
                indexBestObj1 = j
            end
        end
        push!(refSet1, copySolution(solutionsGRASP[indexBestObj1]))
        deleteat!(solutionsGRASP, indexBestObj1)
    end

    for i in 1:beta/2
        bestObj2 = 0
        indexBestObj2 = -1
        for j in 1:length(solutionsGRASP)
            valCandidate = solutionsGRASP[j].valueObj2
            if  valCandidate > bestObj2
                bestObj2 = valCandidate
                indexBestObj2 = j
            end
        end
        push!(refSet2, copySolution(solutionsGRASP[indexBestObj2]))
        deleteat!(solutionsGRASP, indexBestObj2)
    end

    # now, we build the second half of the refsets by adding the most distant solutions to each refset
    for i in (beta/2)+1:beta
        maxDist = 0
        indexMaxDist = -1
        for j in 1:length(solutionsGRASP)
            for k in 1:length(refSet1)
                distCandidate = distanceSolutions(solutionsGRASP[j], refSet1[k])
                if distCandidate > maxDist
                    maxDist = distCandidate
                    indexMaxDist = j
                end
            end
        end
        push!(refSet1, copySolution(solutionsGRASP[indexMaxDist]))
        deleteat!(solutionsGRASP, indexMaxDist)
    end

    for i in (beta/2)+1:beta
        maxDist = 0
        indexMaxDist = -1
        for j in 1:length(solutionsGRASP)
            for k in 1:length(refSet2)
                distCandidate = distanceSolutions(solutionsGRASP[j], refSet2[k])
                if distCandidate > maxDist
                    maxDist = distCandidate
                    indexMaxDist = j
                end
            end
        end
        push!(refSet2, copySolution(solutionsGRASP[indexMaxDist]))
        deleteat!(solutionsGRASP, indexMaxDist)
    end

    test::Vector{Vector{Float64}} = []
    for i in 1:beta
        push!(test, [refSet1[i].valueObj1,refSet1[i].valueObj2])
        push!(test, [refSet2[i].valueObj1,refSet2[i].valueObj2])
    end

    # now we start the iterations to create the pareto front

    # here, we try to update refsets if a new sol is improving
    # forbiddenPairs represents the pairs we already evaluated
    forbiddenPairs = []
    stop = false
    @time while !stop
        stop = true
        poolSolutions = []
        # here, we process the pathrelinking between all new pairs from refset1 and refset2
        for a in 1:beta
            for b in 1:beta
                S1 = refSet1[a]
                S2 = refSet2[b]
                indexS1 = S1.index
                indexS2 = S2.index
                pair = [min(indexS1, indexS2), max(indexS1, indexS2)]
                if !(pair in forbiddenPairs)
                    # here, we call the path relinking to "link" one solution of each refset
                    newSols = PathRelinking(S1, S2, n, m, Q, linkCosts, linkConcentratorsCosts, distancesConcentrators)
                    for sol in 1:length(newSols)
                        # then, each new solution is improved for each objective
                        addArchive(archive, [newSols[sol].valueObj1, newSols[sol].valueObj2])
                        improvedSolution1 = TabuSearch(1, newSols[sol], distancesConcentrators, linkConcentratorsCosts, linkCosts, numberLevel1, numberLevel2)
                        improvedSolution2 = TabuSearch(2, newSols[sol], distancesConcentrators, linkConcentratorsCosts, linkCosts, numberLevel1, numberLevel2)
                        improvedSolution1.index = globalIndex
                        improvedSolution2.index = (globalIndex + 1)
                        globalIndex += 2
                        # if we already have these solutions, we don't keep them
                        keep = true
                        for i in 1:length(poolSolutions)
                            if !isDifferent(improvedSolution1,poolSolutions[i])
                                keep = false
                            end
                        end
                        if keep
                            push!(poolSolutions, improvedSolution1)
                            addArchive(archive, [improvedSolution1.valueObj1, improvedSolution1.valueObj2])
                        end
                        keep = true
                        for i in 1:length(poolSolutions)
                            if !isDifferent(improvedSolution2,poolSolutions[i])
                                keep = false
                            end
                        end
                        if keep
                            push!(poolSolutions, improvedSolution2)
                            addArchive(archive, [improvedSolution2.valueObj1, improvedSolution2.valueObj2])
                        end
                    end
                    push!(forbiddenPairs,pair)
                end
            end
        end

        # we check if we have a dominated solution inside the refset 1
        for i in 1:length(poolSolutions)

            candidateSolution = poolSolutions[i]
            candidateValueObj1 = candidateSolution.valueObj1
            dominatedSols = []

            for j in 1:beta
                if(candidateValueObj1 < refSet1[j].valueObj1)
                    push!(dominatedSols,j)
                end
            end

            if length(dominatedSols) > 0
                stop = false
                distMin = Inf
                indexMin = -1
                for j in 1:length(dominatedSols)
                    dist = distanceSolutions(refSet1[dominatedSols[j]], candidateSolution)
                    if (dist < distMin)
                        distMin = dist
                        indexMin = dominatedSols[j]
                    end
                end
            end
        end

        # we check if we have a dominated solution inside the refset 2
        for i in 1:length(poolSolutions)

            candidateSolution = poolSolutions[i]
            candidateValueObj2 = candidateSolution.valueObj2
            dominatedSols = []

            for j in 1:beta
                if(candidateValueObj2 > refSet2[j].valueObj2)
                    push!(dominatedSols,j)
                end
            end

            if length(dominatedSols) > 0
                stop = false
                distMin = Inf
                indexMin = -1
                for j in 1:length(dominatedSols)
                    dist = distanceSolutions(refSet2[dominatedSols[j]], candidateSolution)
                    if (dist < distMin)
                        distMin = dist
                        indexMin = dominatedSols[j]
                    end
                end
                refSet2[indexMin] = copySolution(candidateSolution)
            end
        end

    end
    #affichageSkiplist(archive)
    println(nbrPoint(archive))
    pts = setOfSolutions(archive)
    return pts
end

#main("Instances/small5.txt")

function Interface()
   println("################## ScatterSearch #####################")
   continuer = true
   while(continuer)
       println("")
       print("Entrez le nom de l'instance (exemple: small1) : ")
       instance = readline()
       instance = "Instances/"* instance *".txt"
       println("")
       println("Démarrage de la résolution")
       pts = main(instance)
       print("Voulez vous comparer le scatter search à Vopt (Y/N): ")
       choix = readline()
       if(choix == "Y")
           print("temps epsilon : ")
           @time YN = solveExact(instance)
           println("")
           for i in 1:length(pts)
           pts[i][2] = -pts[i][2]
           end
           for i in 1:length(YN)
           YN[i][2] = -YN[i][2]
           end
           xMax = 0
           yMax = -Inf
           for i in 1:length(pts)
              if(pts[i][1] > xMax)
                  xMax = pts[i][1]
              end
           end
           for i in 1:length(YN)
              if(YN[i][1] > xMax)
                  xMax = YN[i][1]
              end
           end

           for i in 1:length(pts)
               if(pts[i][2] > yMax)
                   yMax = pts[i][2]
               end
           end
           for i in 1:length(YN)
               if(YN[i][2] > yMax)
                   yMax = YN[i][2]
               end
           end
           refPoint = [xMax, yMax]
           println("refPoint = ", refPoint)
           hv1 = hypervolume(pts, refPoint)
           println("hv scatter = ", hv1)
           hv2 = hypervolume(YN, refPoint)
           println("hv vopt = ", hv2)
           println("nb sol vopt = ", length(YN))
           println("nb sol scatter = ", length(pts))

           plotResults(pts, YN)
       else
           plotResult(pts)
       end
       print("Voulez-vous tester une autre instance (Y/N)? ")
       autre = readline()
       println("")
       if(autre == "N")
           continuer = false
       end
   end
end


Interface()