library(shinydashboard)

header <- dashboardHeader(title = "Toggl Dashboard")

sidebar <- dashboardSidebar(
    sidebarMenu(
        id = "tabs",
        
        menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
        
        menuItem("By project", tabName = "byProject", icon = icon("tasks")),
        
        menuItem("Patterns", tabName = "patterns", icon = icon("line-chart")),
        
        menuItem("Other", tabName = "other", icon = icon("cog"))
    )
)

body <- dashboardBody(
    tabItems(
        tabItem(tabName = "dashboard",
                h2("Main dashboard")
        ),
        
        tabItem(tabName = "byProject",
                fluidRow(
                    box(title = "Time by project", 
                        width = 9,
                        status = "primary", 
                        solidHeader = TRUE,
                        plotOutput("plotByProject", height = 300)),
                    
                    valueBoxOutput("clientsBox", width = 3),
                    
                    valueBoxOutput("projectsBox", width = 3),
                    
                    valueBoxOutput("hoursBox", width = 3)
                )
        ),
        
        tabItem(tabName = "patterns",
                fluidRow(
                    box(title = "Time tracking patterns",
                        width = 9,
                        status = "primary",
                        solidHeader = TRUE,
                        plotOutput("plotPatterns", height = 300)),
                    
                    box(title = "Statistics",
                        width = 3,
                        status = "primary",
                        solidHeader = TRUE,
                        uiOutput("selectDayType"),
                        #br(),
                        uiOutput("selectStat"),
                        #br(),
                        uiOutput("checkboxSmoother"))
                )
            
        ),
        
        tabItem(tabName = "other",
                h2("Other tab")
        )
    )
)


ui <- dashboardPage(header, sidebar, body)