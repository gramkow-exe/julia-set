using Images, FileIO, ColorSchemes, Colors

POINTS = []
WIDTH = 4000
HEIGHT = 4000

# -------------------- JULIA SET -----------------------------

# Struct
struct JuliaSet
    c::ComplexF64
    polynomial::Function
    max_ite::Int
    max_module::Float64
    plan_range::Int
end

# Default Parameters
JuliaSet(; c = complex(1,1), polynomial = (z, c) -> z^2 + c, max_ite = 1000, max_module = 2.0, plan_range = 6 ) = JuliaSet(c, polynomial, max_ite, max_module, plan_range)

function julia_set_iterations(z, julia_set)
    curr_z = z
    for n in 1:julia_set.max_ite
        if abs(curr_z) > julia_set.max_module
            return n - log2(log2(abs(curr_z)))
        end
        curr_z = julia_set.polynomial(curr_z, julia_set.c)
    end
    return julia_set.max_ite
end

# -------------------- DATA PROCESSING -----------------------------

function normalize(data)
    min_val = minimum(data)
    max_val = maximum(data)
    return (data .- min_val) ./ (max_val - min_val)
end

function apply_colormap(data, colormap_func)
    height, width = size(data)
    color_img = Array{RGB{N0f8}}(undef, height, width)
    for y in 1:height, x in 1:width
        color_img[y, x] = colormap_func(data[y, x])
    end
    return color_img
end

# -------------------- CALCULATE SET BASED ON PIXELS -----------------------------

function calculate_task!(data, pixels, julia_set)
    for (x, y) in pixels
        zx = julia_set.plan_range * (x - WIDTH/2) / WIDTH      # [-3, 3]
        zy = julia_set.plan_range * (y - HEIGHT/2) / HEIGHT    # [-3, 3]
        z = complex(zx / 2, zy / 2)
        ite = julia_set_iterations(z, julia_set)
        data[x,y] = ite
    end
end

function calculate_set(julia_set)
    data = zeros(Float64, WIDTH, HEIGHT)
    pixels = [(x, y) for x in 1:WIDTH for y in 1:HEIGHT]
    chunks = Iterators.partition(pixels, Int(length(pixels) / Threads.nthreads()))
    tasks = map(chunks) do chunk
        Threads.@spawn calculate_task!(data, chunk, julia_set)
    end
    fetch.(tasks)
    data
end

# -------------------- RUN -----------------------------

function julia(julia_set)
    start_time = time()

    # Set calculation and cleaning
    set = calculate_set(julia_set)
    normalized_set = normalize(set')
    colored_image = apply_colormap(normalized_set, x -> get(ColorSchemes.RdPu, x))

    # Image saving
    save("julia.png", colored_image)
    end_time = time()

    elapsed = end_time - start_time
    println("Elapsed time: $(elapsed) seconds")
end
