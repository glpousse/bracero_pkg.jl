# This is code to replicate the outputs from the article "Immigration Restrictions as Active Labor Market Policy:
# Evidence from the Mexican Bracero Exclusion" (2018) by Michael A. Clemens, Ethan G. Lewis, and Hannah M. Postel. 

############################### Setting up Working Directory ###############################

cd("/Users/glpou/GitHub/bracero_pkg") # edit the filepath the corresponding working directory

############################### Packages ###############################

using Pkg
Pkg.add("DataFrames")
Pkg.add("CSV")
Pkg.add("PanelDataTools")

############################### Loading the data ###############################

using DataFrames
using CSV

# REFER BACK TO THIS SECTION FOR DF DEFINITIONS

df1 = CSV.read("data/data_bracero_aer.csv", DataFrame)
df2 = CSV.read("data/data_bracero_outflows_from_mex_gonzalez.csv", DataFrame)
df3 = CSV.read("data/data_cpi.csv", DataFrame)
df4 = CSV.read("data/data_tomatoes_vandermeer_final.csv", DataFrame)
df5 = CSV.read("data/data_total_braceros_by_year.csv", DataFrame)
df6 = CSV.read("data/data_alston_ferrie_votes.csv", DataFrame)

############################### Cleaning the data ############################### 

df1 = sort(df1, [:State, :Year])
df1.Month = Int.(df1.Month) # Making months Integers. 

# Replace Cotton_machine with missing if State is "FL" and Year > 1969 and Cotton_machine == 0, ignoring missing values
df1[(df1.State .== "FL") .& (df1.Year .> 1969) .& (df1.Cotton_machine .== 0) .& .!ismissing.(df1.Cotton_machine), :Cotton_machine] .= missing

# Replace Cotton_machine with missing if State is "VA" and Year > 1965 and Cotton_machine == 0, ignoring missing values
df1[(df1.State .== "VA") .& (df1.Year .> 1965) .& (df1.Cotton_machine .== 0) .& .!ismissing.(df1.Cotton_machine), :Cotton_machine] .= missing

# Generate flags for months 
df1.january = df1.Month .== 1 
df1.april = df1.Month .== 4
df1.july = df1.Month .== 7 
df1.october = df1.Month .== 10

df1.quarterly_flag = [x in [1, 4, 7, 10] for x in df1.Month]

# Initialize the quarter column with missing values
df1.quarter .= 0

# Create the 'quarter' column with default values
df1[!, :quarter][(df1.Month .== 1) .| (df1.Month .== 2) .| (df1.Month .== 3)] .= 1  # Q1
df1[!, :quarter][(df1.Month .== 4) .| (df1.Month .== 5) .| (df1.Month .== 6)] .= 2  # Q2
df1[!, :quarter][(df1.Month .== 7) .| (df1.Month .== 8) .| (df1.Month .== 9)] .= 3  # Q3
df1[!, :quarter][(df1.Month .== 10) .| (df1.Month .== 11) .| (df1.Month .== 12)] .= 4 # Q4

# Time variables
using Dates

# Months
df1.time_m = Date.(string.(df1.Year .* 100 .+ df1.Month), "yyyymm")

# Quarters (Quarter number * 3 s.t. date shows last month of the quarter)
df1.time_q_ = Date.(string.(df1.Year .* 100 .+ (df1.quarter .* 3)), "yyyymm")

# Merge different Mexican series 

df1.Mexican = df1.Mexican_final
df1.ln_Mexican = log.(df1.Mexican_final) 
replace!(df1.ln_Mexican, -Inf => missing) # Getting rid of -Inf values from the zeros in Mexican_final

# Seting up the Panel 

df1 = dropmissing(df1, [:time_m, :State_FIPS])

using PanelDataTools
sort!(df1, [:State_FIPS, :time_m])
paneldf!(df1, :State_FIPS, :time_m)

df1.fulldata = Int.(((df1.Year .>= 1954) .& (df1.Month .>= 7) .| (df1.Year .>= 1955)) .& (df1.Year .<= 1972))

