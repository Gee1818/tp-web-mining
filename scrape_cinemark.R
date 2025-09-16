# Sitio: Cinemark Hoyts
# Autor: Joaquín Bermejo
# Fecha: 15 de septiembre
# ------------------------------------------
#  1. Acceder a la pagina
#  2. Aceptar cookies
#  3. Obtener el catalogo para el cine de Rosario
#  4. Para cada pelicula:
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
remote_driver <- rsDriver(browser = "firefox", chromever = NULL, verbose = F, phantomver = NULL)
remDr <- remote_driver$client

## 2. Acceder a la pagina
remDr$navigate("https://www.cinemarkhoyts.com.ar/")
Sys.sleep(5)

## 3. Obtener el catalogo para el cine de Rosario
btn_elegir_peli <- remDr$findElement("xpath", "//button[contains(normalize-space(.), 'Elegí Película')]")
remDr$executeScript("arguments[0].click();", list(btn_elegir_peli))
Sys.sleep(1)
span_elegir_cine <- remDr$findElement("xpath", "//span[contains(normalize-space(.), 'aquí')]")
remDr$executeScript("arguments[0].click();", list(span_elegir_cine))
Sys.sleep(1)
opcion_rosario <- remDr$findElement("xpath", "//p[contains(normalize-space(.), 'Hoyts Rosario')]/..")
checkbox_rosario <- opcion_rosario$findChildElement("css selector", "div > div > label > span > input")
remDr$executeScript("arguments[0].click();", list(checkbox_rosario))
h4_confirmar_cine <- remDr$findElement("xpath", "//h4[contains(normalize-space(.), 'Seleccionar')]")
remDr$executeScript("arguments[0].click();", list(h4_confirmar_cine))

## Se obtienen las peliculas para iterar
div_formato <- remDr$findElement("xpath", "//button[contains(normalize-space(.), 'Formato')]/ancestor::div[3]")
div_pelis <- div_formato$findChildElement("xpath", "following-sibling::div[1]")
anchors_pelis <- div_pelis$findChildElements("css selector", "a")
urls_pelis <- unlist(lapply(anchors_pelis, function(x) x$getElementAttribute("href")[[1]]))

# Creacion del dataset para almacenar la informacion
data <- data.frame(Nombre = NULL, Fecha = NULL, Tipo = NULL, Horario = NULL)

## 4. Para cada pelicula
for (url_peli in urls_pelis) {
  remDr$navigate(url_peli)
  Sys.sleep(2)
  # Obtengo el nombre de la pelicula
  nombre <- remDr$findElement("css selector", "h1")$getElementText()[[1]]
  # Obtengo las fechas donde hay funcion (si las)
  container_fechas <- remDr$findElement("xpath", "//h2[contains(normalize-space(.), 'Horarios')]")
  fechas <- container_fechas$findChildElements("xpath", "following-sibling::div[1]/div/section/div/div/div/div/div/div")
  # Navegar paginacion (cuando hay muchas fechas hay que apretar una flecha para ir pasando por el carrusel)
  paginacion <- remDr$findElement("class name", "carousel-pagination__box")
  for (i in seq_along(fechas)) {
    if (i > 5) tryCatch(
      {
        btn_seguir <- remDr$findElement("css selector", ".next-date-carousel")
        remDr$executeScript("arguments[0].click();", list(btn_seguir)) # TODO !
      },
      error = function(x) return()
    )
    # Vuelvo a agarrar las fechas (las ultimas tienen texto vacio hasta que se renderizan en pantalla)
    container_fechas <- remDr$findElement("xpath", "//h2[contains(normalize-space(.), 'Horarios')]")
    fechas <- container_fechas$findChildElements("xpath", "following-sibling::div[1]/div/section/div/div/div/div/div/div")
    # Seleccionar la fecha correspondiente
    remDr$executeScript("arguments[0].click();", list(fechas[[i]]$findChildElement("css selector", "div")))
    Sys.sleep(1)
    fecha_text <- sub(".*\\n", "", fechas[[i]]$getElementText()[[1]])
    if (fecha_text == "HOY") {
      fecha <- Sys.Date()
    } else {
      meses <- c(
        ENE = 1, FEB = 2, MAR = 3, ABR = 4, MAY = 5, JUN = 6,
        JUL = 7, AGO = 8, SEP = 9, OCT = 10, NOV = 11, DIC = 12
      )
      # Separar día y mes
      parts <- strsplit(fecha_text, "/")[[1]]
      dia <- as.integer(parts[1])
      mes <- meses[toupper(parts[2])]
      # Armar fecha con el año actual
      hoy <- Sys.Date()
      anio <- year(hoy)
      fecha <- as.Date(sprintf("%04d-%02d-%02d", anio, mes, dia))
      if (fecha < hoy) { # Si la fecha ya pasó este año, usar el próximo año
        fecha <- as.Date(sprintf("%04d-%02d-%02d", anio + 1, mes, dia))
      }
    }
    p_direccion <- remDr$findElement("xpath", "//p[contains(normalize-space(.), 'Dirección: Nansen 255, Portal Rosario')]")
    div_formatos <- p_direccion$findChildElement("xpath", "following-sibling::section[1]/div")
    info <- unlist(strsplit(div_formatos$getElementText()[[1]], "\n(?:· )?"))
    es_hora <- grepl("^\\d{1,2}:\\d{2}", info) # Detectamos horas (por regex simple)
    formato_actual <- "" # Vamos acumulando formato hasta que llegue una hora
    for (i in seq_along(info)) {
      if (!es_hora[i]) {
        # Es parte del formato → actualizamos
        formato_actual <- if_else(formato_actual == "" | nchar(formato_actual) > 12, info[i], paste(formato_actual, info[i]))
      } else {
        # Es hora → agregamos fila al dataset
        hora <- substr(info[i], 1, nchar(info[i])-3)
        data <- rbind(data, data.frame(Nombre = nombre, Fecha = fecha, Tipo = formato_actual, Horario = hora))
      }
    }
  }
}

remDr$close()

# Se exporta el dataset en formato csv
write.csv(data, "pelis_cinemark.csv", row.names = F, fileEncoding = "UTF-8")
