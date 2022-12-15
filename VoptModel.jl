#=
VoptModel:
- Julia version: 
- Author: mathey
- Date: 2022-12-10
=#
# =============================================================================


# =============================================================================

print("Loading and compiling vOptGeneric, JuMP, CPLEX...")
using vOptGeneric, JuMP, CPLEX, Printf
println(" done!")


# =============================================================================
# structure of a 2UFLP instance

mutable struct Instance
    fname :: String                     # name of the file
    numberLevel1::Int64                 # number of concentrators level 1
    numberLevel2::Int64                 # number of concentrators level 1
    numberTerminals::Int64              # number of terminals
    #distancesTerminalsConcentrators
    distancesConcentrators
    linkCosts
    linkConcentratorsCosts
    openingCostLevel1
    openingCostLevel2
    maximumNumberOfLinks::Int64
    M::Int64
end


# =============================================================================
function loadInstance(fname::String)
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

function InstanceCreation(pathToInstance::String)
    #println("")
    #println("Instance of the problem")

    # opening the instance
    m, n, p, r, concentrators, terminals = loadInstance(pathToInstance)
    #println("m = ", m, " (# concentrators)")
    #println("n = ", n, " (# terminals)")
    #println("p = ", p, " (# concentrators to open (level 1 & 2)")
    #println("r = ", r)

    # we want to divide the set of concentrators in two levels
    # here, we have 4/5 of level 1 and 1/5 of level 2 concentrators
    ratioLevelOne::Float32 = 4/5
    numberLevel1 = (Int)(m*ratioLevelOne)
    numberLevel2 = m - numberLevel1
    #println("numberLevel1 = ", numberLevel1, " (# level 1 concentrators)")
    #println("numberLevel2 = ", numberLevel2, " (# level 2 concentrators)")

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
            #randCost = rand(10:50)
            #linkCosts[i,j] = randCost
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
    for i in 1:numberLevel1
        for j in (numberLevel1+1):m
            randCost = rand(10:50)
            linkConcentratorsCosts[i,j] = randCost
        end
    end
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
    distancesConcentrators = round.(Int,distancesConcentrators)
    M = maximum(distancesConcentrators)


    return Instance(pathToInstance,numberLevel1,numberLevel2,n,distancesConcentrators,round.(Int,linkCosts),round.(Int,linkConcentratorsCosts),C1,C2,Q,M)
end




#mutable struct Instance
#    fname :: String                     # name of the file
#    numberLevel1::Int64                 # number of concentrators level 1
#    numberLevel2::Int64                 # number of concentrators level 1
#    numberTerminals::Int64              # number of terminals
#    #distancesTerminalsConcentrators
#    distancesConcentrators
#    linkCosts
#    linkConcentratorsCosts
#    openingCostLevel1
#    openingCostLevel2
#    maximumNumberOfLinks::Int64
#end




# ==============================================================================
"""
    createModel2UFLP(solver::DataType, data::Instance)
    Create the vOptGeneric model of 2UFLP
"""
function createModelTSUFLP(solver::DataType, data::Instance)

    model = vModel( solver )

    @variable(model, x[1:data.numberLevel1,1:data.numberTerminals], Bin) #affectation des terminaux au level1
    @variable(model, y[1:data.numberLevel1,data.numberLevel1+1:data.numberLevel1+data.numberLevel2], Bin) #affectation des level1 au level2
    @variable(model, z[1:data.numberLevel1+data.numberLevel2], Bin) #Ouverture concentrator
    @variable(model, minDist[1:data.numberLevel1+data.numberLevel2], Int) # Distance minimale pour chaque concentrateur

    @addobjective( model, Min, sum(data.linkCosts[i,j]*x[i,j] for i in 1:data.numberLevel1, j in 1:data.numberTerminals) + sum(data.linkConcentratorsCosts[i,j]*y[i,j] for i in 1:data.numberLevel1, j in (data.numberLevel1+1):(data.numberLevel1+data.numberLevel2)) )
    @addobjective( model, Max, sum(minDist[i] for i in 1:data.numberLevel1+data.numberLevel2))
    #@addobjective( model, Max, minDist[1:data.numberLevel1+data.numberLevel2])
    M = data.M

    @constraint( model, [i=1:data.numberLevel1+data.numberLevel2, j=1:data.numberLevel1+data.numberLevel2; i!=j], minDist[i] <= data.distancesConcentrators[i,j]+M*(1-z[i])+M*(1-z[j]))
    @constraint( model, [i=1:data.numberLevel1+data.numberLevel2], minDist[i] <= M*z[i])

    @constraint( model, [i=1:data.numberLevel1, j=1:data.numberTerminals], x[i,j]<=sum(y[i,k] for k in(data.numberLevel1+1):(data.numberLevel1+data.numberLevel2) ))
    @constraint( model, [j=1:data.numberTerminals], sum(x[i,j] for i in 1:data.numberLevel1) == 1 )
    @constraint( model, [i=1:data.numberLevel1], sum(x[i,j] for j in 1:data.numberTerminals) <= data.maximumNumberOfLinks )

    @constraint( model, [i=1:data.numberLevel1], z[i] <= sum(y[i,k] for k in (data.numberLevel1+1):(data.numberLevel1+data.numberLevel2)))
    @constraint( model, [k=(data.numberLevel1+1):(data.numberLevel1+data.numberLevel2)], z[k] <= sum(y[i,k] for i in 1:data.numberLevel1))
    @constraint( model, [i=1:data.numberLevel1, k=(data.numberLevel1+1):(data.numberLevel1+data.numberLevel2)], y[i,k] <= z[i])
    @constraint( model, [i=1:data.numberLevel1, k=(data.numberLevel1+1):(data.numberLevel1+data.numberLevel2)], y[i,k] <= z[k])
    @constraint( model, [i=1:data.numberLevel1], sum(y[i,k] for k in data.numberLevel1+1:data.numberLevel1+data.numberLevel2) <= 1 )
    @constraint( model, [j=data.numberLevel1+1:data.numberLevel1+data.numberLevel2], sum(y[i,j] for i in 1:data.numberLevel1) <= data.maximumNumberOfLinks )
    return model
