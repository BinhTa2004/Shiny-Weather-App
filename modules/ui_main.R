ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      html, body { height: 100%; margin: 0; padding: 0; }
      #map { height: 100vh; }
      .floating-panel {
        position: absolute;
        top: 20px;
        left: 20px;
        width: 300px;
        background: rgba(255,255,255,0.75);
        padding: 15px;
        border-radius: 8px;
        z-index: 1000;
        box-shadow: 0 2px 8px rgba(0,0,0,0.5);
        cursor: move;
      }

      .info-box {
        position: absolute;
        top: 80px;
        left: 50%;
        transform: translateX(-50%);
        width: 550px;              
        background: rgba(0, 0, 0, 0.75);
        color: white;
        padding: 25px;            
        font-size: 20px;           
        border-radius: 12px;     
        box-shadow: 0 0 20px rgba(0, 0, 0, 0.5); 
        z-index: 1001;
        display: none;
        cursor: move;
        max-height: 80vh;

        overflow-y: auto;
        scrollbar-width: none;         /* Firefox */
        -ms-overflow-style: none;      /* IE/Edge */
      }

      #weatherBox::-webkit-scrollbar {
        display: none;                 /* Chrome/Safari */
      }

      .info-box .close-btn {
        position: absolute;
        top: 5px;
        right: 10px;
        cursor: pointer;
        color: red;
        font-weight: bold;
      }

      .weather-title {
        font-size: 30px;
        font-weight: bold;
        color: #00ffff;
        margin-bottom: 10px;
        display: block;
      }

      .shiny-notification {
        font-size: 18px !important;
        padding: 15px !important;
        border-radius: 10px;
      }
    ")),

    # tags$script(src = "https://code.jquery.com/ui/1.13.2/jquery-ui.js"),
    # tags$link(rel = "stylesheet", href = "https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css"),
    # tags$script(src = "style/custom.js")
    
    tags$script(src = "https://code.jquery.com/ui/1.13.2/jquery-ui.js"),
    tags$link(rel = "stylesheet", href = "https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css"),
    tags$script(HTML("
      $(function() {
        $('.floating-panel').draggable({
        cancel: 'input, .selectize-input, .selectize-dropdown'});
        $('#weatherBox').draggable({
          cancel: '.plotly',        // không kéo khi bấm biểu đồ
          scroll: false,            // không scroll khi kéo
          containment: 'window',    // giữ trong màn hình
          start: function(event, ui) {
            ui.helper.css('transform', 'none'); // tránh lỗi giật nếu có scale/zoom
          }
        });
        $(document).on('click', '.close-btn', function() {
          $('#weatherBox').hide();
        });
      });
    "))
  ),
  
  leafletOutput("map", width = "100%", height = "100vh"),
  
  tags$div(class = "floating-panel",
          textInput("city", "🔍 Enter City Name"),
          actionButton("search", "Search"),
          tags$script(HTML("
            $(document).on('keypress', function (e) {
              if (e.which == 13) {
                $('#search').click();
              }
            });
          ")),

          sliderInput("hour_select", "🕒 Hourly Forecast", min = 0, max = 23, value = 12),
          selectizeInput("plot_var", "📈 Plot Variable", choices = c(
            #"Please choose a variable" = "",
            "Temperature (°C)" = "temperature_2m",
            "Humidity (%)" = "relative_humidity_2m_max",
            "Precipitation (mm)" = "precipitation_sum",
            "Wind Speed (km/h)" = "windspeed_10m_max",
            "UV Index" = "uv_index_max",
            "AQI (Air Quality Index)" = "air_quality_index"
          ),selected = "temperature_2m", 
            multiple = TRUE, 
            options = list(placeholder = 'Select variables to plot...')),

          sliderInput("day_range", "📅 Day Range", min = 1, max = 7, value = 3, step = 1, ticks = FALSE),
          radioButtons("unit_temp", "🌡️ Temperature Unit", choices = c("Celsius" = "c", "Fahrenheit" = "f"), inline = TRUE),
  ),

  tags$div(id = "weatherBox", class = "info-box",
           tags$div(class = "info-header",
           tags$span(class = "close-btn", "✖"),
           tags$strong(class = "weather-title","🌍 Weather Information")),
           htmlOutput("weatherInfo"),
           #plotlyOutput("dailyPlot", height = "250px")
           uiOutput("dailyPlot") 
  )
)
