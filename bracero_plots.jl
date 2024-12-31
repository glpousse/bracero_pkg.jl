############################### Additional Data Prep/ Cleaning for Plots ############################### 

using Statistics
using Plots

# Semesters of the year 
dfm_2.semester .=1 
dfm_2.semester[dfm_2.Month .>= 7] .= 2
dfm_2.time_h = Date.(dfm_2.Year, (dfm_2.semester .- 1) .* 6 .+ 1, 1)

# Seasons of the year
dfm_2.springsummer = in.(dfm_2.Month, Ref([3, 4, 5, 6, 7]))
dfm_2.fall = in.(dfm_2.Month, Ref([8, 9, 10, 11]))

#Setting up the loop
varlist = [:mex_frac, :Mexican, :domestic_seasonal, :dom_area, :mex_area, :Local_final, :Intrastate_final, :Interstate_final]
rename!(dfm_2, Symbol.(names(dfm_2)))

# WORKS 

sort!(dfm_2, [:State_FIPS, :Year])
grouped_df = groupby(dfm_2, [:State_FIPS, :Year])
dfm_2.mex_frac_spring = dfm_2.mex_frac .* dfm_2.springsummer
dfm_2.mex_frac_fall = dfm_2.mex_frac .* dfm_2.fall


dfm_2 = transform(grouped_df, 
    :mex_frac_fall => (x -> maximum(coalesce.(x, 0.0))) => :fallmax_mex_frac, 
    :mex_frac_spring => (x -> maximum(coalesce.(x, 0.0))) => :springmax_mex_frac,
    :mex_frac => (x -> maximum(coalesce.(x, 0.0))) => :yrmax_mex_frac) 

dfm_2.fallmax_mex_frac = dfm_2.fallmax_mex_frac .* dfm_2.fall
dfm_2.springmax_mex_frac = dfm_2.springmax_mex_frac .* dfm_2.springsummer
select!(dfm_2, Not([:mex_frac_spring, :mex_frac_fall]))
dfm_2[!, Symbol("seamax_mex_frac")] = dfm_2[!, Symbol("springmax_mex_frac")] .+ dfm_2[!, Symbol("fallmax_mex_frac")]

# --------------------------------------------------------------------------------

# MEAN CHECKING 

mean(dfm_2.fallmax_mex_frac[.!ismissing.(dfm_2.fallmax_mex_frac) .& .!isnan.(dfm_2.fallmax_mex_frac)])
a = mean(dfm_2.high[.!ismissing.(dfm_2.high) .& .!isnan.(dfm_2.high)])
b = mean(dfm_2.none[.!ismissing.(dfm_2.none) .& .!isnan.(dfm_2.none)])
c = mean(dfm_2.low[.!ismissing.(dfm_2.low) .& .!isnan.(dfm_2.low)])
a+b+c
mean(dfm_2.seamax_mex_frac_high[.!ismissing.(dfm_2.seamax_mex_frac_high) .& .!isnan.(dfm_2.seamax_mex_frac_high)])

# --------------------------------------------------------------------------------


sort!(dfm_2, [:time_h])
grouped_df2 = groupby(dfm_2, [:time_h])
dfm_2.temp_none = dfm_2.seamax_mex_frac .* dfm_2.none
dfm_2.temp_low = dfm_2.seamax_mex_frac .* dfm_2.low
dfm_2.temp_high = dfm_2.seamax_mex_frac .* dfm_2.high

dfm_2 = transform(grouped_df2,
    :temp_none => (x -> mean(skipmissing(x))) => :seamax_mex_frac_none,
    :temp_low => (x -> mean(skipmissing(x))) => :seamax_mex_frac_low,
    :temp_high => (x -> mean(skipmissing(x))) => :seamax_mex_frac_high)

dfm_2.seamax_mex_frac_none = dfm_2.seamax_mex_frac_none .* dfm_2.none
dfm_2.seamax_mex_frac_low = dfm_2.seamax_mex_frac_low .* dfm_2.low
dfm_2.seamax_mex_frac_high = dfm_2.seamax_mex_frac_high .* dfm_2.high

sort!(dfm_2, [:Year])
grouped_df3 = groupby(dfm_2, [:Year])
dfm_2.temp_none = dfm_2.yrmax_mex_frac .* dfm_2.none
dfm_2.temp_low = dfm_2.yrmax_mex_frac .* dfm_2.low
dfm_2.temp_high = dfm_2.yrmax_mex_frac .* dfm_2.high

