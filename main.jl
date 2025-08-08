using Images, FileIO, ColorSchemes, Colors

MAX_ITERATION = 1000
POINTS = []
WIDTH = 4000
HEIGHT = 4000
c = complex(0.345, 0.08)

# -------------------- JULIA SET -----------------------------

function polynomial(z, c)
    return z^2 + c
end

function julia_set_iterations(z, c)
    curr_z = z
    for n in 1:MAX_ITERATION
        if abs(curr_z) > 2
            return n - log2(log2(abs(curr_z)))
        end
        curr_z = polynomial(curr_z, c)
    end
    return MAX_ITERATION
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

function calculate_task!(data, pixels)
    for (x, y) in pixels
        zx = 6 * (x - WIDTH/2) / WIDTH      # [-3, 3]
        zy = 6 * (y - HEIGHT/2) / HEIGHT    # [-3, 3]
        z = complex(zx / 2, zy / 2)
        ite = julia_set_iterations(z, c)
        data[x,y] = ite
    end
end

function calculate_set()
    data = zeros(Float64, WIDTH, HEIGHT)
    pixels = [(x, y) for x in 1:WIDTH for y in 1:HEIGHT]
    chunks = Iterators.partition(pixels, Int(length(pixels) / Threads.nthreads()))
    tasks = map(chunks) do chunk
        Threads.@spawn calculate_task!(data, chunk)
    end
    fetch.(tasks)
    data
end

# -------------------- RUN -----------------------------

start_time = time()

# Set calculation and cleaning
set = calculate_set()
normalized_set = normalize(set')
colored_image = apply_colormap(normalized_set, x -> get(ColorSchemes.viridis, x))

# Image saving
save("julia.png", colored_image)
end_time = time()

elapsed = end_time - start_time
println("Elapsed time: $(elapsed) seconds")
