library(tidyverse)

pelis_showcase  <- read.csv('pelis_showcase.csv')
pelis_cinepolis <- read.csv('pelis_cinepolis.csv')
pelis_centro    <- read.csv('pelis_centro.csv')
pelis_tipas     <- read.csv('pelis_tipas.csv')

pelis_showcase$Cine  <- "Showcase"
pelis_cinepolis$Cine <- "Cinépolis"
pelis_centro$Cine    <- "Cines del Centro"
pelis_tipas$Cine     <- "Las Tipas"

pelis <- rbind(pelis_showcase, pelis_cinepolis, pelis_centro, pelis_tipas)

pelis %>% pull(Tipo) %>% unique() #%>% length()
