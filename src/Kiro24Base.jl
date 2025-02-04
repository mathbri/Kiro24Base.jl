module Kiro24Base

# Packages used
using JSON
using Random
using IterTools

# Structures
include("LotChange.jl")
include("RollingWindow.jl")
include("BatchSize.jl")
include("Shop.jl")
include("Vehicle.jl")
include("Instance.jl")
include("Solution.jl")

# Functions
include("utils.jl")
include("feasible.jl")

# Exports
export BatchSize, is_a_batch, batch_size_cost
export LotChange, lot_change_cost
export RollingWindow, rolling_window_cost
export Shop, shop_cost, delay_cost
export Vehicle
export Instance, read_instance
export Solution, compute_cost, read_solution, write_solution
export two_tone_permute!, paint_shop_exit_sequence
export check_position_range,
    check_position_unicity,
    check_sequence_equality,
    check_paint_shop_requirements,
    is_feasible
export test_all_groups_sol, test_group

end
