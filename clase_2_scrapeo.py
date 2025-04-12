from playwright.sync_api import sync_playwright
import re

def separar_cadena(texto):
    # Usamos una expresión regular para insertar una coma antes de cualquier letra mayúscula que no esté al principio
    return re.sub(r'(?<=[a-zA-Z])(?=[A-Z])', r', ', texto)

def scrape_workremoto():
    url = "https://workremoto.com/empleos/"
    
    # Abre un navegador sin interfaz gráfica en la URL indicada
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url)
        
        # Esperar que cargue la lista de empleos
        page.wait_for_selector(".awsm-job-item")
        
        jobs = []

        while True:
            # Obtener todos los trabajos visibles en la página
            job_elements = page.query_selector_all(".awsm-job-item")
            
            for job in job_elements:
                title = job.query_selector(".awsm-job-post-title")
                language = job.query_selector(".awsm-job-specification-job-languaje")
                dedication = job.query_selector(".awsm-job-specification-job-location")
                
                language_text = language.inner_text() if language else "N/A"
                language_separado = separar_cadena(language_text)

                job_data = {
                    "Título": title.inner_text() if title else "N/A",
                    "Idioma": language_separado,
                    "Dedicación": dedication.inner_text() if dedication else "N/A"
                }
                jobs.append(job_data)
            
            # Esperar el botón "Cargar más" y hacer clic si está presente
            load_more_button = page.query_selector(".awsm-load-more.awsm-load-more-btn")
            if load_more_button:
                load_more_button.click()
                # Esperar que se carguen más trabajos antes de continuar
                page.wait_for_selector(".awsm-job-item", state="attached")  # Esperar a que se carguen más elementos
            else:
                # Si el botón ya no está, salir del bucle
                break
        
        browser.close()
    
    return jobs

if __name__ == "__main__":
    results = scrape_workremoto()

    # Definir el ancho de las columnas para alinearlas
    column_widths = {
        "Título": 60,
        "Idioma": 20,
        "Dedicación": 25
    }

    # Imprimir encabezados
    header = f"{'Título'.ljust(column_widths['Título'])} {'Idioma'.ljust(column_widths['Idioma'])} {'Dedicación'.ljust(column_widths['Dedicación'])}"
    print(header)
    print("-" * len(header))  # Línea separadora

    # Imprimir cada fila de datos
    for job in results:
        print(f"{job['Título'].ljust(column_widths['Título'])} {job['Idioma'].ljust(column_widths['Idioma'])} {job['Dedicación'].ljust(column_widths['Dedicación'])}")
