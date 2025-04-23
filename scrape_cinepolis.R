# Sitio: Cinepolis
# Autor: Joaquin Bermejo
# Fecha: Marzo 7, 2025
# ------------------------------------------
#  1. Acceder a la pagina
#  2. Cerrar el anuncio emergente
#  3. Obtener el catalogo para el cine de Rosario
#  4. Para toda pelicula:
#      a. Abrir la pagina de la pelicula
#      b. Obtener el nombre de la pelicula
#      c. Para cada fecha disponible:
#          I. Grabar la fecha correspondiente
#          II. Hacer click en la fecha y desplegar opciones
#          III. Para cada tipo de funcion, extraer opciones de horarios

library(RSelenium)
library(rvest)
library(netstat)
library(tidyverse)

remote_driver <- rsDriver(browser = "firefox", port = free_port(), verbose = F)
remDr <- remote_driver$client

#  1. Acceder a la pagina
remDr$navigate("https://www.cinepolis.com.ar/cines/cinepolis-rosario")
Sys.sleep(5)

#  2. Cerrar anuncio emergente
popup <- remDr$findElement(using = "class name", "modal-body")
btn_cerrar_popup <- popup$findElement("class name", "btn")
btn_cerrar_popup$click()

#  3. Obtener el catalogo para el cine de Rosario
pelis_rosario <- remDr$findElements("css selector", ".featured-movies-grid-view-component > div")
urls_pelis <- character()
for (peli in pelis_rosario) {
    url_peli <- peli$findChildElement("css selector", "a")$getElementAttribute("href")[[1]]
    urls_pelis <- c(urls_pelis, url_peli)
}

data <- data.frame(Nombre = NULL, Fecha = NULL, Tipo = NULL, Horario = NULL)

#  4. Para toda pelicula:
for (url in urls_pelis) {
  #      a. Abrir la pagina de la pelicula
  remDr$navigate(url)
  Sys.sleep(3)
  
  #      b. Obtener el nombre de la pelicula
  nombre_peli <- remDr$findElement("css selector", "h2")$getElementAttribute("textContent")[[1]]
  
  #      c. Para cada fecha disponible:
  opciones_fechas <- remDr$findElements("css selector", ".p-1 > li > button")
  for (dia in opciones_fechas) {
    
    #          I. Grabar la fecha correspondiente
    fecha <- dia$getElementAttribute("value")[[1]]
    
    #          II. Hacer click en la fecha y desplegar opciones
    remDr$executeScript("arguments[0].click();", list(dia)) # Este es un "click JavaScript"
    Sys.sleep(1)  
    
    #          III. Para cada tipo de funcion, extraer opciones de horarios
    opciones <- remDr$findElements("css selector", "#collapse-4 > div > div > div")
    if (length(opciones) == 0) next
    for (i in 1:length(opciones)) {
      tipo <- opciones[[i]]$findChildElement("class name", "movie-showtimes-component-label")$getElementText()[[1]]
      btns_horarios <- opciones[[i]]$findChildElements("css selector", ".movie-showtimes-component-schedule > a")
      horarios <- unlist(lapply(btns_horarios, function(x) x$getElementText()[[1]]))
      for (horario in horarios) {
        data <- rbind(data, data.frame(Nombre = nombre_peli, Fecha = fecha, Tipo = tipo, Horario = horario))
      }
    }
  }
  
}

write.csv(data, "pelis_cinepolis.csv", row.names = F, fileEncoding = "UTF-8")
