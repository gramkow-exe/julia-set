include("../../julia.jl")

function polynomial(z, c)
    return z^2 + c
end

julia_set = JuliaSet(
    c = complex(-0.54, 0.54),
    max_ite = 100,
    polynomial = polynomial
)

julia(julia_set)
