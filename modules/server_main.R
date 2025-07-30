# server <- function(input, output, session) {
#   output$map <- renderLeaflet({
#     leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
#       setView(lng = 105.8542, lat = 21.0285, zoom = 6)
#   })

# coords <- eventReactive(input$search, {
#   req(input$city)
#   get_coords(input$city)
# })

#   observeEvent(input$map_click, {
#     lat <- input$map_click$lat
#     lon <- input$map_click$lng
#     update_weather(lat, lon)
#   })

#   observeEvent(input$search, {
#     coords_val <- coords()
#     if (is.null(coords_val)) {
#       showNotification("❌ City not found", type = "error")
#       return()
#     }
#     lat <- coords_val$lat
#     lon <- coords_val$lon

#     leafletProxy("map") %>% setView(lng = lon, lat = lat, zoom = 10)
#     update_weather(lat, lon)
#   })

#   update_weather <- function(lat, lon) {
#     leafletProxy("map") %>% clearMarkers() %>% addMarkers(lng = lon, lat = lat)
    
#     weather <- get_weather_data(lat, lon)
#     if (is.null(weather)) {
#       showNotification("⚠️ Failed to fetch weather", type = "error")
#       return()
#     }

#     location_name <- reverse_geocode(lat, lon)
#     output$weatherInfo <- renderUI({
#       HTML(render_weather_info(weather, lat, lon, input$hour_select, location_name, input$unit_temp))
#     })
    
#     output$dailyPlot <- renderPlotly({
#       req(input$plot_var)
#       if (is.null(weather$daily)) return(NULL)

#       aqi_data <- NULL
#       if (input$plot_var == "air_quality_index") {
#         aqi_data <- get_aqi_data(lat, lon)
#         if (is.null(aqi_data)) {
#           showNotification("⚠️ Failed to fetch AQI data", type = "error")
#           return(NULL)
#         }
#       }
#       render_temp_plot(    
#       daily = weather$daily,
#       hourly = weather$hourly,
#       var = input$plot_var,
#       unit = input$unit_temp,
#       days = input$day_range,
#       aqi = aqi_data
#     )
#     })
    
#     shinyjs::show("weatherBox")
#   }
#   observe({
#   print(input$plot_var)
# })
# }



# server <- function(input, output, session) {
#   # Khởi tạo biến để lưu dữ liệu thời tiết
#   weather_data <- reactiveValues(
#     daily = NULL,
#     hourly = NULL,
#     lat = NULL,
#     lon = NULL
#   )

#   output$map <- renderLeaflet({
#     leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
#       setView(lng = 105.8542, lat = 21.0285, zoom = 6)
#   })

#   coords <- eventReactive(input$search, {
#     req(input$city)
#     get_coords(input$city)
#   })

#   observeEvent(input$map_click, {
#     lat <- input$map_click$lat
#     lon <- input$map_click$lng
#     update_weather(lat, lon)
#   })

#   observeEvent(input$search, {
#     req(input$city)

#     id_loading <- showNotification("⏳ Loading...", duration = NULL, type = "message")
#     coords_val <- get_coords(input$city)

#     if (is.null(coords_val)) {
#       removeNotification(id_loading)
#       showNotification("❌ City not found", type = "error")
#       shinyjs::hide("weatherBox")
#       return()
#     }

#     lat <- coords_val$lat
#     lon <- coords_val$lon

#     # Di chuyển bản đồ + hiển thị thời tiết
#     leafletProxy("map") %>% setView(lng = lon, lat = lat, zoom = 10)
#     update_weather(lat, lon)
#     removeNotification(id_loading)
#   })


#   selected_order <- reactiveVal(character(0))
#   observeEvent(input$plot_var, {
#     new <- input$plot_var

#     if (length(new) == 0) {
#       selected_order(NULL)
#       return()
#     }

#     old <- selected_order()
#     updated <- c(old[old %in% new], new[!new %in% old])

#     selected_order(updated)
#   })


#   update_weather <- function(lat, lon) {
#     leafletProxy("map") %>% clearMarkers() %>% addMarkers(lng = lon, lat = lat)
    
#     weather <- get_weather_data(lat, lon)
#     if (is.null(weather)) {
#       showNotification("⚠️ Failed to fetch weather", type = "error")
#       return()
#     }

#     location_name <- reverse_geocode(lat, lon)
#     output$weatherInfo <- renderUI({
#       HTML(render_weather_info(weather, lat, lon, input$hour_select, location_name, input$unit_temp))
#     })

#     # Lưu dữ liệu vào reactiveValues
#     weather_data$daily <- weather$daily
#     weather_data$hourly <- weather$hourly
#     weather_data$lat <- lat
#     weather_data$lon <- lon

#     shinyjs::show("weatherBox")
#   }

#   output$dailyPlot <- renderUI({
#     req(weather_data$daily)

#     if (length(selected_order()) == 0) {
#       return(NULL)
#     }

#     plot_output_list <- lapply(selected_order(), function(varname) {
#       plotname <- paste0("plot_", varname)
#       div(
#         style = "margin-bottom: 30px;",  
#         plotlyOutput(plotname, height = "300px")
#       )
#     })

#     do.call(tagList, plot_output_list)
#   })


#   observe({
#   req(weather_data$daily)

