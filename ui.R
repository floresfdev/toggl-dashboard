library(shinydashboard)

header <- dashboardHeader(title = "Toggl Dashboard")

sidebar <- dashboardSidebar(
    sidebarMenu(
        id = "tabs",
        
        menuItem("By project", tabName = "byProject", icon = icon("tasks")),
        
        menuItem("Patterns", 

                 menuSubItem("By hour", 
                             tabName = "patternsByHour", 
                             icon = icon("line-chart")),
                 
                 menuSubItem("By duration", 
                             tabName = "patternsByDuration", 
                             icon = icon("bar-chart")),
                 
                 startExpanded = TRUE
        ),
        
        menuItem("Raw data", tabName = "rawData", icon = icon("file-text-o"))
    )
)

body <- dashboardBody(
    tabItems(
        tabItem(tabName = "byProject",
                fluidRow(
                    tags$head(tags$style(HTML(".small-box {height: 95px}"))),
                    
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
                        plotOutput("plotByProject", height = 300))
                )
        ),
        
        tabItem(tabName = "patternsByHour",
                fluidRow(
                    box(title = "Time tracking patterns: By hour",
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
                    box(title = "Time tracking patterns: By duration",
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
                
        )
    )
)


ui <- dashboardPage(header, sidebar, body)