df1.Mexican .= ifelse.(ismissing.(df1.Mexican) .& (df1.fulldata .== 1), 0, df1.Mexican)

# Now the non-Mexican workers 

df1.TotalHiredSeasonal = df1.TotalHiredSeasonal_final 
df1.NonMexican = df1.TotalHiredSeasonal .- df1.Mexican
df1.ln_NonMexican = log.(df1.NonMexican)
df1.ln_HiredWorkersonFarms = log.(df1.HiredWorkersonFarms_final)
df1.mex_frac = df1.Mexican ./ df1.TotalHiredSeasonal
df1.mex_frac_tot = df1.Mexican ./ (df1.Farmworkers_Hired * 1000)

# Merging with the CPI data 

# Reformatting dates in CPI data 
using Dates
df3.time_m .= Date("1960-01-01") .+ Month.(Int.(df3.time_m))

# The merge
df1 = leftjoin(df1, df3, on = [:State_FIPS, :time_m])

# Generating new vars 
df1.priceadjust = df1.cpi ./ 0.1966401  # Divide by value of index in January 1965
df1.realwage_daily = df1.DailywoBoard_final ./ df1.priceadjust
df1.realwage_hourly = df1.HourlyComposite_final ./ df1.priceadjust

# Generating Employment Data 
df1 = sort(df1, [:State, :time_m])

df1.domestic_seasonal = sum.(eachrow(df1[:, [:Local_final, :Intrastate_final, :Interstate_final]]))
df1.ln_domestic_seasonal = log.(df1.domestic_seasonal)
df1.ln_foreign = log.(df1.TotalForeign_final)
df1.dom_frac = df1.domestic_seasonal ./ df1.TotalHiredSeasonal_final
df1.for_frac = df1.TotalForeign_final ./ df1.TotalHiredSeasonal_final
df1.ln_local = log.(df1.Local_final)
df1.ln_intrastate = log.(df1.Intrastate_final)
df1.ln_interstate = log.(df1.Interstate_final)

df1.domestic_seasonal[(df1.Year .< 1954) .| (df1.Year .> 1973) .| (df1.Year .== 1973 .& df1.Month .> 7)] .= missing
df1.ln_domestic_seasonal[(df1.Year .< 1954) .| (df1.Year .> 1973) .| (df1.Year .== 1973 .& df1.Month .> 7)] .= missing

# Normalizing by, respectively, data from the latest Census of Agriculture before 1955 and latest Census of Population before 1955:

df1.mex_area = df1.Mexican ./ (df1.cropland_1954/1000)
df1.dom_area = df1.domestic_seasonal ./ (df1.cropland_1954/1000)
df1.mex_pop = df1.Mexican ./ (df1.pop1950/1000)
df1.dom_pop = df1.domestic_seasonal ./ (df1.pop1950/1000)

df1.Farmworkers_Hired_pop = (df1.Farmworkers_Hired * 1000) ./ (df1.pop1950 / 1000)
df1.Farmworkers_Hired_area = (df1.Farmworkers_Hired * 1000) ./ (df1.cropland_1954 / 1000)

# Getting rid of any -Inf values in df1 caused by taking ln(0)
columns_with_neg_inf = [] 

for col in names(df1)
    if any(coalesce.(df1[!, col], Inf) .== -Inf)
        push!(columns_with_neg_inf, string(col)) 
    end
end

println("Columns with -Inf values: ", columns_with_neg_inf)

# Need to allow the above columns to admit missing values

for col in columns_with_neg_inf
    df1[!, col] = convert(Vector{Union{eltype(df1[!, col]), Missing}}, df1[!, col])
end

# Finally switching out the -Inf 

for col in columns_with_neg_inf
    indices_neg_inf = findall(x -> x == -Inf, skipmissing(df1[!, col]))
    df1[!, col][indices_neg_inf] .= missing
end

############################### Analysis ############################### 