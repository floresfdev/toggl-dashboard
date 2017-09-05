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
                        width = 8,
                        status = "primary", 
                        solidHeader = TRUE,
                        plotOutput("plotByProject", height = 300)),
                    
                    valueBoxOutput("clientsBox"),
                    
                    valueBoxOutput("projectsBox"),
                    
                    valueBoxOutput("hoursBox")
                )
        ),
        
        tabItem(tabName = "patterns",
                fluidRow(
                    box(title = "Time tracking patterns",
                        width = 8,
                        status = "primary",
                        solidHeader = TRUE,
                        plotOutput("plotPatterns", height = 300)),
                    
                    box(title = "Statistics",
                        width = 4,
                        status = "primary",
                        solidHeader = TRUE,
                        uiOutput("patternStats1"),
                        br(),
                        uiOutput("patternStats2"))
                )
            
        ),
        
        tabItem(tabName = "other",
                h2("Other tab")
        )
    )
)


ui <- dashboardPage(header, sidebar, body)