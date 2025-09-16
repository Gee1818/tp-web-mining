from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
import pandas as pd
import time
import re
from datetime import datetime

# Configure headless Firefox
options = Options()
options.headless = True
driver = webdriver.Firefox(options=options)

# 1. Go to the website
driver.get("https://rosario.lastipas.com.ar/es-AR")
time.sleep(5)

# Get date buttons and extract text
btns_fechas = driver.find_elements(By.CSS_SELECTOR, "#snapDateSlider > div")
btn_derecha = driver.find_elements(By.CSS_SELECTOR, ".gap-4 > button")[1]  # Click right arrow after each selection

meses_es = {
    "Enero": 1, "Febrero": 2, "Marzo": 3, "Abril": 4, "Mayo": 5, "Junio": 6,
    "Julio": 7, "Agosto": 8, "Septiembre": 9, "Octubre": 10, "Noviembre": 11, "Diciembre": 12
}

fechas = []
btns_actuales = []

for btn in btns_fechas:
    texto = btn.text.strip()
    match = re.search(r"(\d+)\s+([A-Za-z]+)", texto)
    if match:
        dia = int(match.group(1))
        mes = meses_es.get(match.group(2), 1)
        fecha = datetime(datetime.today().year, mes, dia).strftime("%Y-%m-%d")
        fechas.append(fecha)
        btns_actuales.append(btn)

data = []

# 2. Iterate through each date
print(fechas)
for i, fecha in enumerate(fechas):
    try:
        btns_actuales[i].click()
        btn_derecha.click()  # simulate swiping
        time.sleep(1)

        pelis = driver.find_elements(By.XPATH, "//div[contains(@class, 'max-w-')]")

        for peli in pelis:
            try:
                # I. Movie name and format
                nombre_raw = peli.find_element(By.CSS_SELECTOR, "h4").text
                nombre = re.sub(r"\s*(2D|3D|ATMOS|4D).*", "", nombre_raw).strip()

                formato = peli.find_elements(By.CSS_SELECTOR, "p")[6].text  # 7th <p> tag

                # II. Get showtimes
                horarios = peli.find_elements(By.CSS_SELECTOR, "span.text-primary.flex")
                for h in horarios:
                    contenido = h.text.strip().split('\n')
                    if len(contenido) == 2:
                        idioma, hora = contenido
                        tipo = f"{formato} {idioma}".strip()
                    else:
                        hora = contenido[0]
                        tipo = formato
                    data.append({"Nombre": nombre, "Fecha": fecha, "Tipo": tipo, "Horario": hora})
            except Exception as e:
                print(f"Error processing movie: {e}")
    except Exception as e:
        print(f"Error on date {fecha}: {e}")

# Save to CSV
df = pd.DataFrame(data)
df.to_csv("pelis_tipas.csv", index=False, encoding="utf-8")

driver.quit()
