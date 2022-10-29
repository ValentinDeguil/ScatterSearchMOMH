using Random

function loadInstance(fname)
    f=open(fname)
    # read the parameters of the instance, here m, n, p and r
    m, n, p, r = parse.(Int, split(readline(f)) )

    # read the location of the m facilities
    facilities=zeros(Float32, m, 2)
    for i=1:m
        values = split(readline(f))
        for j in 1:2
            coordinate = parse(Float32,values[j])
            facilities[i,j]= coordinate
        end
    end

    # read the location of the n demands
    demands=zeros(Float32, n, 3)
    for i=1:n
        values = split(readline(f))
        for j in 1:3
            coordinate = parse(Float32,values[j])
            demands[i,j]= coordinate
        end
    end


    close(f)
    return m, n, p, r, facilities, demands
end

function generatePopulation(sizePopulation::Int, facilities::Matrix{Float32}, p::Int)
    solutions = Array{Array{Int}}
    numberFacilities = size(facilities,1)
    setOfFacilities = []
    for i in 1:numberFacilities
        push!(setOfFacilities, i)
    end

    for i in 1:(Int)(floor(sizePopulation/2))
        # pick a random facility
        randFacility = rand(1:numberFacilities)
        println("randFacility = ", randFacility)
        solution = [randFacility]
        # we add other facility with a metaheuristic based on GRASP
        CL = copy(setOfFacilities) # candidate list
        splice!(CL,randFacility)
        RCL = [] # restricted candidate list
        for i in 1:(p-1)

        end
    end
    for i in (Int)(floor(sizePopulation/2))+1:sizePopulation

    end
end

function main(pathToInstance::String, sizePopulation::Int)

    # opening the instance
    m, n, p, r, facilities, demands = loadInstance(pathToInstance)
    println("m = ", m)
    println("n = ", n)
    println("p = ", p)
    println("r = ", r)

    # we generate our first population of solution
    # half is good for the first objective the other is good for the second one
    generatePopulation(sizePopulation, facilities, p)
end

main("Instances/small1.txt", 10)