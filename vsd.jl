using Lazy
using MAT, SparseArrays
using StatsBase, LinearAlgebra
using Memoize, IterTools
using ImageFiltering
using Plots; pyplot()
PyPlot.using3D()

function animate_trial(trial::Array{Float64,3}, plot_fn)
    mn = minimum(filter(!isnan, trial)); mx = maximum(filter(!isnan, trial))
    anim = @animate for i_time = 1:size(trial,3)
        plot_fn(trial[:,:,i_time], zlims=(mn,mx), clims=(mn,mx))
    end
    return anim
end

function snip_row(row::BitArray{1}, snip_width::Int)
    @assert row[1] == false & row[end] == false
    switches = xor.(row[1:end-1], row[2:end])
    if sum(switches) < 2
        return
    end
    first_edge::Int = findfirst(switches)
    last_edge::Int = findlast(switches)
    row[1:first_edge+snip_width-1] .= false
    row[first_edge+snip_width:last_edge-snip_width] .= true
    row[last_edge-snip_width+1:end] .= false
    return row
end

function widen_edge_mask!(arr::BitArray{2}, snip_width::Int, snip_height::Int)
    rows_to_kill = snip_height
    for i_row in size(arr,1):-1:1
        # First trim off top
        if rows_to_kill > 0 # if still need to kill rows
            if !all(arr[i_row,:] .== false) # if row has interior
                arr[i_row,:] .= false # then kill entire row
                rows_to_kill -= 1 # one less row left to kill
            end
        else
            # then trim edges of remainder
            arr[i_row,:] .= snip_row(arr[i_row,:],snip_width)
        end
    end
end

function remove_semicircle(arr::Array{Float64,3}, snip_width, snip_height)
    interior_mask = .!dropdims(all(arr .== 0, dims=3), dims=3) # ! means true means interior
    widen_edge_mask!(interior_mask, snip_width, snip_height)
    interior_mask = repeat(interior_mask, outer=(1,1,size(arr,3)))
    retarr = similar(arr)
    fill!(retarr, NaN)
    retarr[interior_mask] .= arr[interior_mask]
    return retarr
end

function smooth_trial(arr::Array{Float64,3})
    retarr = similar(arr)
    for i_time in 1:size(arr,3)
        retarr[:,:,i_time] .= imfilter(arr[:,:,i_time], Kernel.gaussian(4))
    end
    return retarr
end

function zscore_trial(arr::Array{Float64,3})
    retarr = similar(arr)
    fill!(retarr, NaN)
    retarr[.!isnan.(arr)] .= zscore(arr[.!isnan.(arr)])
    return retarr
end

function process_trial(trial::Array{Float64,3}, snip_width, snip_height)
    @> trial begin
        remove_semicircle(snip_width, snip_height)
        smooth_trial
        zscore_trial
    end
end

function visualize_trials(all_trials::Array{Float64,4}; snip_width=5, snip_height=5, plot_fn=heatmap, name_prefix="")
    n_trials = size(all_trials, 4)
    for i_trial in 1:n_trials
        @> all_trials[:,:,:,i_trial] begin
            process_trial(snip_width, snip_height)
            animate_trial(plot_fn)
            mp4("$(name_prefix)_$(string(plot_fn))_$(i_trial).mp4", fps=7)
        end
    end
end

function test_visualization(all_trials::Array{Float64,4})
    trial = all_trials[:,:,:,1]
    process_trial!(trial)
    contour(trial[:,:,25])
end
# vsd_data = matread("vsd_data.mat")["vsd_data"];
# # visualize_trials(vsd_data[:,:,:,1:2])
# test_visualization(vsd_data)