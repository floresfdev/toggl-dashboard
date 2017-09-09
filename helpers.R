# ========================================
# General settings
# ========================================

# ---
# Set locale
Sys.setlocale("LC_ALL", "C")



# ========================================
# Helper functions
# ========================================

# ---
# Takes a numeric value and return as a formatted time
format_time <- function(value, time_unit = "hours") {
    if (time_unit == "hours") {
        value_whole <- floor(value)
        value_decimal <- floor((value - value_whole) * 100)
        value_formatted <- 
            paste0(value_whole, ":", round(value_decimal * 60 / 100))
    } else {
        ## Other formats not needed yet. Return the same input value
        value_formatted <- value
    }
    
    value_formatted
}