dfm_2 = transform(grouped_df3,
    :temp_none => (x -> mean(skipmissing(x))) => :yrmax_mex_frac_none,
    :temp_low => (x -> mean(skipmissing(x))) => :yrmax_mex_frac_low,
    :temp_high => (x -> mean(skipmissing(x))) => :yrmax_mex_frac_high)

dfm_2.yrmax_mex_frac_none = dfm_2.yrmax_mex_frac_none .* dfm_2.none
dfm_2.yrmax_mex_frac_low = dfm_2.yrmax_mex_frac_low .* dfm_2.low
dfm_2.yrmax_mex_frac_high = dfm_2.yrmax_mex_frac_high .* dfm_2.high

# Second half of code needs debugging. Then need to transform into for loop. 


############################### Figure 2A ############################### 

x = dfm_2.time_h 
y_none = dfm_2.seamax_mex_frac_none  # Data for "none"
y_low = dfm_2.seamax_mex_frac_low    # Data for "low"
y_high = dfm_2.seamax_mex_frac_high  # Data for "high"

# Subset data based on `fulldata`
x_subset = x[dfm_2.fulldata]
y_none_subset = y_none[dfm_2.fulldata]
y_low_subset = y_low[dfm_2.fulldata]
y_high_subset = y_high[dfm_2.fulldata]

plot(
    x_subset, y_none_subset,
    seriestype = :steppre,        # Stairstep plot
    color = :black,                # Replace with `$color_control`
    linewidth = 1,                # Thin line
    linestyle = :dash,            # Short dash pattern
    label = "No exposure (B/L = 0)") # Legend label

plot!(
    x_subset, y_low_subset,
    seriestype = :steppre,
    color = :grey,               # Replace with `$color_low * 0.66`
    linewidth = 2,                # Medium line
    linestyle = :solid,           # Solid line pattern
    label = "Low exposure (0 < B/L < 0.2)")

plot!(
    x_subset, y_high_subset,
    seriestype = :steppre,
    color = :black,                 # Replace with `$color_high * 0.66`
    linewidth = 2,
    linestyle = :solid,
    label = "High exposure (B/L ≥ 0.2)")

vline!([9.8, 4.7],
    color = :grey,
    linestyle = :dot,
    label = "")

xlabel!("", labelpad = 10)
ylabel!("Average Mexican fraction (season peak)", labelpad = 10)
title!("Panel A. Average Mexican fraction of hired seasonal farm workers, 1954–1972", labelpad = 10)

# Customize ticks and aspect ratio
xticks!(-20:10:20)               # Replace with the appropriate ticks
yticks!(0:0.1:0.5, format = :f) # Y-axis ticks
xlims!(-24, 26)                  # Optional: Limit for x-axis
ylims!(0, 0.5)                   # Optional: Limit for y-axis
aspect_ratio = 0.5               # Aspect ratio

# Customize legend
plot!(
    legend = :topright,
    legendfontsize = 8,
    legendcols = 2,
    legendtitle = "Bracero} fraction (B/L) in 1955:"
)
# Remove plot border

# Save the plot
savefig("dd_mex_frac.pdf") 

############################### Figure 4A ############################### 


Pkg.add("FixedEffectModels")
Pkg.add("GLM")
Pkg.add("BSplines") 

using FixedEffectModels
using GLM 


Pkg.add("MixedModels")
Pkg.add("NonparametricRegression")
using NonparametricRegression
using MixedModels

dfm_2.time_q_plus = dfm_2.time_q .+ 100
dfm_2.time_q_plus_cat = CategoricalVector(dfm_2.time_q_plus)



par_model = fit(MixedModel, @formula(realwage_hourly ~ time_q_plus_cat + ln_Mexican + (1|State_FIPS)), dfm_2)
println(model)

valid_data = dfm_2[.!ismissing.(dfm_2.ln_Mexican) .& .!ismissing.(dfm_2.realwage_hourly), :]
npar_model = npregress(valid_data.ln_Mexican, valid_data.realwage_hourly)
npar_fitted = fitted(npar_model)
dfm_2[:, :npar_mode] = npar_model