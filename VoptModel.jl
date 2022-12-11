#=
VoptModel:
- Julia version: 
- Author: mathey
- Date: 2022-12-10
=#
# =============================================================================


# =============================================================================

print("Loading and compiling vOptGeneric, JuMP, GLPK...")
using vOptGeneric, JuMP, GLPK, Printf
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

    return Instance(pathToInstance,numberLevel1,numberLevel2,n,round.(Int,distancesConcentrators),round.(Int,linkCosts),round.(Int,linkConcentratorsCosts),C1,C2,Q)
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
    @variable(model, y[1:data.numberLevel1+data.numberLevel2,data.numberLevel1+1:data.numberLevel1+data.numberLevel2], Bin) #affectation des level1 au level2
    @variable(model, z[1:data.numberLevel1+data.numberLevel2], Bin) #Ouverture concentrator
    @variable(model, minDist[1:data.numberLevel1+data.numberLevel2], Int) # Distance minimale pour chaque concentrateur de lvl1

    @addobjective( model, Min, sum(data.linkCosts[i,j]*x[i,j] for i in 1:data.numberLevel1, j in 1:data.numberTerminals) + sum(data.linkConcentratorsCosts[i,j]*y[i,j] for i in 1:data.numberLevel1, j in (data.numberLevel1+1):(data.numberLevel1+data.numberLevel2)) )
    @addobjective( model, Max, sum(minDist[i] for i in 1:data.numberLevel1))
    M =10000

    @constraint( model, [i=1:data.numberLevel1+data.numberLevel2, j=1:data.numberLevel1+data.numberLevel2, i!=j], minDist[i] <= data.distancesConcentrators[i,j]+M*(1-z[j]))

    @constraint( model, [i=1:data.numberLevel1, j=1:data.numberTerminals], x[i,j]<=sum(y[i,k] for k in(data.numberLevel1+1):(data.numberLevel1+data.numberLevel2) ))
    @constraint( model, [j=1:data.numberTerminals], sum(x[i,j] for i in 1:data.numberLevel1) == 1 )
    @constraint( model, [i=1:data.numberLevel1], sum(x[i,j] for j in 1:data.numberTerminals) <= data.maximumNumberOfLinks )


    @constraint( model, [i=1:data.numberLevel1, k=(data.numberLevel1+1):(data.numberLevel1+data.numberLevel2)], y[i,k] <= z[k])
    @constraint( model, [i=1:data.numberLevel1], sum(y[i,k] for k in data.numberLevel1+1:data.numberLevel1+data.numberLevel2) <= 1 )
    @constraint( model, [j=data.numberLevel1+1:data.numberLevel1+data.numberLevel2], sum(y[i,j] for i in 1:data.numberLevel1) <= data.maximumNumberOfLinks )
    return model
end


# ==============================================================================
function main()

    # -------------------------------------------------------------------------
    # Load an instance (files are available in vOptLib)

    fname = "Instances/verySmall1.txt"   # filename of the instance to solve
    data  = InstanceCreation(fname)

    # -------------------------------------------------------------------------
    # Display information about the instance to solve

    println("\nfilename      : $(data.fname)")
    #println("nI (users)    : $(data.nI)")
    #println("nJ (services) : $(data.nJ)\n")

    # -------------------------------------------------------------------------
    # compute YN with vOptGeneric using ϵ-constraint method and GLPK

    println("Running the ϵ-constraint method with GLPK... \n")
    solver = GLPK.Optimizer
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
    return nothing

end

# ==============================================================================
main()