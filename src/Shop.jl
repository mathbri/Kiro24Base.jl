# Shop structure for KIRO24

struct Shop
    # Name of the shop
    name::String
    # Is the shop a paint shop ?
    isPaint::Bool
    # Lag of resequencing (ie free space in the rack after the shop)
    resequencingLag::Int
    resequencingCost::Float64
    # Cost constraints : soft constraints inducing cost in this shop
    batchSizes::Vector{BatchSize}
    lotChanges::Vector{LotChange}
    rollingWindows::Vector{RollingWindow}
end

function Shop(name, isPaint, resequencingLag, resequencingCost)
    return Shop(
        name,
        isPaint,
        resequencingLag,
        resequencingCost,
        BatchSize[],
        LotChange[],
        RollingWindow[],
    )
end

function Base.show(io::IO, shop::Shop)
    println(io, "Shop(name = $(shop.name),")
    println(io, "\tisPaint = $(shop.isPaint),")
    println(io, "\tresequencingLag = $(shop.resequencingLag),")
    println(io, "\tresequencingCost = $(shop.resequencingCost),")
    println(
        io, "\tbatchSizes ($(length(shop.batchSizes))) = [$(join(shop.batchSizes, ","))],"
    )
    println(
        io, "\tlotChanges ($(length(shop.lotChanges))) = [$(join(shop.lotChanges, ","))],"
    )
    println(
        io,
        "\trollingWindows ($(length(shop.rollingWindows))) = [$(join(shop.rollingWindows, ","))]",
    )
    return print(io, ")")
end

# Cost incurred in the shop for the sequence given
function shop_cost(shop::Shop, sequence::Vector{Int}; verbose::Bool=false)
    shopCost = 0.0
    # Iterating all lot change constraints
    for lotChange in shop.lotChanges
        shopCost += lot_change_cost(lotChange, sequence)
    end
    lotChangeCost = shopCost
    verbose && println("Lot change costs : $lotChangeCost")
    # Iterating all rolling window constraints
    for rollingWindow in shop.rollingWindows
        shopCost += rolling_window_cost(rollingWindow, sequence)
    end
    rollingWindowCost = shopCost - lotChangeCost
    verbose && println("Rolling window costs : $rollingWindowCost")
    # Iterating all batch size constraints
    for batchSize in shop.batchSizes
        shopCost += batch_size_cost(batchSize, sequence)
    end
    batchSizeCost = shopCost - rollingWindowCost - lotChangeCost
    verbose && println("Batch size costs : $batchSizeCost")
    verbose && println("Shop cost : $shopCost")
    return shopCost
end

# Cost of the delay incrred by having sequence in the shop and nextSequence in the next shop 
function delay_cost(shop::Shop, sequence::Vector{Int}, nextSequence::Vector{Int})
    delayCost = 0.0
    for exitPos in eachindex(sequence)
        vId = sequence[exitPos]
        # println("Exit position for vehicle $v : $exitPos")
        nextEntryPos = findfirst(isequal(vId), nextSequence)
        # println("Next entry position for vehicle $v : $nextEntryPos")
        delay = max(0, exitPos - nextEntryPos - shop.resequencingLag)
        # println("Delay for vehicle $v : $delay")
        delayCost += shop.resequencingCost * delay
    end
    return delayCost
end