#   all_vars <- c("temperature_2m", "relative_humidity_2m_max", "precipitation_sum",
#                 "windspeed_10m_max", "uv_index_max", "air_quality_index")
  
#   selected <- selected_order()

#   # Xóa các output plot không còn được chọn để tránh giữ plot cũ
#   plots_to_clear <- setdiff(all_vars, selected)
#   lapply(plots_to_clear, function(varname) {
#     plotname <- paste0("plot_", varname)
#     output[[plotname]] <- NULL
#   })

#   # Nếu không còn plot nào được chọn thì thôi
#   if (length(selected) == 0) return()

#   lapply(selected, function(varname) {
#     plotname <- paste0("plot_", varname)
#     output[[plotname]] <- renderPlotly({
#       aqi_data <- NULL
#       if (varname == "air_quality_index") {
#         aqi_data <- get_aqi_data(weather_data$lat, weather_data$lon)
#         if (is.null(aqi_data)) {
#           showNotification("⚠️ Failed to fetch AQI data", type = "error")
#           return(NULL)
#         }
#       }
#       render_temp_plot(
#         daily = weather_data$daily,
#         hourly = weather_data$hourly,
#         var = varname,
#         unit = input$unit_temp,
#         days = input$day_range,
#         aqi = aqi_data
#       )
#     })
#   })
# })

# }


server <- function(input, output, session) {
  # Khởi tạo biến lưu dữ liệu thời tiết
  weather_data <- reactiveValues(
    daily = NULL,
    hourly = NULL,
    lat = NULL,
    lon = NULL
  )

  # Render bản đồ ban đầu
  output$map <- renderLeaflet({
    leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
      setView(lng = 105.8542, lat = 21.0285, zoom = 6)
  })

  # Khi click trên bản đồ
  observeEvent(input$map_click, {
    lat <- input$map_click$lat
    lon <- input$map_click$lng
    update_weather(lat, lon)
  })

  # Khi nhấn Search
  observeEvent(input$search, {
    req(input$city)

    id_loading <- showNotification("⏳ Loading...", duration = NULL, type = "message")
    coords_val <- get_coords(input$city)

    if (is.null(coords_val)) {
      removeNotification(id_loading)
      showNotification("❌ City not found", type = "error")
      shinyjs::hide("weatherBox")
      return()
    }

    lat <- coords_val$lat
    lon <- coords_val$lon

    leafletProxy("map") %>% setView(lng = lon, lat = lat, zoom = 10)
    update_weather(lat, lon)
    removeNotification(id_loading)
  })

  selected_order <- reactiveVal(character(0))
  observe({
    selected_order(input$plot_var)
  })

  update_weather <- function(lat, lon) {
    leafletProxy("map") %>% clearMarkers() %>% addMarkers(lng = lon, lat = lat)

    weather <- get_weather_data(lat, lon)
    if (is.null(weather)) {
      showNotification("⚠️ Failed to fetch weather", type = "error")
      return()
    }

    location_name <- reverse_geocode(lat, lon)

    output$weatherInfo <- renderUI({
      HTML(render_weather_info(
        weather, lat, lon, input$hour_select, location_name, input$unit_temp
      ))
    })

    weather_data$daily <- weather$daily
    weather_data$hourly <- weather$hourly
    weather_data$lat <- lat
    weather_data$lon <- lon

    shinyjs::show("weatherBox")
  }

  # Render phần plot UI (nhiều biểu đồ)
  output$dailyPlot <- renderUI({
    req(weather_data$daily)

    selected <- selected_order()
    if (is.null(selected) || length(selected) == 0) {
      return(NULL)
    }

    plot_output_list <- lapply(selected, function(varname) {
      plotname <- paste0("plot_", varname)
      div(style = "margin-bottom: 30px;",
          plotlyOutput(plotname, height = "300px"))
    })

    do.call(tagList, plot_output_list)
  })

  observe({
    req(weather_data$daily)

    all_vars <- c("temperature_2m", "relative_humidity_2m_max", "precipitation_sum",
                  "windspeed_10m_max", "uv_index_max", "air_quality_index")

    selected <- selected_order()

    # Nếu bỏ hết chọn → xóa hết
    if (is.null(selected) || length(selected) == 0) {
      lapply(all_vars, function(varname) {
        output[[paste0("plot_", varname)]] <- NULL
      })
      return()
    }

    # Xóa plot không còn chọn
    plots_to_clear <- setdiff(all_vars, selected)
    lapply(plots_to_clear, function(varname) {
      output[[paste0("plot_", varname)]] <- NULL
    })

    # Render các plot mới
    lapply(selected, function(varname) {
      output[[paste0("plot_", varname)]] <- renderPlotly({
        aqi_data <- NULL
        if (varname == "air_quality_index") {
          aqi_data <- get_aqi_data(weather_data$lat, weather_data$lon)
          if (is.null(aqi_data)) {
            showNotification("⚠️ Failed to fetch AQI data", type = "error")
            return(NULL)
          }
        }

        render_temp_plot(
          daily = weather_data$daily,
          hourly = weather_data$hourly,
          var = varname,
          unit = input$unit_temp,
          days = input$day_range,
          aqi = aqi_data
        )
      })
    })
  })
}

