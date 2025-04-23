# Sitio: Cinemark Hoyts
# Autor: Victorio Costa
# Fecha: 8 de marzo
# ------------------------------------------
#  1. Acceder a la pagina
#  2. Aceptar cookies
#  3. Obtener el catalogo para el cine de Rosario
#  4. Obtener la categoria "Todas las peliculas"
#  5. Para cada pelicula:
#      a. Abrir la pagina de la pelicula
#      b. Obtener el nombre de la pelicula
#      c. Para cada fecha disponible:
#          I. Grabar la fecha correspondiente
#          II. Hacer click en la fecha y desplegar opciones
#          III. Para cada tipo de funcion, extraer opciones de horarios

library(RSelenium)
library(netstat)
library(tidyverse)
library(wdman)
library(rlist)

# 0. Cerrar puerto en uso (si lo hubiera)
#remDr$close()
#remote_driver$server$stop()

## 1. Iniciar el servidor de Selenium con GeckoDriver (Firefox)
remote_driver <- rsDriver(browser = "firefox", chromever = NULL, verbose = F)
remDr <- remote_driver$client

## 2. Acceder a la pagina
remDr$navigate("https://www.cinemarkhoyts.com.ar/")
Sys.sleep(5)

## 3. Cerrar el anuncio emergente
btn_cookies <- remDr$findElement(using = "css selector", ".ch-popup-section-content > button")
remDr$executeScript("arguments[0].click();", list(btn_cookies))

## 4. Obtener el catalogo para el cine de Rosario
selector_cine <- remDr$findElements(using = "css selector", "select.ch-select")[[1]]
selector_cine$sendKeysToElement(list(key="enter"))
cine_ros <- remDr$findElements(using = "css selector", "li.opt")[[16]]
remDr$executeScript("arguments[0].click();", list(cine_ros))


## 5. Se obtienen las peliculas del desplegable para iterar
selector_peli <- remDr$findElements(using = "css selector", "select.ch-select")[[2]]
selector_peli$sendKeysToElement(list(key="enter"))
pelis <- remDr$findElements(using = "css selector", "li.opt")

# Funcion para obtener los indices de las peliculas en el desplegable
indice_peli1 <- function(y) {
  nombres_pelis <- unlist(lapply(y, function(x) x$getElementText()[[1]]))
  which(nombres_pelis != "")[1]
}
indice <- indice_peli1(pelis)

# Creacion del dataset para almacenar la informacion
data <- data.frame(Nombre = NULL, Fecha = NULL, Tipo = NULL, Horario = NULL)

## 6. Iteracion en la pagina para obtener la informacion deseada 
# Para cada pelicula
for (i in 26:length(pelis)) {
  # Obtengo el nombre de la pelicula
  nombre_peli <- pelis[[indice+i-26]]$getElementText()[[1]]
  remDr$executeScript("arguments[0].click();", list(pelis[[indice+i-26]]))
  Sys.sleep(1)
  # Cierro (si existe) el cartel de advertencia de que no hay pelicula en la fecha seleccionada
  popup_advertencia <- remDr$findElement(using = "css selector", "div#ch-popup-confirm > button")
  popup_advertencia$clickElement()
  Sys.sleep(1)
  
  # Obtengo las fechas disponibles
  fechas <- remDr$findElements(using = "css selector", "div#ch-timeline > div.ch-radio")
  
  # Para cada fecha
  for (fecha in fechas) {
    # Obtengo la fecha de la pelicula
    fecha$clickElement()
    Sys.sleep(1)
    fecha_text <- strsplit(fecha$getElementText()[[1]], "\n")[[1]][2]
    
    # Obtengo los tipos (2D/3D, subtitulada/doblada)
    tipos <- remDr$findElements(using = "css selector", "ul.list-group.p-0 > li")
    
    # Para cada tipo
    for (tipo in tipos) {
      # Obtengo el tipo de la pelicula
      tipo_text <- tipo$findChildElement(using = "css selector", "h2.ch-showtime-title")$getElementText()[[1]]
      
      # Obtengo los diferentes horarios
      horarios <- tipo$findChildElements(using = "css selector", "ul .ch-radio.ch-radio_outline")
      
      # Para cada horario
      for (horario in horarios) {
        # Obtengo el horario de la pelicula
        horario_text <- horario$getElementAttribute("textContent")[[1]]
        
        # Printeo el resultado en la consola y lo agrego al dataset  
        print(c(nombre_peli, fecha_text, tipo_text, horario_text))
        data <- rbind(data, data.frame(Nombre = nombre_peli, Fecha = fecha_text, Tipo = tipo_text, Horario = horario_text))
      }
    }
  }
  
  # "Reseteo" los valores iniciales para recuperar el orden inicial y seguir con la iteracion
  selector_peli <- remDr$findElements(using = "css selector", "select.ch-select")[[2]]
  selector_peli$sendKeysToElement(list(key="enter"))
  pelis <- remDr$findElements(using = "css selector", "li.opt")
  indice <- indice_peli1(pelis)
}

# Se exporta el dataset en formato csv
write.csv(data, "./pelis_cinemark.csv", row.names = F, fileEncoding = "UTF-8")
