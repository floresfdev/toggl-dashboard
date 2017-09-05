library(shiny)
library(shinydashboard)
library(data.table)
library(tidyverse)
library(lubridate)
library(forcats)
library(padr)

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
        mutate(client_label = ifelse(is.na(client), "(without client)", client),
               client_project = paste0(client_label, " / ", project),
               start = ymd_hms(paste(start_date, start_time)),
               end = ymd_hms(paste(end_date, end_time)),
               duration = hms(duration),
               duration_secs = as.numeric(duration))
    
    
    # ---
    # Filter data by client and project
    by_project <-
        time_entries %>%
        group_by(client_project) %>% 
        summarize(n = n(),
                  sum_duration_secs = sum(duration_secs),
                  sum_duration_mins = sum_duration_secs / 60,
                  sum_duration_hours = sum_duration_mins / 60)

    
    # ---
    # Filter data by client
    by_client <-
        time_entries %>%
        group_by(client, client_label) %>% 
        summarize(n = n(),
                  sum_duration_secs = sum(duration_secs),
                  sum_duration_mins = sum_duration_secs / 60,
                  sum_duration_hours = sum_duration_mins / 60)
    
    
    # ---
    # Entries by time
    by_time <-
        time_entries %>% 
        select(description, start_date, start, end) %>% 
        reshape2::melt(id.vars = c("description", "start_date")) %>% 
        arrange(start_date, description, variable, value) %>% 
        select(start_date, description, variable, value) %>% 
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
        

    # ---
    # Output - By project: Plot by project
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
    # Output - By project: # of clients
    output$clientsBox <-
        renderValueBox({
            value_clients <- 
                by_client %>% 
                filter(!is.na(client)) %>% 
                nrow()

            valueBox(value_clients, 
                     ifelse(value_clients == 1, "Client", "Clients"), 
                     icon = icon("building"))
        })
    
    
    # ---
    # Output - By project: # of projects
    output$projectsBox <-
        renderValueBox({
            value_projects <- nrow(by_project)
            valueBox(value_projects, 
                     ifelse(value_projects == 1, "Project", "Projects"), 
                     icon = icon("tasks"))
        })
    
    
    # ---
    # Output - By project: # of tracked hours
    output$hoursBox <-
        renderValueBox({
            valueBox(format_time(round(sum(by_project$sum_duration_hours), 
                                       digits = 2), 
                                 "hours"), 
                     "Hours tracked", 
                     icon = icon("clock-o"))
        })
    
    
    # ---
    # Output - Time tracking patterns; Plot
    output$plotPatterns <-
        renderPlot({
            ## Continue only after all dependent controls are created
            if (is.null(input$checkboxSmootherInput) |
                is.null(input$selectDayTypeInput) |
                is.null(input$selectStatInput)) {
                return(NULL)
            }
            
            ## TODO: Filter/show by:
            ## - Stat: Sum, median, mean (or altogether?)
            ## - Days: All, weekdays, weekend (or altogether with diff lines?)
            
            if (input$selectDayTypeInput == "Weekdays") {
                filter_days <- 2:6
            } else if (input$selectDayTypeInput == "Weekend") {
                filter_days <- c(1, 7)
            } else {
                filter_days <- 1:7
            }
            
            by_time_summary <-
                by_time %>% 
                filter(as.numeric(day_string) %in% filter_days) %>% 
                group_by(hour) %>% 
                summarize(sum_entries = sum(entries), 
                          mean_entries = mean(entries),
                          median_entries = median(entries))
            
            plot_patterns <-
                ggplot(by_time_summary, 
                       aes_string(x = "hour", y = input$selectStatInput))

            plot_patterns <- 
                plot_patterns +
                geom_line() #size = 1
            
            if (input$checkboxSmootherInput) {
                plot_patterns <-
                    plot_patterns + 
                    geom_smooth(se = FALSE)
                # stat_smooth(aes(y = sum_entries, x = hour), 
                #             formula = y ~ s(x, k = 24), 
                #             method = "gam", 
                #             se = FALSE) +
            }
                
            plot_patterns <-
                plot_patterns +
                labs(x = "Hour of the day", y = "Active entries") +
                scale_x_continuous(breaks = 0:23) + 
                theme_minimal() #+
                #theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
                #scale_x_date(date_breaks = "1 hour", date_labels = "%d/%m/%Y - %H:%M")
            
            print(plot_patterns)
        })

    
    # ---
    # Output - Time tracking patterns: 
    # Input for Day type selector (all, weekdays, weekends)
    output$selectDayType <-
        renderUI({
            selectInput("selectDayTypeInput",
                        "Type of days:", 
                        choices = c("All", "Weekdays", "Weekend"))
        })

    
    # ---
    # Output - Time tracking patterns: 
    # Input for Stat selector (number of entries, median, mean)
    output$selectStat <-
        renderUI({
            # p(class = "text-muted",
            #   "Second line of stats")
            selectInput("selectStatInput",
                        "Measure:", 
                        choices = c("# of entries" = "sum_entries", 
                                    "Median # of entries" = "median_entries", 
                                    "Mean # of entries" = "mean_entries"))
        })
    
    
    # ---
    # Output - Time tracking patterns: 
    # Input for smoother checkbox
    output$checkboxSmoother <-
        renderUI({
            checkboxInput("checkboxSmootherInput",
                          "Add smoother", 
                          value = FALSE)
        })
    
}