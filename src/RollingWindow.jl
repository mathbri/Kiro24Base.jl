# RollingWindow structure for the rolling window constraint inside a shop

struct RollingWindow
    id::Int
    cost::Float64
    windowSize::Int
    maxVehicles::Int
    vehicles::Vector{Int}
end

function RollingWindow(constraintDict::Dict{String,Any})
    return RollingWindow(
        constraintDict["id"],
        constraintDict["cost"],
        constraintDict["window_size"],
        constraintDict["max_vehicles"],
        constraintDict["vehicles"],
    )
end

function Base.show(io::IO, rollingWindow::RollingWindow)
    return print(
        io,
        "RollingWindow(id=$(rollingWindow.id), cost=$(rollingWindow.cost), window_size=$(rollingWindow.windowSize), max_vehicles=$(rollingWindow.maxVehicles), vehicles=$(rollingWindow.vehicles))",
    )
end

function rolling_window_cost(rollingWindow::RollingWindow, sequence::Vector{Int})
    cost = 0.0
    # For each window in the sequence
    for windowSequence in partition(sequence, rollingWindow.windowSize, 1)
        # Counting the number of vehicle concerned by the constraint in the window
        vehicleInWindow = count(v -> v in rollingWindow.vehicles, windowSequence)
        # Computing if this is too much
        overVehicules = max(0, vehicleInWindow - rollingWindow.maxVehicles)
        # Adding the cost
        cost += rollingWindow.cost * (overVehicules^2)
    end
    return cost
end