from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import pandas as pd

# Headless Firefox setup
print("Creando driver...")
options = Options()
options.add_argument("--headless")
driver = webdriver.Firefox(options=options)

# 1. Go to the Showcase website
print("Accediendo a la página web...")
driver.get("https://todoshowcase.com/")
time.sleep(1.5)

# 2. Get Rosario's movie catalog
urls_pelis = []
try:
    menu_rosario = driver.find_element(By.ID, "cartelera_cine_40218")
    pelis = menu_rosario.find_elements(By.CLASS_NAME, "boxfilm")
    for peli in pelis:
        afiche = peli.find_element(By.CLASS_NAME, "afiche-pelicula")
        link = afiche.find_element(By.CSS_SELECTOR, "a").get_attribute("href")
        urls_pelis.append(link)
except:
    print("Rosario movie catalog not found.")

data = []

# 3. Loop through each movie URL
for url in urls_pelis:
    driver.get(url)
    time.sleep(1.5)
    
    # a. Get movie name
    try:
        nombre = driver.find_element(By.CSS_SELECTOR, "h2").text
    except:
        nombre = "Desconocido"
    print(f"Película: {nombre}")

    # b. Iterate through available dates
    fechas = driver.find_elements(By.CLASS_NAME, "op_day")
    for fecha_elem in fechas:
        try:
            fecha = fecha_elem.get_attribute("value")
            driver.execute_script("arguments[0].click();", fecha_elem)
            driver.execute_script("arguments[0].click();", driver.find_element(By.CSS_SELECTOR, "h3"))
            time.sleep(0.5)

            opciones_div = driver.find_element(By.ID, "ui-accordion-op_cinemas-panel-0")
            opciones = opciones_div.find_elements(By.CSS_SELECTOR, "div")

            tipo = None
            for i, opcion in enumerate(opciones):
                if i % 2 == 0:
                    tipo = opcion.text.strip()
                else:
                    botones = opcion.find_elements(By.CSS_SELECTOR, "button")
                    for btn in botones:
                        horario = btn.text.strip()
                        data.append({"Nombre": nombre, "Fecha": fecha, "Tipo": tipo, "Horario": horario})
        except Exception as e:
            print(f"Error processing date for {nombre}: {e}")

# Save to CSV
df = pd.DataFrame(data)
df.to_csv("pelis_showcase.csv", index=False, encoding="utf-8")

driver.quit()
