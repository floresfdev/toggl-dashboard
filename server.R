library(shiny)
library(shinydashboard)
library(data.table)
library(tidyverse)
library(lubridate)
library(forcats)

server <- function(input, output) {
    # ---
    # Helper functions
    
    ## Takes a numeric value and return as a formatted time
    format_time <- function(value, time_unit = "hours") {
        if (time_unit == "hours") {
            value_whole <- floor(value)
            value_decimal <- floor((value - value_whole) * 100)
            value_formatted <- 
                paste0(value_whole, ":", round(value_decimal * 60 / 100))
        }
        
        value_formatted
    }
    
    
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
    # Filter data by client and project
    by_project <-
        time_entries %>%
        mutate(client_project = 
                   paste0(
                       ifelse(client == "", "Without client", client), 
                       " / ", 
                       project)) %>% 
        group_by(client_project) %>% 
        summarize(n = n(),
                  sum_duration_secs = sum(duration_secs),
                  sum_duration_mins = sum_duration_secs / 60,
                  sum_duration_hours = sum_duration_mins / 60)

    
    # ---
    # Filter data by client
    by_client <-
        time_entries %>%
        group_by(client) %>% 
        summarize(n = n(),
                  sum_duration_secs = sum(duration_secs),
                  sum_duration_mins = sum_duration_secs / 60,
                  sum_duration_hours = sum_duration_mins / 60)
    
    
    # ---
    # Output: Plot by project
    output$plotByProject <-
        renderPlot({
            by_project %>% 
                ggplot() +
                geom_bar(aes(x = fct_reorder(client_project, sum_duration_hours),
                             y = sum_duration_hours,
                             fill = client_project),
                         stat = "identity") +
                labs(x = "Project",
                     y = "Hours") +
                coord_flip() +
                guides(fill = FALSE) +
                theme_minimal()
        })
    
    # ---
    # Output: # of clients
    output$clientsBox <-
        renderValueBox({
            value_clients <- nrow(by_client)
            valueBox(value_clients, 
                     ifelse(value_clients == 1, "Client", "Clients"), 
                     icon = icon("building"))
        })
    
    
    # ---
    # Output: # of projects
    output$projectsBox <-
        renderValueBox({
            value_projects <- nrow(by_project)
            valueBox(value_projects, 
                     ifelse(value_projects == 1, "Project", "Projects"), 
                     icon = icon("tasks"))
        })
    
    
    # ---
    # Output: # of tracked hours
    output$hoursBox <-
        renderValueBox({
            valueBox(format_time(round(sum(by_project$sum_duration_hours), 
                                       digits = 2), 
                                 "hours"), 
                     "Hours tracked", 
                     icon = icon("clock-o"))
        })
    
    
}