# BatchSize structure for the batch size constraint inside a shop 

struct BatchSize
    id::Int
    cost::Float64
    minBatchSize::Int
    maxBatchSize::Int
    vehicles::Vector{Int}
end

function BatchSize(constraintDict::Dict{String,Any})
    return BatchSize(
        constraintDict["id"],
        constraintDict["cost"],
        constraintDict["min_vehicles"],
        constraintDict["max_vehicles"],
        constraintDict["vehicles"],
    )
end

function Base.show(io::IO, batchSize::BatchSize)
    return print(
        io,
        "BatchSize(id=$(batchSize.id), cost=$(batchSize.cost), min_size=$(batchSize.minBatchSize), max_size=$(batchSize.maxBatchSize), vehicles=$(batchSize.vehicles))",
    )
end

# Checking if the subsequence extracted is a batch
function is_a_batch(
    batchSize::BatchSize, sequence::Vector{Int}, batchStartIdx::Int, batchEndIdx::Int
)
    # idx before not in batch 
    beforeNotIn = batchStartIdx == 1 || !(sequence[batchStartIdx - 1] in batchSize.vehicles)
    # idx inside in batch
    insideIn = all(v -> v in batchSize.vehicles, sequence[batchStartIdx:batchEndIdx])
    # idx after not in batch
    afterNotIn =
        batchEndIdx == length(sequence) ||
        !(sequence[batchEndIdx + 1] in batchSize.vehicles)
    return beforeNotIn && insideIn && afterNotIn
end

# Cost of batch constraints in the shop given for the sequence given
function batch_size_cost(batchSize::BatchSize, sequence::Vector{Int})
    cost = 0.0
    # For each possible batch starting index
    for batchStartIdx in 1:(length(sequence) - 1)
        # For each possible batch ending index
        for batchEndIdx in batchStartIdx:length(sequence)
            # Checking if the subsequence extracted is a batch
            if is_a_batch(batchSize, sequence, batchStartIdx, batchEndIdx)
                # Computing the size of the batch
                size = batchEndIdx - batchStartIdx + 1
                # Computing the deviation of the batch size from the constraint prescription
                sizeDeviation = max(
                    0, size - batchSize.maxBatchSize, batchSize.minBatchSize - size
                )
                # Adding the cost
                cost += batchSize.cost * (sizeDeviation^2)
            end
        end
    end
    return cost
end
