library(shinydashboard)

header <- dashboardHeader(title = "Toggl Dashboard")

sidebar <- dashboardSidebar(
    sidebarMenu(
        menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
        
        menuItem("By project", tabName = "byProject", icon = icon("tasks")),
        
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
        
        tabItem(tabName = "other",
                h2("Other tab")
        )
    )
)


ui <- dashboardPage(header, sidebar, body)