end


# ==============================================================================
function solveExact(fileName)

    # -------------------------------------------------------------------------
    # Load an instance (files are available in vOptLib)

    fname = fileName   # filename of the instance to solve
    #fname = fileName
    data  = InstanceCreation(fname)

    #println("linkCosts = ",data.linkCosts)
    #println("linkConcentratorsCosts = ", data.linkConcentratorsCosts)
    #println("distancesConcentrators = ", data.distancesConcentrators)

    # -------------------------------------------------------------------------
    # Display information about the instance to solve

    println("\nfilename      : $(data.fname)")
    #println("nI (users)    : $(data.nI)")
    #println("nJ (services) : $(data.nJ)\n")

    # -------------------------------------------------------------------------
    # compute YN with vOptGeneric using ϵ-constraint method and CPLEX

    println("Running the ϵ-constraint method with GLPK... \n")
    solver = CPLEX.Optimizer
    modTSUFLP = createModelTSUFLP(solver, data)
    set_silent(modTSUFLP)

    getTime = time()
    vSolve(modTSUFLP, method=:epsilon, step = 1.0)
    timevOPt = round(time()- getTime, digits=4)


    # -------------------------------------------------------------------------
    # Display the results

    println("\nDisplaying the results... \n")
    YN = getY_N( modTSUFLP )
    println("fname: $(fname[1:end-4])     tOpt: $(timevOPt) sec     #YN: $(length(YN)) points\n")
    printX_E( modTSUFLP )
    println("\n...done!")
    println(YN)
    #for i in 1
    return YN

end

# ==============================================================================

# x = [4,3,4,7,2,3,3,2,2,3,2,2,7,3,7,7,4,4,2,2]
# y =[9,10,9,9]
# selectedLvl1 = [2,3,4,7]
# selectedLvl2 = [9,10]
# linkCosts = [36 76 21 67 58 94 68 51 36 82 70 52 37 86 43 55 45 40 54 33; 22 35 25 54 18 52 27 7 16 55 43 20 43 41 57 46 15 22 25 19; 40 6 53 50 34 21 6 29 47 38 60 43 58 23 69 49 29 37 47 49; 19 26 31 45 25 44 18 14 27 44 52 30 40 38 53 39 8 17 35 29; 52 20 61 65 31 22 20 32 50 52 53 41 71 8 83 64 41 49 44 53; 66 26 82 59 62 11 34 58 76 38 85 71 79 37 88 64 56 62 75 79; 46 68 61 24 85 83 66 73 75 46 110 87 28 93 21 22 53 45 91 74; 56 72 71 25 93 84 70 81 85 45 119 95 40 98 32 29 61 54 100 84; 36 33 56 14 61 46 33 51 62 12 89 67 38 60 44 20 34 33 72 62; 62 21 74 65 48 8 27 46 65 48 69 57 78 20 89 67 51 59 60 68]
# linkConcentratorsCosts = [0 45 74 51 82 101 63 75 70 95; 45 0 31 11 37 60 67 75 48 50; 74 31 0 23 15 30 71 75 37 21; 51 11 23 0 33 51 60 68 37 44; 82 37 15 33 0 33 86 90 53 17; 101 60 30 51 33 0 83 83 46 18; 63 67 71 60 86 83 0 12 37 88; 75 75 75 68 90 83 12 0 39 90; 70 48 37 37 53 46 37 39 0 52; 95 50 21 44 17 18 88 90 52 0]
# distancesConcentrators = [0 45 74 51 82 101 63 75 70 95; 45 0 31 11 37 60 67 75 48 50; 74 31 0 23 15 30 71 75 37 21; 51 11 23 0 33 51 60 68 37 44; 82 37 15 33 0 33 86 90 53 17; 101 60 30 51 33 0 83 83 46 18; 63 67 71 60 86 83 0 12 37 88; 75 75 75 68 90 83 12 0 39 90; 70 48 37 37 53 46 37 39 0 52; 95 50 21 44 17 18 88 90 52 0]