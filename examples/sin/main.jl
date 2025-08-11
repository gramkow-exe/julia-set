include("../../julia.jl")

function polynomial(z, c)
    return c * sin(z)
end

julia_set = JuliaSet(
    c = complex(0.984808, 0.173648),
    max_ite = 50,
    max_module = 50,
    polynomial = polynomial,
    plan_range = 30
)

julia(julia_set)
