## Running regressions

using Pkg
Pkg.add("FixedEffectModels")
Pkg.add("GLM")
Pkg.add("CategoricalArrays")

using DataFrames
using CSV
using FixedEffectModels
using GLM
using CategoricalArrays
using Dates 

df = CSV.read("data/clean/data_cleaned.csv", DataFrame)

## TABLE 1

df.mex_frac_55 = ifelse.(df.Year .== 1955, df.Mexican ./ (df.Mexican .+ df.NonMexican), missing)
# Collapse by State 
collapsed_df = combine(groupby(df, :State), :mex_frac_55 => (x -> mean(skipmissing(x))) => :m_mex_frac_55)
collapsed_df.m_mex_frac_55 .= ifelse.(isnan.(collapsed_df.m_mex_frac_55), missing, collapsed_df.m_mex_frac_55)
sort!(collapsed_df, :State)
CSV.write("Data/clean/merge_util.csv", collapsed_df)  

dfm = CSV.read("Data/clean/merge_util.csv", DataFrame)
df2 = leftjoin(df, dfm, on=:State)

df2.post = df2.Year .>= 1965                # Create 'post' column
df2.treatment_frac = df2.post .* df2.m_mex_frac_55  # Create 'treatment_frac' column

df2.post_2 = df2.Year .>= 1962              # Create 'post_2' column
df2.treatment_frac_2 = df2.post_2 .* df2.m_mex_frac_55  # Create 'treatment_frac_2' column

df3 = filter(:quarterly_flag => identity, df2) # Quarterly data only

df3.time_q_plus = df3[!, :time_q] .+ 100
df3.time_q_plus = categorical(df3.time_q_plus)

model = reg(df3, 
            @formula(realwage_hourly ~  treatment_frac + fe(time_q_plus)), 
            Vcov.cluster(:State_FIPS))