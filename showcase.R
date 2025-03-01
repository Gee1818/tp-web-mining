# Sitio: Showcase
# Autor: Joaquin Bermejo
# Fecha: Marzo 1, 2025
# ------------------------------------------
#  1. Acceder a la pagina
#  2. Cerrar el anuncio emergente
#  3. Obtener el catalogo para el cine de Rosario
#  4. Para toda pelicula "no anticipada":
#      a. Abrir la pagina de la pelicula
#      b. Obtener el nombre de la pelicula
#      c. Hacer click en la "Mañana" y desplegar opciones
#      d. Para cada tipo de funcion, extraer opciones de horarios

library(RSelenium)
library(rvest)
library(netstat)
library(tidyverse)

remote_driver <- rsDriver(browser = "firefox", port = free_port(), verbose = F)
remDr <- remote_driver$client

#  1. Acceder a la pagina
remDr$navigate("https://todoshowcase.com/")
Sys.sleep(5)

#  2. Cerrar el anuncio emergente
popup <- remDr$findElement(using = "class name", "modal-body")
btn_cerrar_popup <- popup$findElement("class name", "btn")
btn_cerrar_popup$click()

#  3. Obtener el catalogo para el cine de Rosario
menu_rosario <- remDr$findElement(using = "id", "cartelera_cine_40218")
pelis_rosario <- menu_rosario$findChildElements("class name", "boxfilm")
urls_pelis <- character()
for (peli in pelis_rosario) {
    tag_container <- peli$findChildElement("class name", "tag-container")
    tag_anticipada <- tag_container$findChildElements("class name", "estreno2")
    if (length(tag_anticipada) > 0) next
    afiche <- peli$findChildElement("class name", "afiche-pelicula")
    url_peli <- afiche$findChildElement("css selector", "a")$getElementAttribute("href")[[1]]
    urls_pelis <- c(urls_pelis, url_peli)
}

data <- data.frame(Nombre = NULL, Tipo = NULL, Horario = NULL)

#  4. Para toda pelicula "no anticipada":
for (url in urls_pelis) {
  #      a. Abrir la pagina de la pelicula
  remDr$navigate(url)
  Sys.sleep(5)
  
  #      b. Obtener el nombre de la pelicula
  nombre_peli <- remDr$findElement("css selector", "h2")$getElementText()[[1]]
  
  #      c. Hacer click en la "Mañana" y desplegar opciones
  opciones_fechas <- remDr$findElements("class name", "op_day")
  idx_btn_manana <- ifelse(length(opciones_fechas) > 1, 2, 1)
  btn_manana <- opciones_fechas[[idx_btn_manana]]
  remDr$executeScript("arguments[0].click();", list(btn_manana)) # Este es un "click JavaScript"
  remDr$executeScript("arguments[0].click();", list(remDr$findElement("css selector", "h3")))
  Sys.sleep(0.5)
  
  #      d. Para cada seccion, extraer opciones de horarios
  opciones <- remDr$findElement("id", "ui-accordion-op_cinemas-panel-0")
  opciones <- opciones$findChildElements("css selector", "div")
  for (i in 1:length(opciones)) {
    if (i %% 2 != 0) {
      tipo <- opciones[[i]]$getElementText()[[1]]
    } else {
      btns_horarios <- opciones[[i]]$findChildElements("css selector", "button")
      horarios <- unlist(lapply(btns_horarios, function(x) x$getElementText()[[1]]))
      for (horario in horarios) {
        data <- rbind(data, data.frame(Nombre = nombre_peli, Tipo = tipo, Horario = horario))
      }
    }
  }
}

write.csv(data, "pelis_showcase.csv", row.names = F, fileEncoding = "UTF-8")

# Problemas que encontré
# 1) Tuve que usar RSelenium para cerrar el popup. Además, en ocasiones tuve que
#     usar un clic JS en vez de uno normal. No sé si eso puede hacerse en rvest.
# 2) A pesar de que quise excluir las "anticipadas" (estrenos futuros), algunas
#     pelis que figuran en cartelera tienen fechas disponibles para el futuro.
#     Visto esto, quizá no tenga sentido excluir las anticipadas.
# 3) Hay casos muy excepcionales donde una peli no está todos los días hasta el
#     próximo jueves. O está pero no siempre en los mismos horarios. Visto esto,
#     debería scrapear los horarios para cada día por separado, y agregar una
#     columna al dataset con la fecha de la función. Esto trae la complicación
#     adicional de convertir las etiquetas "Hoy" y "Mañana" en fechas.

