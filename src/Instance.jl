# Instance structure for KIRO24

struct Instance
    # Name of the instance
    name::String
    # Vector of shops, in the order they have to be visited
    shops::Vector{Shop}
    # General parameters
    twoToneDelta::Int
    # Vector of vehicles
    vehicles::Vector{Vehicle}
end

function Instance(name::String, twoToneDelta::Int)
    return Instance(name, Shop[], twoToneDelta, Vehicle[])
end

function Instance(name::String, parameterDict::Dict{String,Any})
    return Instance(name, parameterDict["two_tone_delta"])
end

function Base.show(io::IO, instance::Instance)
    println(io, "Instance(name = $(instance.name),")
    println(io, "two-tone delta = $(instance.twoToneDelta),")
    println(
        io, "vehicles ($(length(instance.vehicles))) = [$(join(instance.vehicles, ","))],"
    )
    println(io, "shops = [$(join(instance.shops, ",\n"))],")
    return print(io, ")")
end

function read_instance(instance_file::String; verbose::Bool=false)
    # Reading the solution file
    println("Reading solution file $(instance_file)")
    # No indication of type here as Union{String, Int, Vector{Int}, Vector{Vector{Int}}} is equivalent performance-wise
    instanceDict = JSON.parsefile(instance_file)
    # Creating an base instance with thr provided parameters
    name = string(split(basename(instance_file), '.')[1])
    verbose && println("Instance name : $(name)")
    instance = Instance(name, instanceDict["parameters"])
    verbose && println("Instance two-tone delta : $(instance.twoToneDelta)")
    # Completing the instance with the different structures
    verbose && println("Instance vehicles : $(length(instanceDict["vehicles"]))")
    for vehicleDict in instanceDict["vehicles"]
        # Creating one vehicle per dict 
        vehicle = Vehicle(vehicleDict["id"], vehicleDict["type"] == "two-tone")
        # Adding the vehicle to the instance
        push!(instance.vehicles, vehicle)
    end
    verbose && println(instance.vehicles)
    verbose && println("Instance shops : $(length(instanceDict["shops"]))")
    for shopDict in instanceDict["shops"]
        # Creating one shop per dict 
        shop = Shop(
            shopDict["name"],
            shopDict["name"] == "paint",
            shopDict["resequencing_lag"],
            instanceDict["parameters"]["resequencing_cost"],
        )
        # Adding the shop to the instance
        push!(instance.shops, shop)
    end
    verbose && println(instance.shops)
    verbose && println("Instance constraints : $(length(instanceDict["constraints"]))")
    for constraintDict in instanceDict["constraints"]
        # Getting the shop concerned
        shopIdx = findfirst(shop -> shop.name == constraintDict["shop"], instance.shops)
        shop = instance.shops[shopIdx]
        # Creating one object per dict, differing by the type
        if constraintDict["type"] == "batch_size"
            batchSize = BatchSize(constraintDict)
            push!(shop.batchSizes, batchSize)
        elseif constraintDict["type"] == "lot_change"
            lotChange = LotChange(constraintDict)
            # Checking partition 
            allV = sort(vcat(lotChange.partition...))
            allVU = unique(vcat(lotChange.partition...))
            if length(allVU) != length(instance.vehicles) ||
                length(allV) != length(instance.vehicles)
                println("length(allVU) : $(length(allVU))")
                println("length(allV) : $(length(allV))")
                println("N vehicles : $(length(instance.vehicles))")
                println(allV)
                missingVehicles = Int[]
                for i in 1:(length(allV) - 1)
                    if allV[i] + 1 < allV[i + 1]
                        append!(missingVehicles, (allV[i] + 1):(allV[i + 1] - 1))
                    end
                end
                println("Missing vehicles : $missingVehicles")
                duplicatedVehicles = Int[]
                for i in 1:(length(allV) - 1)
                    if allV[i] == allV[i + 1]
                        push!(duplicatedVehicles, allV[i])
                    end
                end
                println("Duplicated vehicles : $duplicatedVehicles")
                @warn "Lot change $(lotChange.id) is not valid : $(lotChange.partition) does not partition vehicles"
            else
                push!(shop.lotChanges, lotChange)
            end
        elseif constraintDict["type"] == "rolling_window"
            rollingWindow = RollingWindow(constraintDict)
            if rollingWindow.windowSize > length(instance.vehicles)
                @warn "Rolling window $(rollingWindow.id) is not valid : window size $(rollingWindow.windowSize) is greater than number of vehicles $(length(instance.vehicles))"
            elseif length(rollingWindow.vehicles) == 0
                @warn "Rolling window $(rollingWindow.id) is not valid : no vehicle in the rolling window"
            end
            push!(shop.rollingWindows, rollingWindow)
        end
    end
    verbose && println(instance.shops)
    return instance
end
