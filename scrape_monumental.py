from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import time

# Set up Firefox options
options = Options()
options.add_argument("--headless")  # Run in headless mode (no UI)

# Set up the WebDriver
service = Service("driver/firefox/geckodriver")
driver = webdriver.Firefox(service=service, options=options)

URL = "https://www.nuevomonumental.com/"

df_nombre = []
df_fecha = []
df_tipo = []
df_horario = []

driver.get(URL)

time.sleep(5)

#cartelera = driver.find_element(By.ID, "listaCartelera")

peliculas = driver.find_elements(By.CLASS_NAME, "movie")

fechas = None

tipos = None

print(len(peliculas))

for pelicula in peliculas:
    print(50*"-")
    
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

        print(f"Nombre: {nombre} - Horario: {horario} - Tipo: {tipo}")


driver.quit()