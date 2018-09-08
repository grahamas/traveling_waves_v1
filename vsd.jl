using MAT
using StatsBase
using Plots; pyplot()
PyPlot.using3D()

function animate_trial_contour(trial::Array{Float64,3})
    mn = -5; mx = 5
    anim = @animate for i = 1:66
        heatmap(trial[:,:,i], zlims=(mn,mx), clims=(mn,mx))
    end
    return anim
end

function zero_outliers!(arr::A, threshold::N=1.0) where {A<:Array, N<:Number}
    arr[abs.(arr) .> threshold] .= 0
    return arr
end

function remove_semicircle(arr::Array{Float64,N}, width=3)::Array{Float64,N} where {N}
    ny, nx, others = size(arr)
    y, x, others = range.(1, size(arr))
    radius = nx / 2
    semicircle(i_x) = sqrt(radius^2 - (i_x - radius)^2)::Real
    semicircle_coords = [CartesianIndex(i_y, i_x)
        for i_x in x, i_y in y
        if abs(i_y - semicircle(i_x)) < width]
    arr[semicircle_coords,:] .+= 500
    return arr
end

function process_trial(trial::Array{Float64,3})
    trial |>
        remove_semicircle |>
        zscore
end

function visualize_trials(all_trials::Array{Float64,4})
    n_trials = size(all_trials, 4)
    for i_trial in 1:n_trials
        trial = all_trials[:,:,:,i_trial]
        processed_trial = process_trial(trial)
        anim =  animate_trial_contour(processed_trial)
        mp4(anim, "contour_$(i_trial).mp4", fps=7)
    end
end

function test_visualization(all_trials::Array{Float64,4})
    frame = all_trials[:,:,:,1]
    contour(process_trial(frame)[:,:,25])
end
vsd_data = matread("vsd_data.mat")["vsd_data"];
# visualize_trials(vsd_data[:,:,:,1:2])
test_visualization(vsd_data)