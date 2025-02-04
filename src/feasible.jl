# Functions used to check feasibility of a solution

function check_position_range(sequence::Vector{Int}, nVehicles::Int; verbose::Bool=false)
    # The sequence integers are between 1 and the number of vehicles
    if minimum(sequence) < 1 || maximum(sequence) > nVehicles
        verbose &&
            @warn "The sequence is not valid : $sequence (elements must be between 1 and $nVehicles)"
        return false
    end
    return true
end

function check_position_unicity(sequence::Vector{Int}; verbose::Bool=false)
    # The sequence must be composed of unique intergers
    if length(unique(sequence)) != length(sequence)
        verbose && @warn "The sequence is not valid : $sequence (elements must be unique)"
        uniques = unique(sequence)
        notUniques = Int[]
        for n in uniques
            if length(findall(sequence .== n)) > 1
                push!(notUniques, n)
            end
        end
        verbose && @warn "Duplicate elements : $notUniques"
        return false
    end
    return true
end

function check_sequence_equality(entry::Vector{Int}, exit::Vector{Int}; verbose::Bool=false)
    # The entry and exit sequence must be the same
    if entry != exit
        verbose &&
            @warn "The entry and exit sequences are not valid : $(entry) != $(exit) (sequences must be the same)"
        verbose &&
            @warn "Entry and exit sequence differs at idxs $(findall(entry .!= exit))"
        return false
    end
    return true
end

function check_paint_shop_requirements(
    instance::Instance, entry::Vector{Int}, exit::Vector{Int}; verbose::Bool=false
)
    # Computing it from scratch
    verifExit = paint_shop_exit_sequence(instance, entry; verbose=false)
    # Comparing to the exit sequence given
    if verifExit != exit
        verbose &&
            @warn "The entry and exit sequences don't match paint shop requirements : $(exit) != $(verifExit)"
        return false
    end
    return true
end

# Checks if the solution is feasible
function is_feasible(instance::Instance, solution::Solution; verbose::Bool=false)
    # For each shop, verifying that the entry and exit sequences are valid
    for s in 1:length(instance.shops)
        # println("Checking shop $(instance.shops[s].name)")
        entry = solution.entries[:, s]
        exit = solution.exits[:, s]
        nVehicles = length(instance.vehicles)
        # The entry and exit sequence must be between 1 and the number of vehicles
        check_position_range(entry, nVehicles; verbose=verbose) || return false
        check_position_range(exit, nVehicles; verbose=verbose) || return false
        # The entry and exit sequence must be composed of unique intergers
        check_position_unicity(entry; verbose=verbose) || return false
        check_position_unicity(exit; verbose=verbose) || return false
        # The sequence respect the shops inner changes
        # If the shop is not a paint shop, entry and exit must be the same
        if !instance.shops[s].isPaint
            check_sequence_equality(entry, exit; verbose=verbose) || return false
        else
            # If the shop is a paint shop, entry and exit must respect two tone delta 
            check_paint_shop_requirements(instance, entry, exit; verbose=verbose) ||
                return false
        end
    end
    return true
end