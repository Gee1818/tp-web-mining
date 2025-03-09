from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import time
import pandas as pd
from datetime import datetime

# Set up Firefox options
options = Options()
options.add_argument("--headless")  # Run in headless mode (no UI)

# Set up the WebDriver
service = Service("driver/firefox/geckodriver")
driver = webdriver.Firefox(service=service, options=options)

URL = "https://www.nuevomonumental.com/"

df = pd.DataFrame(columns=["Nombre", "Fecha","Tipo", "Horario"])

# Asumo que el año actual es el año en el que se corre el script
year = datetime.now().year

# Diccionario para convertir nombres de meses a números
meses_dict = {
    "Enero": 1,
    "Febrero": 2,
    "Marzo": 3,
    "Abril": 4,
    "Mayo": 5,
    "Junio": 6,
    "Julio": 7,
    "Agosto": 8,
    "Septiembre": 9,
    "Octubre": 10,
    "Noviembre": 11,
    "Diciembre": 12
}

driver.get(URL)

time.sleep(5)

# Find buttons for dates

fechas = driver.find_elements(By.CLASS_NAME, "btnFiltroFecha")

i = 1

# Busco las primeras 7 fechas
for fecha_btn in fechas[:7]:

    print(f"Buscando pelis para la fecha {i}/7")

    fecha_btn.click()
    time.sleep(5)

    dia = fecha_btn.find_element(By.CLASS_NAME, "fecha-numero-text").text.strip()
    mes = fecha_btn.find_element(By.CLASS_NAME, "fecha-mes").text.strip()

    mes_num = meses_dict[mes]

    fecha = datetime(year, mes_num, int(dia))

    # Find the movies

    peliculas = driver.find_elements(By.CLASS_NAME, "movie")

    for pelicula in peliculas:
        
        nombre = pelicula.find_element(By.CLASS_NAME, "movie__title").text.strip()

        horarios = pelicula.find_elements(By.CLASS_NAME, "time-select__item")

        for _ in horarios:

            horario = _.text.strip()

            tipo = "subtitulada"

            try:
                # Try to find a <span> inside the <li>
                span_element = _.find_element(By.TAG_NAME, "span")
                
            except:
                # If no <span> is found, print the time normally
                tipo = "doblada"

            #print(f"Nombre: {nombre} - Horario: {horario} - Tipo: {tipo}")
            new_row = {"Nombre": nombre, "Fecha": fecha, "Tipo": tipo, "Horario": horario}
            df.loc[len(df)] = new_row

    i += 1

driver.quit()

df.to_csv("pelis_monumental.csv")
print("Scraping finalizado")