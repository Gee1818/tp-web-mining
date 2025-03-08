# Sitio: Cines del Centro
# Autor: Joaquin Bermejo
# Fecha: Marzo 8, 2025
# ------------------------------------------
#  1. Acceder a la pagina
#  2. Para toda pelicula:
#      a. Obtener el nombre de la pelicula
#      b. Para cada horario:
#          I. Extraer formato y fechas
#          II. Grabar una funcion por cada fecha y horario

library(RSelenium)
library(rvest)
library(netstat)
library(tidyverse)

remote_driver <- rsDriver(browser = "firefox", port = free_port(), verbose = F)
remDr <- remote_driver$client

#  1. Acceder a la pagina
remDr$navigate("https://www.cinesdelcentro.com.ar/")
Sys.sleep(5)

pelis <- remDr$findElements("css selector", "#comp-m7xaua95 > .E6jjcn > .VM7gjN > .Zc7IjY")

data <- data.frame(Nombre = NULL, Fecha = NULL, Tipo = NULL, Horario = NULL)

#  2. Para toda pelicula:
for (peli in pelis) {
  #      a. Obtener el nombre de la pelicula
  nombre_peli <- peli$findChildElements("css selector", "p")[[2]]$getElementText()[[1]]
  
  #      b. Para cada horario:
  texto_horarios <- peli$findChildElements("css selector", "p")[[3]]$getElementText()[[1]]
  horarios <- unlist(strsplit(texto_horarios, "\n+| / "))
  
  for (horario in horarios) {
    #          I. Extraer formato y fechas
    horario_split <- unlist(strsplit(horario, " "))
    hora <- horario_split[1]
    tipo <- substr(horario_split[2], 2, nchar(horario_split[2])-1)
    solo_vie_sab <- ifelse(is.na(horario_split[3]), F, T)
    
    hoy <- Sys.Date()
    proximo_mie <- hoy + (3 - as.integer(format(hoy, "%u"))) %% 7
    fechas <- seq.Date(from = hoy, to = proximo_mie, by = "day")
    if (solo_vie_sab) fechas <- fechas[weekdays(fechas) %in% c("Friday", "Saturday")]
    fechas <- as.character(fechas)
    
    #          II. Grabar una funcion por cada fecha y horario
    for (fecha in fechas) {
      data <- rbind(data, data.frame(Nombre = nombre_peli, Fecha = fecha, Tipo = tipo, Horario = hora))
    }
  }
}

write.csv(data, "pelis_centro.csv", row.names = F, fileEncoding = "UTF-8")
