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

driver.get(URL)

cartelera = driver.find_element(By.ID, "listaCartelera")

peliculas = cartelera.find_elements(By.CLASS_NAME, "col-md-7")

# titulos = []

# for pelicula in peliculas:
#     titulo = pelicula.find_element(By.CLASS_NAME_NAME, "movie_title")
#     titulos.append(titulo.text.strip())


driver.quit()

peliculas