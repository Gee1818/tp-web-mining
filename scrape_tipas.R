# Sitio: Las Tipas
# Autor: Joaquin Bermejo
# Fecha: Marzo 8, 2025
# ------------------------------------------
#  1. Acceder a la pagina
#  2. Para cada fecha:
#      a. Ir a la fecha
#      b. Obtener las peliculas en cartelera
#      c. Para cada pelicula disponible:
#          I. Obtener el nombre y formato
#          II. Para cada horario, extraer hora e idioma y grabar

library(RSelenium)
library(rvest)
library(netstat)
library(tidyverse)

remote_driver <- rsDriver(browser = "firefox", port = free_port(), verbose = F, phantomver = NULL)
remDr <- remote_driver$client

#  1. Acceder a la pagina
remDr$navigate("https://rosario.lastipas.com.ar/es-AR")
Sys.sleep(5)

btns_fechas <- remDr$findElements("css selector", "#snapDateSlider > div")
btn_derecha <- remDr$findElements("css selector", ".gap-4 > button")[[2]]
fechas_texto <- unlist(lapply(btns_fechas, function(x) x$getElementAttribute("textContent")[[1]]))
fechas <- character()
meses_espanol <- c(
  "Enero"=1, "Febrero"=2, "Marzo"=3, "Abril"=4, "Mayo"=5, "Junio"=6,
  "Julio"=7, "Agosto"=8, "Septiembre"=9, "Octubre"=10, "Noviembre"=11, "Diciembre"=12
)
for (fecha_texto in fechas_texto) {
  dia <- as.numeric(str_extract(fecha_texto, "\\d+"))
  mes <- meses_espanol[[str_extract(fecha_texto, "[A-Za-z]+$")]]
  fecha <- as.character(as.Date(paste(year(Sys.Date()), mes, dia, sep = "-")))
  fechas <- c(fechas, fecha)
}

data <- data.frame(Nombre = NULL, Fecha = NULL, Tipo = NULL, Horario = NULL)

#  2. Para cada fecha:
for (i in 1:length(fechas)) {
  
  #      a. Ir a la fecha
  btns_fechas[[i]]$clickElement()
  btn_derecha$clickElement()
  Sys.sleep(1)
  
  #      b. Obtener las peliculas en cartelera
  pelis <- remDr$findElements("class name", "max-w-[670px]")
  
  #      c. Para cada pelicula disponible:
  for (peli in pelis) {
    #          I. Obtener el nombre y formato
    nombre_peli <- peli$findChildElement("css selector", "h4")$getElementText()[[1]]
    nombre_peli <- sub("(.*?)\\s*(2D|3D|ATMOS).*", "\\1", nombre_peli) # remover 2D, 3D, 4D
    formato <- peli$findChildElements("css selector", "p")[[8]]$getElementText()[[1]]
    
    #          II. Para cada horario, extraer hora e idioma y grabar
    horarios_spans <- peli$findChildElements("css selector", "span.text-primary.flex")
    horarios <- unlist(lapply(horarios_spans, function(x) x$getElementText()[[1]]))
    for (horario in horarios) {
      horario_split <- unlist(strsplit(horario, "\n"))
      tipo <- ifelse(length(horario_split) > 1, paste(formato, horario_split[1]), formato)
      hora <- horario_split[length(horario_split)]
      data <- rbind(data, data.frame(Nombre = nombre_peli, Fecha = fechas[i], Tipo = tipo, Horario = hora))
    }
    
  }
  
}

remDr$close()

write.csv(data, "pelis_tipas.csv", row.names = F, fileEncoding = "UTF-8")
