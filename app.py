import streamlit as st
import pandas as pd
from datetime import datetime, timedelta
from streamlit_calendar import calendar
from os import listdir
import re

# Load the combined and cleaned dataset
file_path = "pelis_combinado_clean.csv"
df = pd.read_csv(file_path)
df.reset_index(inplace=True)

# Ensure the 'Fecha' column is in datetime format
df['Fecha'] = pd.to_datetime(df['Fecha'])

# Streamlit App Layout
st.set_page_config(
    page_title="Cinefy Rosario",
    page_icon="🎬",
    layout="wide",
    initial_sidebar_state="expanded",
)
# Inject CSS to hide fullscreen button
st.markdown(
    """
    <style>
    button[title="View fullscreen"] {
        visibility: hidden;
    }
    p, select {
        font-size: 14pt;
    }
    </style>
    """,
    unsafe_allow_html=True
)

# Create two columns
left_col, right_col = st.columns(2)

# Add stuff to the left column
with left_col:
    st.image("cinefy_logo.png", width=300)

    # Dropdown to select a movie (only display dropdown if more than one movie exists)
    nombres = sorted(df['Nombre'].unique())
    if len(nombres) > 1:
        selected_movie = st.selectbox('Seleccione una película', nombres)
    else:
        selected_movie = nombres[0]
        st.write("Película disponible:", selected_movie)

    # Filter dataset by the selected movie
    df_filter1 = df[df["Nombre"] == selected_movie]

    # Projection Type filter (FormatoImagen)
    projection_types = sorted(df_filter1["FormatoImagen"].unique())
    if len(projection_types) > 1:
        selected_type = st.selectbox("Seleccione tipo de proyección", projection_types)
    else:
        selected_type = projection_types[0]
        st.write("Proyección disponible:", selected_type)

    # Filter the dataset based on the selected projection type
    df_filter2 = df_filter1[df_filter1["FormatoImagen"] == selected_type]

    # Language Format filter (FormatoIdioma)
    languages = sorted(df_filter2["FormatoIdioma"].unique())
    if len(languages) > 1:
        selected_language = st.selectbox("Seleccione formato de lenguaje", languages)
    else:
        selected_language = languages[0]
        st.write("Lenguaje disponible:", selected_language)

    # Further filter the dataset based on the selected language format
    df_filter3 = df_filter2[df_filter2["FormatoIdioma"] == selected_language]

    # Cinema filter (Cine)
    cinemas = sorted(df_filter3["Cine"].unique())
    checkbox_states = {}
    with st.expander("Seleccione cine", expanded = True):
        for cinema in cinemas:
            checkbox_states[cinema] = st.checkbox(cinema, value = True)
    selected_cinemas = [cine for cine, selected in checkbox_states.items() if selected]

    # Filter the DataFrame based on selected cinemas
    df_filter4 = df_filter3[df_filter3["Cine"].isin(selected_cinemas)]


# Add stuff to the right column
with right_col:
    # Prepare calendar events from the filtered data
    calendar_events = []
    for _, row in df_filter4.iterrows():
        # Combine the date and time from 'Fecha' and 'Horario' columns
        start_datetime = datetime.combine(row["Fecha"], datetime.strptime(row["Horario"], "%H:%M").time())
        calendar_events.append({
            "title": row["Cine"],
            "start": start_datetime.strftime("%Y-%m-%dT%H:%M:%S"),
            "resourceId": row["Cine"],
        })

    # Display a subheader with the selected movie
    st.subheader(f'Proyecciones para {selected_movie}')

    # Calendar options with pre-defined resource listings for the cinemas
    calendar_options = {
        "editable": False,
        "selectable": True,
        "headerToolbar": {
            "left": "today prev,next",
            "center": "title",
            "right": "dayGridDay,dayGridWeek,dayGridMonth",
        },
        "initialView": "dayGridWeek",  # Set the default view to weekly
        "resources": [
            {"id": "Showcase", "title": "Showcase", "eventBorderColor": "#1717dd"},
            {"id": "Cinépolis", "title": "Cinépolis", "eventBorderColor": "#17dd17"},
            {"id": "Centro", "title": "Cines del Centro", "eventBorderColor": "#dddd17"},
            {"id": "Tipas", "title": "Las Tipas", "eventBorderColor": "#dd1717"},
        ],
    }

    # Render the calendar with a key that ensures proper updates for each filter change
    calendar(
        events=calendar_events,
        options=calendar_options,
        key=f"{selected_movie}_{selected_type}_{selected_language}_{len(selected_cinemas)}"
    )

