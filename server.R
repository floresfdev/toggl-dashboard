library(shiny)
library(shinydashboard)
library(data.table)
library(tidyverse)
library(lubridate)


server <- function(input, output) {
    # ---
    # Settings
    file_name <- "./data/Toggl_time_entries_2017-08-01_to_2017-08-31.csv"
    
    
    # ---
    # Load data
    time_entries <- fread(file_name, encoding = "UTF-8")
    
    
    # ---
    # Preprocess
    time_entries <-
        time_entries %>% 
        rename_all(. %>% 
                       gsub("[(][)]", "", .) %>% 
                       tolower %>% 
                       trimws %>% 
                       gsub(" ", "_", .)) %>% 
        mutate(start = ymd_hms(paste(start_date, start_time)),
               end = ymd_hms(paste(end_date, end_time)),
               duration = hms(duration),
               duration_secs = as.numeric(duration))
    
    
    # ---
    # Output: Plot by project
    output$plotByProject <-
        renderPlot({
            time_entries %>% 
                group_by(project) %>% 
                summarize(n = n(),
                          sum_duration_secs = sum(duration_secs),
                          sum_duration_mins = sum_duration_secs / 60,
                          sum_duration_hours = sum_duration_mins / 60) %>% 
                ggplot() +
                geom_bar(aes(x = fct_reorder(project, sum_duration_hours),
                             y = sum_duration_hours,
                             fill = project),
                         stat = "identity") +
                labs(x = "Project",
                     y = "Hours") +
                coord_flip() +
                guides(fill = FALSE) +
                theme_minimal()
        })
    
}