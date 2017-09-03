library(shinydashboard)

header <- dashboardHeader(title = "Toggl Dashboard")

sidebar <- dashboardSidebar(
    sidebarMenu(
        menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
        menuItem("Other", tabName = "other", icon = icon("cog"))
    )
)

body <- dashboardBody(
    tabItems(
        tabItem(tabName = "dashboard",
                fluidRow(
                    box(title = "Time by project", 
                        status = "primary", 
                        solidHeader = TRUE,
                        plotOutput("plotByProject", height = 300)),
                    valueBoxOutput("projectsBox")
                )
        ),
        
        tabItem(tabName = "other",
                h2("Other tab")
        )
    )
)


ui <- dashboardPage(header, sidebar, body)