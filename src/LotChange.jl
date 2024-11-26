# LotChange structure for the lot change constraint inside a shop 

struct LotChange
    id::Int
    cost::Float64
    partition::Vector{Vector{Int}}
end

function LotChange(constraintDict::Dict{String,Any})
    return LotChange(
        constraintDict["id"], constraintDict["cost"], constraintDict["partition"]
    )
end

function Base.show(io::IO, lotChange::LotChange)
    return print(
        io,
        "LotChange(id=$(lotChange.id), cost=$(lotChange.cost), partition=$(lotChange.partition))",
    )
end

function lot_change_cost(lotChange::LotChange, sequence::Vector{Int})
    cost = 0.0
    # For each position in the sequence
    for vIdx in 1:(length(sequence) - 1)
        # Getting the lot of the current vehicle
        v = sequence[vIdx]
        currentLot = findfirst(lot -> v in lot, lotChange.partition)
        # Getting the lot of the next vehicle
        nextV = sequence[vIdx + 1]
        nextLot = findfirst(lot -> nextV in lot, lotChange.partition)
        # Checking if they are different, adding cost if they are
        cost += currentLot != nextLot ? lotChange.cost : 0
    end
    return cost
end