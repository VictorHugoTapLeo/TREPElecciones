import streamlit as st
import pandas as pd
from sqlalchemy import create_engine

# Conexión a tu base de datos
engine = create_engine("mssql+pyodbc://sa:univalle.@DESKTOP-5VL7RJV/DBTrep?driver=ODBC+Driver+17+for+SQL+Server")

st.title("📊 Dashboard de Actas Electorales")

# Leer las actas desde la base de datos
df = pd.read_sql("SELECT * FROM resultados_actas", engine)

# Mostrar el DataFrame
st.dataframe(df)

# Mostrar métricas
st.metric(label="Total de Actas Subidas", value=len(df))

# Mostrar gráfico de votos
if not df.empty:
    votos = df[['primer_partido', 'segundo_partido', 'tercer_partido', 'cuarto_partido']].sum()
    st.bar_chart(votos)
else:
    st.write("No hay datos para mostrar aún.")
