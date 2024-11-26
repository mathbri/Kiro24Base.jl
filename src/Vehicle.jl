# Vehicle structure for KIRO24

struct Vehicle
    # Id of the vehicle
    id::Int
    # Type of the vehicle : regular or two-tone
    twoTone::Bool
end

function Base.show(io::IO, v::Vehicle)
    return print(io, "Vehicle(id=$(v.id), type=$(v.twoTone ? "two-tone" : "regular"))")
end