# Mergeo de los datasets obtenidos de cada web
# ------------------------------------------
library(tidyverse)

# Carga de los archivos csv
pelis_showcase   <- read.csv('pelis_showcase.csv')
pelis_cinepolis  <- read.csv('pelis_cinepolis.csv')
pelis_centro     <- read.csv('pelis_centro.csv')
pelis_tipas      <- read.csv('pelis_tipas.csv')
pelis_monumental <- read.csv('pelis_monumental.csv')[, -1]
pelis_cinemark   <- read.csv('pelis_cinemark.csv')

# Corrijo los formatos de cada dataset segun sea necesario
pelis_centro <- pelis_centro %>% 
  mutate(Fecha = ymd(Fecha))

pelis_cinemark <- pelis_cinemark %>% 
  mutate(
    Fecha = dmy(paste0(data$Fecha, "/", year(Sys.Date()))),
    Horario = gsub(" ", "", Horario)
    )

pelis_cinepolis <- pelis_cinepolis %>% 
  mutate(Fecha = ymd(Fecha))

pelis_monumental <- pelis_monumental %>% 
  mutate(Fecha = ymd(Fecha))

pelis_showcase <- pelis_showcase %>% 
  mutate(Fecha = ymd(Fecha))

pelis_tipas <- pelis_tipas %>% 
  mutate(Fecha = ymd(Fecha))


# Agrego una columna con la indicadora 
pelis_showcase$Cine   <- "Showcase"
pelis_cinepolis$Cine  <- "Cinépolis"
pelis_centro$Cine     <- "Cines del Centro"
pelis_tipas$Cine      <- "Las Tipas"
pelis_monumental$Cine <- "Monumental"
pelis_cinemark$Cine   <- "Cinemark Hoyts"

pelis <- rbind(pelis_showcase, pelis_cinepolis, pelis_centro, pelis_tipas, pelis_monumental, pelis_cinemark)

pelis %>% pull(Tipo) %>% unique() #%>% length()
pelis %>% filter(Cine == "Showcase") %>% pull(Tipo) %>% unique()
# Creo que el formato de Showcase es la que va
