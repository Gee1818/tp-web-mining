import streamlit as st
import pandas as pd
from datetime import datetime, timedelta
from streamlit_calendar import calendar
from os import listdir
import re

# Read data
def find_csv_filenames( path_to_dir, suffix=".csv" ):
    filenames = listdir(path_to_dir)
    return [ filename for filename in filenames if filename.endswith( suffix ) ]

# Convert the data to a DataFrame
datos_cines = []
filenames = find_csv_filenames("./")
for filename in filenames:
    df_cine = pd.read_csv(filename)
    df_cine['Fecha'] = pd.to_datetime(df_cine['Fecha'])
    df_cine['Cine'] = re.search(r"_(.*?)\.", filename).group(1)
    datos_cines.append(df_cine)

df = pd.concat(datos_cines)

# Streamlit App Layout
st.title('Cinema Movie Projections')

# Dropdown to select a movie
nombres = sorted(df['Nombre'].unique())
selected_movie = st.selectbox('Select a Movie', nombres)

# Filter dataset by selected movie
filtered_df = df[df["Nombre"] == selected_movie]

# Dropdown to select projection type (sorted alphabetically)
projection_types = sorted(filtered_df["Tipo"].unique())
selected_type = st.selectbox("Select Projection Type", projection_types)

# Filter the dataset based on selected movie
filtered_data = filtered_df[filtered_df["Tipo"] == selected_type]

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
