## Miscellaneous functions

# Function to check dataset columns with missing values
function safe_mean(x)
    if sum(ismissing, x) == length(x)
        missing
    else
        mean(skipmissing(x))
    end
end

# Function to compute the quarter numerically
function calc_diff(dataframe, time_column::Symbol)
    # Base date
    base_date = Date(1960, 1, 1)
    # month to quarter conversion
    month_to_quarter(month) = begin
        if month <= 3
            1
        elseif month <= 6
            2
        elseif month <= 9
            3
        else
            4
        end
    end
    # Calculate the difference 
    quarters_diff = (year.(dataframe[!, time_column]) .- year(base_date)) .* 4 .+
                          (month_to_quarter.(month.(dataframe[!, time_column])) .- 1)
    return quarters_diff
end