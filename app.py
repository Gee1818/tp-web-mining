import streamlit as st
import pandas as pd
from datetime import datetime, timedelta
from streamlit_calendar import calendar

# Convert the data to a DataFrame
df_showcase = pd.read_csv('pelis_showcase.csv')
df_showcase['Fecha'] = pd.to_datetime(df_showcase['Fecha'])
df_showcase['Cine'] = 'Showcase'

df_cinepolis = pd.read_csv('pelis_cinepolis.csv')
df_cinepolis['Fecha'] = pd.to_datetime(df_cinepolis['Fecha'])
df_cinepolis['Cine'] = 'Cinépolis'

df = pd.concat([df_showcase, df_cinepolis])

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
        {"id": "Showcase", "title": "Showcase", "eventBorderColor": "#1717dd"},
        {"id": "Cinépolis", "title": "Cinépolis", "eventBorderColor": "#17dd17"},
    ],
}

calendar(
    events=calendar_events,
    options=calendar_options,
    key=f"{selected_movie}_{selected_type}"
)
