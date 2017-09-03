library(data.table)
library(tidyverse)
library(lubridate)
library(stringr)
library(forcats)

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

#names(time_entries)


# ---
# EDA
str(time_entries)
View(time_entries)


## By user:
time_entries %>% 
    group_by(user) %>% 
    summarize(n = n(),
              #sum_duration = sum(duration),
              sum_duration_secs = sum(duration_secs),
              sum_duration_mins = sum_duration_secs / 60,
              sum_duration_hours = sum_duration_mins / 60
              #sum_from_dates = sum(end - start)
              )
    

time_entries %>% 
    select(start, end, duration) %>% 
    mutate(duration_from_dates = end - start,
           class_column = class(duration_from_dates))


## By project:
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
