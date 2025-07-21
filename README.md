# 🌦️ Shiny Weather App
A user-friendly Shiny web application that allows users to view and analyze weather forecasts by inputting geographic coordinates. The app integrates interactive maps and charts with real-time and forecasted weather data from the OpenWeather API.

---

## 🚀 Features
- 📍 **Coordinate-based Weather Retrieval**  
  Enter latitude and longitude to fetch accurate weather data for any location in the world.

- 🗺️ **Interactive Map (Leaflet)**  
  Visualize and click directly on the map to select a location.

- 📊 **7-Day Forecast Visualization**  
  Line charts for daily temperature trends using `plotly` or `ggplot2`.

- ⏱️ **Hourly Forecast Selection**  
  Choose a specific day and hour to view detailed forecast info (temperature, humidity, weather condition...).

- 🌐 **Real-time API Integration**  
  Powered by [OpenWeatherMap API](https://openweathermap.org/api).

---

## 🖼️ Demo Screenshot

<p align="center">
  <img src="www/screenshot.png" width="600" alt="Shiny Weather App Screenshot">
</p>

---

## 🛠️ Technologies Used
- [R Shiny](https://shiny.posit.co/)
- [Leaflet](https://rstudio.github.io/leaflet/)
- [OpenWeatherMap API](https://openweathermap.org/api)
- [Plotly](https://plotly.com/r/)
- [dplyr](https://dplyr.tidyverse.org/), [httr](https://cran.r-project.org/web/packages/httr/), [jsonlite](https://cran.r-project.org/web/packages/jsonlite/)

---

## 🧪 How to Run
### 📦 Prerequisites
Ensure you have the following R packages installed:

```r
install.packages(c("shiny", "leaflet", "httr", "jsonlite", "plotly", "dplyr"))
```

---

## 🌐 Live Demo

🔗 Try it now: [https://hevfc3-bin-ta.shinyapps.io/AppWeather/](https://hevfc3-bin-ta.shinyapps.io/AppWeather/)
