# Utils functions

# Apply the two-tone permutation defined by twoToneDelta for the vehicle at position idx in the sequence
function two_tone_permute!(
    sequence::Vector{Int}, idx::Int, twoToneDelta::Int; verbose::Bool=false
)
    vehicleDelta = min(twoToneDelta, length(sequence) - idx)
    # If there is no delta to apply, returning the identity
    vehicleDelta == 0 && return nothing
    # Otherwise, applying the permutation
    verbose && print("\t", sequence[idx:(idx + vehicleDelta)], " became ")
    twoToneId = sequence[idx]
    sequence[idx:(idx + vehicleDelta - 1)] = sequence[(idx + 1):(idx + vehicleDelta)]
    sequence[idx + vehicleDelta] = twoToneId
    return verbose && println(sequence[idx:(idx + vehicleDelta)])
end

# Computes the paint shop exit sequence given the entry sequence
function paint_shop_exit_sequence(
    instance::Instance, sequence::Vector{Int}; verbose::Bool=false
)
    EXIT = deepcopy(sequence)
    verbose && println("Before permute : \n", EXIT)
    # Boolean vector to keep track of vehicle on which to apply perturbation
    applyPermute = map(v -> v.twoTone, instance.vehicles)
    verbose && println(
        "Vehicles to permute : ", [vId for vId in sequence if applyPermute[vId]], "\n"
    )
    idx = 1
    while any(applyPermute)
        # If the current vehicle is two-tone delta and has not yet been permuted, applying
        vId = EXIT[idx]
        if applyPermute[vId]
            verbose && println("\nIdx $idx : Permuting vehicle $vId")
            two_tone_permute!(EXIT, idx, instance.twoToneDelta; verbose=verbose)
            # Putting apply to false 
            applyPermute[vId] = false
            # Not updating index as the vId at the current idx changed
            verbose && println("\tUpdated exit sequence : ")
            verbose && println("\t", EXIT, "\n")
        else
            if instance.vehicles[vId].twoTone
                verbose &&
                    println("Idx $idx : Two-tone vehicle $vId has already been permuted")
            else
                verbose && println("Idx $idx : Vehicle $vId is not a two-tone vehicle")
            end
            idx = idx + 1
        end
    end
    return EXIT
end

# Construct an admissible solution with the entries
function Solution(instance::Instance, entries::Matrix{Int})
    if size(entries) != (length(instance.vehicles), length(instance.shops))
        @warn "entries must be a $(length(instance.vehicles)) x $(length(instance.shops)) matrix"
    end
    # Initializing the solution
    exits = zeros(Int, length(instance.vehicles), length(instance.shops))
    for s in 1:length(instance.shops)
        # The exit sequence depends on the type of shop
        exits[:, s] = if instance.shops[s].isPaint
            paint_shop_exit_sequence(instance, entries[:, s])
        else
            entries[:, s]
        end
    end
    return Solution(entries, exits)
end