#=
SkipList:
- Julia version: 1.8.1
- Author: mathey
- Date: 2022-10-20
=#

mutable struct point
    valeur::Vector{Float64}
    nord
    sud
    est
    ouest
end

function SkipList()
    init = point([-Inf,-Inf],nothing,nothing,nothing,nothing)
    infini = point([Inf,Inf],nothing,nothing,nothing,init)
    init.est= infini
    return init
end

function addArchive(init::point,x::Vector{Float64})
    temp::point = init
    filtrer = false
    suppre = nothing

    while !filtrer
        #Parcour des pointeurs de la colonne
        while x[1]<(temp.est).valeur[1] && temp.sud!=nothing
            temp = temp.sud
        end
        #Parcour des pointeurs de la ligne
        while x[1]>=(temp.est).valeur[1]
            temp = temp.est
        end

        if x[1]>=temp.valeur[1] && x[1]<=(temp.est).valeur[1] && temp.sud == nothing
            filtrer = true
        end
    end
    if x[1] == temp.valeur[1]
       temp = temp.ouest
    end

    possibleDominance = temp.est
    while domine(x,possibleDominance.valeur)
        suppressionPoint(possibleDominance)
        possibleDominance = temp.est
    end

    if !domine((temp.est).valeur,x) && !domine(temp.valeur,x)
        add(init,temp,x)
        #return true
    end
    #println("FIN!!!!")
end



function add(head, skiplist::point, x::Vector{Float64})
    inserer = false
    gauche = skiplist # point à gauche du point à insérer
    droite = skiplist.est

    if gauche.nord == nothing && gauche.valeur[1] == -Inf #Cas du premier point à ajouter
        newPoint = point([-Inf,-Inf],gauche,nothing,nothing,nothing)
        infini = point([Inf,Inf],gauche.est,nothing,nothing,newPoint)
        newPoint.est = infini
        (gauche.est).sud = infini
        gauche.sud = newPoint
        gauche = newPoint
        droite = infini
    end
    newPoint = point(x,nothing,nothing,droite,gauche) #Création du point à ajouter + insertion à droite du point gauche
    gauche.est = newPoint
    droite.ouest = newPoint
    #affichageSkiplist(head)
    cpt = 1
    while pileOuFace()
        cpt+=1
        gauche = gaucheSup(gauche)
        droite = droiteSup(droite)
        temp = point(x,nothing,newPoint,droite,gauche)
        newPoint.nord = temp
        gauche.est = temp
        droite.ouest = temp
        newPoint = temp
    end
    #println("Il a ",cpt,"ligne de ",x)
end



function gaucheSup(gauche::point)
    temp = gauche
    while temp.nord == nothing && temp.ouest != nothing
        temp = temp.ouest
    end
    temp = temp.nord
    if temp.nord == nothing && temp.ouest == nothing
        newPoint = point([-Inf,-Inf],temp,temp.sud,nothing,nothing)
        infini = point([Inf,Inf],temp.est,(temp.est).sud,nothing,newPoint)
        newPoint.est = infini
        (temp.est).sud = infini
        (infini.sud).nord = infini
        (temp.sud).nord = newPoint
        temp.sud = newPoint
        temp = newPoint
    end
    return temp
end

function droiteSup(droite::point)
    temp = droite
    while temp.nord == nothing && temp.est != nothing
        temp = temp.est
    end
    temp = temp.nord
    return temp
end

# Retourne si x1 domine x2
function domine(x1,x2)
    if x1[1] <= x2[1] && x1[2] >= x2[2]
        return true
    else
        return false
    end
end

function suppressionPoint(pointASupprimer::point)
    (pointASupprimer.ouest).est = pointASupprimer.est
    (pointASupprimer.est).ouest = pointASupprimer.ouest
    pointASupprimer.est = nothing
    pointASupprimer.ouest = nothing
    temp = pointASupprimer
    while temp.nord != nothing
        temp = temp.nord
        (temp.sud).nord = nothing
        (temp.ouest).est = temp.est
        (temp.est).ouest = temp.ouest
        temp.est = nothing
        temp.ouest = nothing
    end
end


function pileOuFace()
    if rand()>0.5
        return true
    else
        return false
    end
end




function affichageSkiplist(head::point)
    nbrpoint = nbrPoint(head)
    affichage = string(head.valeur)
    affichage = affichage * "------"
    for i in 1:nbrpoint
        affichage = affichage * "------"
    end
    affichage = affichage * string((head.est).valeur)
    println(affichage)
    temp = head
    affichage = ""
    while temp.sud != nothing
        temp = temp.sud
        affichage = string(temp.valeur)
        tempEst = temp
        while tempEst.est != nothing
            #println("TEST")
            tempEst = tempEst.est
            affichage = affichage * "------"
            affichage = affichage * string(tempEst.valeur)
        end
        println(affichage)
    end

end

function nbrPoint(head::point)::Int64
    while head.sud != nothing
        head = head.sud
    end
    cpt = -1
    while head.est!= nothing
        cpt = cpt+1
        head = head.est
    end
    return cpt
end


function setOfSolutions(head::point)::Vector{Vector{Float64}}
   temp = head
   setSol = Vector{Vector{Float64}}()
   while(temp.sud!=nothing)
       temp = temp.sud
   end
   while (temp.est != nothing)
       temp = temp.est
       test = temp.valeur
       push!(setSol,test)
   end
   deleteat!(setSol,length(setSol))
   return setSol
end    

#test = SkipList()
#affichageSkiplist(test)
#println("")
#addArchive(test,[1.0,1.0])
#affichageSkiplist(test)
#println("")
#addArchive(test,[2.0,2.0])
#affichageSkiplist(test)
#println("")
#addArchive(test,[1.0,2.0])
#affichageSkiplist(test)
#println("")
#addArchive(test,[3.0,3.0])
#affichageSkiplist(test)
#println("")
#addArchive(test,[1.0,2.0])
#affichageSkiplist(test)








#=
    if x[1] > (temp.est).valeur[1]
            temp = temp.est
        elseif  x[1] == temp.valeur[1]
            if domine(x,temp.values)
                suppre = temp
                temp = temp.ouest
                suppressionPoint(suppre)
                add(temp,x)
                filtrer = true
            else if
        end



function remonter(point::point)
=#