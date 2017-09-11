library(shinydashboard)

header <- dashboardHeader(title = "Toggl Dashboard")

sidebar <- dashboardSidebar(
    sidebarMenu(
        id = "tabs",
        
        menuItem("Time by project", 
                 tabName = "byProject", 
                 icon = icon("tasks")),
        
        menuItem("Time tracking patterns", 

                 menuSubItem("Entries by hour", 
                             tabName = "patternsByHour", 
                             icon = icon("line-chart")),
                 
                 menuSubItem("Entries by duration", 
                             tabName = "patternsByDuration", 
                             icon = icon("bar-chart")),
                 
                 startExpanded = TRUE
        ),
        
        menuItem("Raw data", 
                 tabName = "rawData", 
                 icon = icon("file-text-o")),
        
        menuItem("About",
                 tabName = "about",
                 icon = icon("info-circle"))
    )
)

body <- dashboardBody(
    tabItems(
        tabItem(tabName = "byProject",
                fluidRow(
                    tags$head(tags$style(HTML(".small-box {height: 90px}"))),
                    
                    valueBoxOutput("dateRangeBox", width = 4),
                    
                    valueBoxOutput("clientsBox", width = 4),
                    
                    valueBoxOutput("projectsBox", width = 4),
                    
                    valueBoxOutput("hoursBox", width = 4),
                    
                    valueBoxOutput("entriesBox", width = 4),
                    
                    valueBoxOutput("uniqueEntriesBox", width = 4)
                ),
                
                fluidRow(
                    box(title = "Time by project", 
                        width = 12,
                        status = "primary", 
                        solidHeader = TRUE,
                        plotOutput("plotByProject", height = 290))
                )
        ),
        
        tabItem(tabName = "patternsByHour",
                fluidRow(
                    box(title = "Time tracking patterns: Entries by hour",
                        width = 9,
                        status = "primary",
                        solidHeader = TRUE,
                        plotOutput("plotPatternsByHour", height = 500)),
                    
                    box(title = "Explore",
                        width = 3,
                        status = "primary",
                        solidHeader = TRUE,
                        uiOutput("selectDayType"),
                        uiOutput("selectStat"),
                        uiOutput("checkboxSmoother"))
                )
            
        ),
        
        tabItem(tabName = "patternsByDuration",
                fluidRow(
                    box(title = "Time tracking patterns: Entries by duration",
                        width = 9,
                        status = "primary",
                        solidHeader = TRUE,
                        plotOutput("plotPatternsByDuration", height = 500)),
                    
                    box(title = "Explore",
                        width = 3,
                        status = "primary",
                        solidHeader = TRUE,
                        uiOutput("radioPlotType"),
                        uiOutput("selectBins"))
                )
        ),
        
        tabItem(tabName = "rawData",
                fluidRow(
                    box(title = "Raw data",
                        width = 12,
                        status = "primary",
                        solidHeader = TRUE,
                        dataTableOutput("rawDataTable"))
                )
                
        ),
        
        tabItem(tabName = "about",
                fluidRow(
                    column(width = 12,
                           shiny::includeHTML("./docs/about.html"))
                ))
    )
)


ui <- dashboardPage(header, sidebar, body)