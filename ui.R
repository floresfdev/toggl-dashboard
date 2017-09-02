library(shinydashboard)

ui <- dashboardPage(
    dashboardHeader(title = "Toggl Dashboard"),
    dashboardSidebar(),
    dashboardBody(
        fluidRow(
            box(plotOutput("plotByProject", height = 300))
        )
    )
)