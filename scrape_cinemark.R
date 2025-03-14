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
# library(rvest)
library(netstat)
library(tidyverse)
library(wdman)
library(rlist)

# Cerrar puerto en uso
remDr$close()
remote_driver$server$stop()

# Iniciar el servidor de Selenium con GeckoDriver (Firefox)
remote_driver <- rsDriver(browser = "firefox", chromever = NULL, verbose = F)
remDr <- remote_driver$client

# 1. Acceder a la pagina
remDr$navigate("https://www.cinemarkhoyts.com.ar/")
Sys.sleep(5)

#  2. Cerrar el anuncio emergente
btn_cookies <- remDr$findElement(using = "css selector", ".ch-popup-section-content > button")
remDr$executeScript("arguments[0].click();", list(btn_cookies))

#  3. Obtener el catalogo para el cine de Rosario
selector_cine <- remDr$findElements(using = "css selector", "select.ch-select")[[1]]
selector_cine$sendKeysToElement(list(key="enter"))
cine_ros <- remDr$findElements(using = "css selector", "li.opt")[[16]]
remDr$executeScript("arguments[0].click();", list(cine_ros))

selector_peli <- remDr$findElements(using = "css selector", "select.ch-select")[[2]]
selector_peli$sendKeysToElement(list(key="enter"))
pelis <- remDr$findElements(using = "css selector", "li.opt")
indice_peli1 <- function(y) {
  nombres_pelis <- unlist(lapply(y, function(x) x$getElementText()[[1]]))
  which(nombres_pelis != "")[1]
}
indice <- indice_peli1(pelis)
for (i in 26:length(pelis)) {
  nombre_peli <- pelis[[indice+i-26]]$getElementText()[[1]]
  print(nombre_peli)
  remDr$executeScript("arguments[0].click();", list(pelis[[indice+i-26]]))
  Sys.sleep(1)
  popup_advertencia <- remDr$findElement(using = "css selector", "div#ch-popup-confirm > button")
  popup_advertencia$clickElement()
  Sys.sleep(1)
  
  fechas <- remDr$findElements(using = "css selector", "div#ch-timeline > div.ch-radio")
  
  for (fecha in fechas) {
    fecha$clickElement()
    Sys.sleep(1)
    fecha_text <- strsplit(fecha$getElementText()[[1]], "\n")[[1]][2]
    print(fecha_text)
    formatos <- remDr$findElements(using = "css selector", "ul.list-group.p-0 > li")
    for (formato in formatos) {
      formato_text <- formato$findChildElement(using = "css selector", "h2.ch-showtime-title")$getElementText()[[1]]
      print(formato_text)
      horarios <- formato$findChildElements(using = "css selector", "ul .ch-radio.ch-radio_outline")
      #print(unlist(lapply(horarios, function(x) x$getElementText()[[1]])))
      print(unlist(lapply(horarios, function(x) x$getElementAttribute("textContent")[[1]])))
    }
  }
  
  selector_peli <- remDr$findElements(using = "css selector", "select.ch-select")[[2]]
  selector_peli$sendKeysToElement(list(key="enter"))
  pelis <- remDr$findElements(using = "css selector", "li.opt")
  indice <- indice_peli1(pelis)
}
