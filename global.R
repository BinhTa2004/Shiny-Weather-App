library(shiny)
library(leaflet)
library(httr)
library(jsonlite)
library(plotly)
library(lubridate)
library(shinyjs)
library(future)
library(later)  
plan(multisession) 

key <- "a1be32ac2728160108cf255254d80937"

get_coords <- function(city) {
  url <- paste0("https://nominatim.openstreetmap.org/search?format=json&q=", URLencode(city))
  res <- fromJSON(content(GET(url), httr::user_agent("R Shiny Weather App"),as = "text", encoding = "UTF-8"))

  if (length(res) > 0) {
    lat <- as.numeric(res$lat[1])
    lon <- as.numeric(res$lon[1])
    return(list(lat = lat, lon = lon))
  } else {
    showNotification("❌ City not found", type = "error")
    return(NULL)
  }
}

reverse_geocode <- function(lat, lon) {
  url <- paste0("https://nominatim.openstreetmap.org/reverse?format=json&lat=", lat, "&lon=", lon)
  res <- httr::GET(url, httr::user_agent("R Shiny Weather App"))
  
  if (httr::status_code(res) != 200) return(NULL)
  
  data <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
  
  return(data$display_name)
}

get_weather_data <- function(lat, lon) {
  base_url <- "https://api.open-meteo.com/v1/forecast"
  
  params <- list(
    latitude = lat,
    longitude = lon,
    hourly = paste(
      "temperature_2m", "relative_humidity_2m", "cloudcover", 
      "precipitation", "windspeed_10m", "winddirection_10m",
      "apparent_temperature", "uv_index", sep = ","
    ),
    daily = paste(
      "temperature_2m_max", "temperature_2m_min",
      "precipitation_sum", "sunrise", "sunset",
      "uv_index_max", "windspeed_10m_max", "weathercode", sep = ","
    ),
    current_weather = "true",
    timezone = "auto"
  )
  
  res <- httr::GET(base_url, query = params)
  if (httr::status_code(res) != 200) return(NULL)
  
  return(jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8")))
}

get_aqi_data <- function(lat, lon) {
  url <- paste0(
    "https://air-quality-api.open-meteo.com/v1/air-quality?",
    "latitude=", lat,
    "&longitude=", lon,
    "&hourly=us_aqi",
    "&timezone=auto"
  )

  response <- jsonlite::fromJSON(url)

  if (!is.null(response$hourly) && !is.null(response$hourly$us_aqi)) {
    return(data.frame(
      time = as.POSIXct(response$hourly$time, format = "%Y-%m-%dT%H:%M", tz = "UTC"), us_aqi = response$hourly$us_aqi))
  } else {
    return(NULL)
  }
}

get_aqi_color <- function(aqi_value) {
  if (is.na(aqi_value) || is.null(aqi_value)) return("gray")
  else if (aqi_value <= 50) return("green")
  else if (aqi_value <= 100) return("yellow")
  else if (aqi_value <= 150) return("orange")
  else if (aqi_value <= 200) return("red")
  else if (aqi_value <= 300) return("purple")
  else return("brown")
}


render_weather_info <- function(res, lat, lon, hour, location_name, unit) {
  if (is.null(res$current_weather)) return("❌ No data")

  curr <- res$current_weather
  curr_time <- as.POSIXct(curr$time, format = "%Y-%m-%dT%H:%M", tz = "UTC")
  hour_index <- min(hour + 1, length(res$hourly$temperature_2m))
  temp_hour <- res$hourly$temperature_2m[hour_index]
  humidity_hour <- res$hourly$relative_humidity_2m[hour_index]
  clouds_hour <- res$hourly$cloudcover[hour_index]
  feel_like_hour <- res$hourly$apparent_temperature[hour_index]
  uv_index_hour <- res$hourly$uv_index[hour_index]
  precip_hour <- res$hourly$precipitation[hour_index]
  wind_speed_hour <- res$hourly$windspeed_10m[hour_index]
  wind_direction_hour <- res$hourly$winddirection_10m[hour_index]

  if (unit == "f") {
    temp_hour <- round(temp_hour * 9/5 + 32, 1)
  }

  location_display <- if (!is.null(location_name)) {
    paste0("<b>📍 Location:</b> ", location_name, "<br>")
  } else {
    paste0("<b>📍 Lat/Lon:</b> ", round(lat, 3), ", ", round(lon, 3), "<br>")
  }

  paste0(
  "<div style='font-size:15px;'>",
  location_display,
  "<b>🕒 Now:</b> ", format(curr_time, "%A, %d %B %Y %H:%M", tz = "UTC"), "<br/>",
  "<b>🌡️ Temperature:</b> ", curr$temperature, "°C<br/><br/>",
  "<div style='display: flex; gap: 30px;'>",

  "<div>",
  "<b>🌡️ Feels like:</b> ", feel_like_hour, "°C<br/>",
  "<b>🌤 UV Index:</b> ", uv_index_hour, "<br/>",
  "<b>☁️ Cloud cover:</b> ", clouds_hour, "%<br/>",
  "</div>",

  "<div>",
  "<b>💧 Humidity:</b> ", humidity_hour, "%<br/>",
  "<b>💨 Wind:</b> ", wind_speed_hour, " km/h - ", wind_direction_hour, "°<br/>",
  "<b>🌧️ Precipitation:</b> ", precip_hour, " mm<br/>",
  "</div>",

  "</div>",
  "<div style='height:1px; background:#ccc; margin-top:10px; margin-bottom:10px;'></div>"

)}

render_temp_plot <- function(daily, hourly, var, unit, days, aqi) { 
  day_series <- as.Date(daily$time[1:days])
  y_day <- daily[[var]][1:days]

  if (var == "temperature_2m"){
    y_max <- daily$temperature_2m_max[1:days]
    y_min <- daily$temperature_2m_min[1:days]
    if (unit == "f") {
      y_max <- round(y_max * 9/5 + 32, 1)
      y_min <- round(y_min * 9/5 + 32, 1)
    }
    y_label <- if (unit == "c") "°C" else "°F"
    title_label <- "🌡️ Daily Temperature Forecast"

    return(plot_ly(x = day_series, y = y_max, type = "scatter",
        mode = "lines+markers", name = "Max", line = list(color = "orange")) 
        %>% add_trace(y = y_min,name = "Min", line = list(color = "skyblue")) 
        %>% layout(title = title_label, margin = list(t = 50,b = 60), xaxis = list(title = "Date"), yaxis = list(title = y_label))
    )
  }

  y_label <- switch(var,
    "precipitation_sum" = "mm",
    "windspeed_10m_max" = "km/h",
    "uv_index_max" = "Index",
    "relative_humidity_2m_max" = "%",
    "air_quality_index" = "AQI",
    ""
  )

  title_label <- switch(var,
    "precipitation_sum" = "🌧️ Precipitation Forecast",
    "windspeed_10m_max" = "💨 Wind Speed Forecast",
    "uv_index_max" = "☀️ UV Index Forecast",
    "relative_humidity_2m_max" = "💧 Humidity Forecast",
    "air_quality_index" = "🌫️ Air Quality Index Forecast",
    "📈 Forecast"
  )

  if (var == "air_quality_index") {
    time_series <- aqi$time
    y_series <- aqi$us_aqi
    colors <- sapply(y_series, get_aqi_color)

    n <- as.numeric(days) * 24
    time_series <- aqi$time[1:n]
    y_series <- aqi$us_aqi[1:n]

    return(plot_ly(x = time_series, y = y_series, type = "scatter",
      mode = "lines+markers", marker = list(color = colors),name = "AQI") %>%
        layout(title = title_label, margin = list(t = 50, b = 60),
        xaxis = list(title = "Time"), yaxis = list(title = "US AQI")
      )
    ) 
  }

  if (var == "relative_humidity_2m_max") {
    # x_hour <- as.POSIXct(hourly$time, format = "%Y-%m-%dT%H:%M", tz = "UTC")
    # y_hour <- hourly$relative_humidity_2m

    time_parsed <- as.POSIXct(hourly$time, format = "%Y-%m-%dT%H:%M", tz = "UTC")
    start_time <- min(time_parsed)
    end_time <- start_time + (days) * 24 * 3600

    selected_indices <- time_parsed >= start_time & time_parsed < end_time

    x_hour <- time_parsed[selected_indices]
    y_hour <- hourly$relative_humidity_2m[selected_indices]

    colors <- ifelse(is.na(y_hour), "gray", "#0077cc")
    return(plot_ly(x = x_hour, y = y_hour, type = "scatter",
      mode = "lines+markers", marker = list(color = colors),name = var) %>%
        layout(title = title_label, margin = list(t = 50, b = 60),
        xaxis = list(title = "Time"), yaxis = list(title = y_label)
      )
    )
  }

    if (var == "uv_index_max") {
    time_parsed <- as.POSIXct(hourly$time, format = "%Y-%m-%dT%H:%M", tz = "UTC")
    start_time <- min(time_parsed)
    end_time <- start_time + (days) * 24 * 3600

    selected_indices <- time_parsed >= start_time & time_parsed < end_time

    x_hour <- time_parsed[selected_indices]
    y_hour <- hourly$uv_index[selected_indices]

    colors <- ifelse(is.na(y_hour), "gray", "#0077cc")
    return(plot_ly(x = x_hour, y = y_hour, type = "scatter",
      mode = "lines+markers", marker = list(color = colors),name = var) %>%
        layout(title = title_label, margin = list(t = 50, b = 60),
        xaxis = list(title = "Time"), yaxis = list(title = y_label)
      )
    )
  }
  type <- if (var == "precipitation_sum") "bar" else "scatter"

  plot_ly(x = day_series, y = y_day, type = type,
    mode = "lines+markers", name = var, line = list(color = "royalblue")) %>% 
    layout(title = title_label, margin = list(t = 50,b = 60), xaxis = list(title = "Date"), yaxis = list(title = y_label))
}


