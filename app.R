library(shiny)
library(shinyjs)
source("global.R")
source("modules/ui_main.R")
source("modules/server_main.R")

shinyApp(ui = ui, server = server)