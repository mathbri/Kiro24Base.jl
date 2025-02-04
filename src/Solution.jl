# Solution structure for KIRO24

# V x S instead of S x V because it is faster to access sequences that way

mutable struct Solution
    # V x S matrix describing the entry sequences of the shops
    entries::Matrix{Int}
    # V x S matrix describing the exit sequences of the shops
    exits::Matrix{Int}
end

function Base.show(io::IO, solution::Solution)
    println(io, "Solution(entries=")
    show(io, "text/plain", solution.entries)
    println(io, "\nexits=")
    show(io, "text/plain", solution.exits)
    return print(io, "\n)")
end

# Computes the cost of the solution
function compute_cost(instance::Instance, solution::Solution; verbose::Bool=false)
    totalCost = 0.0
    verbose && println("Computing solution cost")
    # Resequencing between shops
    for s in eachindex(instance.shops)
        shop = instance.shops[s]
        verbose && println("\nShop $(shop.name)")
        # Cost incurred inside the shop
        sequence = solution.entries[:, s]
        verbose && println("Sequence $sequence inside the shop")
        totalCost += shop_cost(shop, sequence; verbose=verbose)
        # Cost incurred between shops
        sequence = solution.exits[:, s]
        verbose && println("Sequence $sequence at exit of the shop")
        # No delay cost for the last shop 
        if s < length(instance.shops)
            nextSequence = solution.entries[:, s + 1]
            verbose && println("Sequence $nextSequence inside the next shop")
            delayCost = delay_cost(shop, sequence, nextSequence)
            verbose && println("Delay cost : $delayCost")
            totalCost += delayCost
        end
    end
    verbose && println("\nTotal cost : $totalCost")
    return totalCost
end

# Read a solution file 
function read_solution(instance::Instance, solution_file::String)
    # Reading the solution file
    solDict::Dict{String,Dict{String,Vector{Int}}} = JSON.parsefile(solution_file)
    # Creating an empty solution
    solution = Solution(
        zeros(Int, length(instance.vehicles), length(instance.shops)),
        zeros(Int, length(instance.vehicles), length(instance.shops)),
    )
    # Completing the empty solution with the solution dictionnary
    for (s, shop) in enumerate(instance.shops)
        solution.entries[:, s] = solDict[shop.name]["entry"]
        solution.exits[:, s] = solDict[shop.name]["exit"]
    end
    return solution
end

# Writes a solution file 
function write_solution(instance::Instance, solution::Solution)
    # Creating dict to be written with JSON
    solDict = Dict{String,Dict{String,Vector{Int}}}()
    for (s, shop) in enumerate(instance.shops)
        solDict[shop.name] = Dict(
            "entry" => solution.entries[:, s], "exit" => solution.exits[:, s]
        )
    end
    # Writing dict with JSON
    open(joinpath("data", "$(instance.name)_sol.json"), "w") do io
        JSON.print(io, solDict)
    end
end

function test_all_groups_sol(instance::Instance)
    allSol = Dict()
    for gr in 1:22
        # No group 19
        gr == 19 && continue
        instName = replace(instance.name, '_' => '-')
        sol = read_solution(
            instance,
            joinpath("Rendu-REOP-24-25", "Groupe-$(gr)", "KIRO-$instName-sol_$(gr).json"),
        )
        allSol[gr] = (is_feasible(instance, sol), compute_cost(instance, sol))
        println("Groupe $(gr) : $(allSol[gr])")
        if !is_feasible(instance, sol)
            sol2 = Solution(instance, sol.entries)
            println(
                "Solution not feasible, correction proposed : $((is_feasible(instance, sol2), compute_cost(instance, sol2)))",
            )
        end
    end
    # return allSol
end

function test_group(n::Int)
    for instanceName in ["small_1", "small_2", "medium_1", "medium_2", "large_1", "large_2"]
        instance = read_instance(joinpath("data", "$(instanceName).json"))
        instName = replace(instance.name, '_' => '-')
        sol = read_solution(
            instance,
            joinpath("Rendu-REOP-24-25", "Groupe-$n", "KIRO-$instName-sol_$n.json"),
        )
        println(
            "Instance $instName : $((is_feasible(instance, sol), compute_cost(instance, sol)))",
        )
        if !is_feasible(instance, sol)
            sol2 = Solution(instance, sol.entries)
            println(
                "Solution not feasible, correction proposed : $((is_feasible(instance, sol2), compute_cost(instance, sol2)))",
            )
        end
    end
end