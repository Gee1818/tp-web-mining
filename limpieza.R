# Mergeo de los datasets obtenidos de cada web
# ------------------------------------------
library(tidyverse)
library(stringr)

# Set the working directory to the folder in which the script is saved
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Carga de los archivos csv
pelis_showcase   <- read.csv('pelis_showcase.csv')
pelis_centro     <- read.csv('pelis_centro.csv')
pelis_cinemark   <- read.csv('pelis_cinemark.csv')
pelis_cinepolis  <- read.csv('pelis_cinepolis.csv')
pelis_tipas      <- read.csv('pelis_tipas.csv')
pelis_monumental <- read.csv('pelis_monumental.csv')[, -1]

# Corrijo los formatos de cada dataset segun sea necesario
pelis_centro <- pelis_centro %>% 
  mutate(
    Fecha = ymd(Fecha),
    FormatoImagen = "2D",
    FormatoIdioma = case_when(
      Tipo == "SUB" ~ "Subtitulado", 
      .default = "Español"
    )
  )

pelis_cinemark <- pelis_cinemark %>% 
  mutate(
    Fecha = dmy(paste0(Fecha, "/", year(Sys.Date()))),
    Horario = gsub(" ", "", Horario),
    Tipo = str_remove(Tipo, fixed("DBOX + ")),
    FormatoImagen = str_extract(Tipo, "^[^\\ ]+"),
    FormatoIdioma = str_extract(Tipo, "(?<=\\ ).*"),
    FormatoIdioma = if_else(FormatoIdioma == "CASTELLANO", "Español", "Subtitulado")
    )

pelis_cinepolis <- pelis_cinepolis %>% 
  mutate(
    Fecha = ymd(Fecha),
    FormatoIdioma = str_extract(Tipo, "(?<= • ).*"),
    FormatoImagen = str_extract(FormatoIdioma, "^[^ • ]+"),
    FormatoIdioma = str_extract(FormatoIdioma, "(?<= • ).*")
  )

pelis_monumental <- pelis_monumental %>% 
  mutate(
    Fecha = ymd(Fecha),
    Horario = str_remove(Horario, "\\*"),
    FormatoImagen = "2D",
    FormatoIdioma = if_else(Tipo == "doblada", "Español", "Subtitulado"),
  )

pelis_showcase <- pelis_showcase %>% 
  mutate(
    Fecha = ymd(Fecha),
    FormatoImagen = str_extract(Tipo, "^[^-]+"),
    FormatoIdioma = str_extract(Tipo, "(?<=-).*"),
    FormatoIdioma = if_else(is.na(FormatoIdioma), "Español", FormatoIdioma)
  )

pelis_tipas <- pelis_tipas %>% 
  mutate(
    Fecha = ymd(Fecha),
    FormatoImagen = str_extract(Tipo, "^[^\\ ]+"),
    FormatoIdioma = str_extract(Tipo, "(?<=\\ ).*"),
    FormatoIdioma = if_else(is.na(FormatoIdioma), "Español", "Subtitulado")
  )


# Agrego una columna con la indicadora 
pelis_showcase$Cine   <- "Showcase"
pelis_cinepolis$Cine  <- "Cinépolis"
pelis_centro$Cine     <- "Cines del Centro"
pelis_tipas$Cine      <- "Las Tipas"
pelis_monumental$Cine <- "Monumental"
pelis_cinemark$Cine   <- "Cinemark Hoyts"

pelis <- rbind(
  pelis_centro, 
  pelis_cinemark,
  pelis_cinepolis, 
  pelis_monumental, 
  pelis_showcase, 
  pelis_tipas, 
)

pelis %>% pull(Tipo) %>% unique() #%>% length()
pelis %>% filter(Cine == "Showcase") %>% pull(Tipo) %>% unique()
# Creo que el formato de Showcase es la que va
