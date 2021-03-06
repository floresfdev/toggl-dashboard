library(shiny)
library(shinydashboard)
library(data.table)
library(tidyverse)
library(lubridate)
library(forcats)
library(reshape2)
library(stringr)
library(padr)
library(DT)

# ---
# Helper functions and resources
source("helpers.R")


server <- function(input, output) {
    # ========================================
    # General
    # ========================================

    # ---
    # Name of the file exported from Toggl
    file_name <- "./data/Toggl_time_entries_2017-08-01_to_2017-08-31.csv"
    
    
    # ---
    # Load data
    time_entries_raw <- fread(file_name, encoding = "UTF-8")
    
    
    # ---
    # Preprocess:
    # - Fix column names
    # - Create labels for clients and projects
    # - Convert dates
    # - Compute duration of time entries in seconds
    time_entries <-
        time_entries_raw %>% 
        rename_all(. %>% 
                       gsub("[(][)]", "", .) %>% 
                       tolower %>% 
                       trimws %>% 
                       gsub(" ", "_", .)) %>% 
        mutate(client_label = ifelse(is.na(client), "(no client)", client),
               project_label = ifelse(is.na(project), "(no project)", project),
               client_project = paste(client_label, "/", project_label),
               start = ymd_hms(paste(start_date, start_time)),
               end = ymd_hms(paste(end_date, end_time)),
               duration = hms(duration),
               duration_secs = as.numeric(duration))
    
    
    # ---
    # Group data by client and project
    by_project <-
        time_entries %>%
        group_by(client_project) %>% 
        summarize(n = n(),
                  sum_duration_secs = sum(duration_secs),
                  sum_duration_mins = sum_duration_secs / 60,
                  sum_duration_hours = sum_duration_mins / 60)

    
    # ---
    # Group data by client
    by_client <-
        time_entries %>%
        group_by(client, client_label) %>% 
        tally()

        
    # ---
    # Group data by entries
    by_entries <-
        time_entries %>% 
        group_by(client_project, description) %>% 
        tally()
    
    
    # ---
    # Group entries by hour
    # - Select a subset of columns
    # - Keep track the open/close of events
    # - Use thicken/pad to complete the dataset with each hour of the day
    # - Compute day of the week and hour of the day
    by_hour <-
        time_entries %>% 
        select(description, start_date, start, end) %>% 
        reshape2::melt(id.vars = c("description", "start_date")) %>% 
        arrange(start_date, description, variable, value) %>% 
        select(start_date, description, variable, value) %>% 
        ## TODO: Find a clearer way to track the event open/close
        mutate(open_event = ifelse(variable == "start", 1, -1)) %>% 
        thicken("hour") %>% 
        pad(by = "value_hour") %>% 
        group_by(value_hour) %>% 
        summarize(open_event = sum(open_event),
                  n = n(),
                  entries = ifelse(is.na(open_event),
                                   0,
                                   (n + abs(open_event)) / 2)) %>% 
        select(value_hour, entries) %>% 
        mutate(day_string = 
                   lubridate::wday(value_hour, label = TRUE, abbr = FALSE),
               hour = hour(value_hour))
    
    
    
    # ========================================
    # Tab: By project
    # ========================================
    
    # ---
    # Output - By project: 
    # Plot by project
    output$plotByProject <-
        renderPlot({
            by_project %>% 
                ggplot() +
                geom_bar(aes(x = fct_reorder(client_project, sum_duration_hours),
                             y = sum_duration_hours,
                             fill = client_project),
                         alpha = 0.75,
                         stat = "identity") +
                labs(x = "", y = "Hours") +
                coord_flip() +
                guides(fill = FALSE) +
                theme_minimal()
        })
    
    
    # ---
    # Output - By project: 
    # Number of clients
    output$clientsBox <-
        renderValueBox({
            value_clients <-
                by_client %>%
                filter(!is.na(client)) %>%
                nrow()

            valueBox(value_clients,
                     ifelse(value_clients == 1, "Client", "Clients"),
                     icon = icon("building"),
                     color = "teal")
        })
    
    
    # ---
    # Output - By project: 
    # Number of projects
    output$projectsBox <-
        renderValueBox({
            value_projects <- nrow(by_project)
            
            valueBox(value_projects, 
                     ifelse(value_projects == 1, "Project", "Projects"), 
                     icon = icon("tasks"),
                     color = "teal")
        })
    
    
    # ---
    # Output - By project: 
    # Number of entries
    output$entriesBox <-
        renderValueBox({
            value_entries <- sum(by_entries$n)
            
            valueBox(value_entries, 
                     ifelse(value_entries == 1, "Entry", "Entries"), 
                     icon = icon("list"),
                     color = "teal")
        })
    
    
    # ---
    # Output - By project: 
    # Number of unique entries
    output$uniqueEntriesBox <-
        renderValueBox({
            value_unique_entries <- nrow(by_entries)
            
            valueBox(value_unique_entries, 
                     ifelse(value_unique_entries == 1, 
                            "Unique entry", 
                            "Unique entries"), 
                     icon = icon("list-ol"),
                     color = "teal")
        })
    
    
    # ---
    # Output - By project:
    # Number of tracked hours
    output$hoursBox <-
        renderValueBox({
            value_hours <- 
                format_time(round(sum(by_project$sum_duration_hours), 
                                  digits = 2), 
                            "hours")
            
            valueBox(value_hours, 
                     "Hours tracked", 
                     icon = icon("clock-o"),
                     color = "teal")
        })
    
    
    # ---
    # Output - By project:
    # Date range
    output$dateRangeBox <-
        renderValueBox({
            date_range_from <- ymd(min(time_entries$start_date))
            date_range_to <- ymd(max(time_entries$start_date))
            format_template <- "Aug 30, 2017"
            
            valueBox("",
                     HTML(paste(
                         "From", strong(stamp(format_template)(date_range_from)), 
                         br(),
                         "To", strong(stamp(format_template)(date_range_to)))), 
                     icon = icon("calendar"),
                     color = "teal")
        })
    
    

    # ========================================
    # Tab: Patterns - By hour
    # ========================================
    
    # ---
    # Output - Time tracking patterns by hour: 
    # Plot
    output$plotPatternsByHour <-
        renderPlot({
            ## Continue only after all dependent controls are created
            if (is.null(input$checkboxSmootherInput) |
                is.null(input$selectDayTypeInput) |
                is.null(input$selectStatInput)) {
                return(NULL)
            }
            
            ## Setting up what days will be filtered
            ## Sunday: 1, Monday: 2, ..., Saturday: 7
            if (input$selectDayTypeInput == "Weekdays") {
                filter_days <- 2:6
            } else if (input$selectDayTypeInput == "Weekend") {
                filter_days <- c(1, 7)
            } else {
                filter_days <- 1:7
            }
            
            ## Create summary table by hour
            by_hour_summary <-
                by_hour %>% 
                filter(as.numeric(day_string) %in% filter_days) %>% 
                group_by(hour) %>% 
                summarize(sum_entries = sum(entries), 
                          mean_entries = mean(entries),
                          median_entries = median(entries),
                          max_entries = max(entries),
                          min_entries = min(entries))
            
            
            ## Plot construction
            
            ### Y-axis depends on the selected stat
            plot_patterns_by_hour <-
                ggplot(by_hour_summary, 
                       aes_string(x = "hour", 
                                  y = input$selectStatInput)) +
                geom_line(size = 0.75,
                          colour = "dodgerblue4",
                          alpha = 0.5)
            
            ### Condition to add a LOESS smoother
            if (input$checkboxSmootherInput) {
                plot_patterns_by_hour <-
                    plot_patterns_by_hour + 
                    geom_smooth(method = "loess", 
                                se = FALSE,
                                colour = "red4",
                                alpha = 0.5)
            }
            
            ### General settings
            plot_patterns_by_hour <-
                plot_patterns_by_hour +
                labs(x = "Hour of the day", y = "Active entries") +
                scale_x_continuous(breaks = 0:23) + 
                theme_minimal()
            
            
            ## Print constructed plot
            print(plot_patterns_by_hour)
        })

    
    # ---
    # Output - Time tracking patterns by hour: 
    # Input for Day type selector (all, weekdays, weekends)
    output$selectDayType <-
        renderUI({
            selectInput("selectDayTypeInput",
                        "Type of days:", 
                        choices = c("All", 
                                    "Weekdays", 
                                    "Weekend"))
        })

    
    # ---
    # Output - Time tracking patterns by hour: 
    # Input for Stat selector (number of entries, median, mean)
    output$selectStat <-
        renderUI({
            selectInput("selectStatInput",
                        "Measure:", 
                        choices = c("# of entries" = "sum_entries", 
                                    "Median # of entries" = "median_entries", 
                                    "Mean # of entries" = "mean_entries",
                                    "Max # of entries" = "max_entries"))
        })
    
    
    # ---
    # Output - Time tracking patterns by hour: 
    # Input for smoother checkbox (unchecked by default)
    output$checkboxSmoother <-
        renderUI({
            checkboxInput("checkboxSmootherInput",
                          "Add smoother", 
                          value = FALSE)
        })
    
    
    
    # ========================================
    # Tab: Patterns - By duration
    # ========================================
    
    # ---
    # Output - Time tracking patterns by duration: 
    # Plot
    output$plotPatternsByDuration <-
        renderPlot({
            ## Continue only after all dependent controls are created
            if (is.null(input$selectBinsInput) |
                is.null(input$radioPlotTypeInput)) {
                return(NULL)
            }
            
            
            ## Plot construction

            ### Y-axis depends on the selected plot type
            ### Convert X-values in seconds to hours
            plot_patterns_by_duration <-
                ggplot(time_entries, 
                       aes_string(x = "duration_secs / (60 * 60)",
                                  y = paste0("..",
                                             input$radioPlotTypeInput,
                                             ".."))) +
                geom_histogram(
                    binwidth = as.numeric(input$selectBinsInput) / (60 * 60),
                    fill = "dodgerblue4",
                    alpha = 0.5)
            
            ### Condition to add a smoother by kernel density estimate
            if (input$radioPlotTypeInput == "density") {
                plot_patterns_by_duration <-
                    plot_patterns_by_duration +
                    geom_density(fill = "red4", 
                                 alpha = 0.5)
            }
            
            ### General settings
            plot_patterns_by_duration <-
                plot_patterns_by_duration +
                labs(x = "Duration (in hours)", 
                     y = paste(str_to_title(input$radioPlotTypeInput), 
                               "of time entries")) +
                theme_minimal()
            
            
            ## Print constructed plot
            print(plot_patterns_by_duration)
        })
    
    
    # ---
    # Output - Time tracking patterns by duration: 
    # Input for bins selector
    output$selectBins <-
        renderUI({
            ## Values in seconds
            selectInput("selectBinsInput",
                        "Bins:", 
                        choices = c("1 hour" = "3600", 
                                    "30 mins" = "1800", 
                                    "15 mins" = "900",
                                    "10 mins" = "600",
                                    "5 mins" = "120",
                                    "1 min" = "60"))
        })
    
    
    # ---
    # Output - Time tracking patterns by duration: 
    # Input for plot type
    output$radioPlotType <-
        renderUI({
            radioButtons("radioPlotTypeInput",
                         "Type:", 
                         choiceNames = list(
                             "Count",
                             "Density"),
                         choiceValues = list(
                             "count",
                             "density"))
        })
    
    
    
    # ========================================
    # Tab: Raw data
    # ========================================
    
    # ---
    # Output - Raw data table: 
    output$rawDataTable <-
        DT::renderDataTable({
            DT::datatable(time_entries_raw,
                          style = "bootstrap",
                          class = "table-bordered table-condensed",
                          selection = "none",
                          options = list(scrollX = TRUE))
        })

    
}