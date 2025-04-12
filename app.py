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
st.title('Cinema Movie Projections')

# Dropdown to select a movie
nombres = sorted(df['Nombre'].unique())
selected_movie = st.selectbox('Select a Movie', nombres)

# Filter dataset by selected movie
filtered_df = df[df["Nombre"] == selected_movie]

# Dropdown to select projection type (sorted alphabetically)
projection_types = sorted(filtered_df["FormatoImagen"].unique())
selected_type = st.selectbox("Select Projection Type", projection_types)

# Filter the dataset based on selected movie
filtered_data = filtered_df[filtered_df["FormatoImagen"] == selected_type]

calendar_events = []
for _, row in filtered_data.iterrows():
    start_datetime = datetime.combine(row["Fecha"], datetime.strptime(row["Horario"], "%H:%M").time())

    calendar_events.append({
        "title": row["Nombre"],
        "start": start_datetime.strftime("%Y-%m-%dT%H:%M:%S"),
        "resourceId": row["Cine"],
    })

# Show the filtered projections in a calendar-like format
st.subheader(f'Projections for {selected_movie}')

calendar_options = {
    "editable": False,
    "selectable": True,
    "headerToolbar": {
        "left": "today prev,next",
        "center": "title",
        "right": "dayGridDay,dayGridWeek,dayGridMonth",
    },
    "initialView": "dayGridMonth",
    "resources": [
        {"id": "showcase", "title": "Showcase", "eventBorderColor": "#1717dd"},
        {"id": "cinepolis", "title": "Cinépolis", "eventBorderColor": "#17dd17"},
        {"id": "centro", "title": "Cines del Centro", "eventBorderColor": "#dddd17"},
        {"id": "tipas", "title": "Las Tipas", "eventBorderColor": "#dd1717"},
    ],
}

calendar(
    events=calendar_events,
    options=calendar_options,
    key=f"{selected_movie}_{selected_type}"
)
