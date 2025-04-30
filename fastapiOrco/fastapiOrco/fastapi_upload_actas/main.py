from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, BigInteger, text, func
import pandas as pd
import pyodbc
import io

app = FastAPI()

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # URL de tu frontend en desarrollo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Datos de conexión
server = 'DESKTOP-7S64QUV'
database = 'DBTrep'
username = 'sa'
password = '123bolitas'

# Crear cadena de conexión para SQLAlchemy
connection_string = f"mssql+pyodbc://{username}:{password}@{server}/{database}?driver=ODBC+Driver+17+for+SQL+Server"
engine = create_engine(connection_string)
metadata = MetaData()

# Definir tabla resultados_actas
resultados_actas = Table(
    'resultados_actas', metadata,
    Column('id', Integer, primary_key=True, autoincrement=True),
    Column('nombre_pdf', String(255)),
    Column('codigo_recinto', Integer),
    Column('codigo_mesa_formato', String(50)),
    Column('nro_mesa', Integer),
    Column('electores_habilitados', Integer),
    Column('cant_tot_papeletas_anfora', Integer),
    Column('cant_tot_papeletas_no_usadas', Integer),
    Column('primer_partido', Integer),
    Column('segundo_partido', Integer),
    Column('tercer_partido', Integer),
    Column('cuarto_partido', Integer),
    Column('votos_validos', Integer),
    Column('votos_blancos', Integer),
    Column('votos_nulos', Integer),
    Column('tamano_pdf', BigInteger),
    Column('observacion', String),
    Column('estado_acta', String(50))
)

def insertar_recintos_faltantes(df, connection):
    codigos_nuevos = df['Cod_Mesa'].astype(int).unique()  # 🔥 Aquí usamos Cod_Mesa, no Cod_Recinto

    resultados = connection.execute(text("SELECT codigo_recinto FROM recintos_electorales"))
    codigos_existentes = {row[0] for row in resultados.fetchall()}

    codigos_faltantes = [int(c) for c in codigos_nuevos if int(c) not in codigos_existentes]

    for codigo in codigos_faltantes:
        connection.execute(
            text("""
                INSERT INTO recintos_electorales (codigo_recinto, codigo_distribucion, nombre, direccion)
                VALUES (:codigo, NULL, NULL, NULL)
            """),
            {"codigo": int(codigo)}
        )
def insertar_recintos_faltantes_cambio(df, connection):
    codigos_nuevos = df['CodigoRecintoElectoralD'].astype(int).unique()

    resultados = connection.execute(text("SELECT codigo_recinto FROM recintos_electorales"))
    codigos_existentes = {row[0] for row in resultados.fetchall()}

    codigos_faltantes = [int(c) for c in codigos_nuevos if int(c) not in codigos_existentes]

    for codigo in codigos_faltantes:
        connection.execute(
            text("""
                INSERT INTO recintos_electorales (codigo_recinto, codigo_distribucion, nombre, direccion)
                VALUES (:codigo, NULL, NULL, NULL)
            """),
            {"codigo": int(codigo)}
        )

@app.post("/upload-actas/")
async def upload_actas(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        df = pd.read_excel(io.BytesIO(contents))

        required_columns = ['NombrePdf', 'Cod_Recinto', 'Cod_Mesa', 'Nro_Mesa', 'Electores_Habilitados',
                            'Cant_Tot_Papeletas_Anfora', 'Cant_Tot_Papeletas_No_Usadas',
                            'Primer_Partido', 'Segundo_Partido', 'Tercer_Partido', 'Cuarto_Partido',
                            'Votos_Validos', 'Votos_Blancos', 'Votos_Nulos', 'Tamano_PDF']

        if not all(col in df.columns for col in required_columns):
            raise HTTPException(status_code=400, detail="El archivo no tiene todas las columnas requeridas.")

        razon_invalidez_presente = 'Razon_Invalidez' in df.columns

        records = []
        for _, row in df.iterrows():
            codigo_mesa_formato = str(row['Cod_Recinto'])
            codigo_mesa = int(codigo_mesa_formato.split('-')[0])
            codigo_recinto = int(row['Cod_Mesa'])

            observacion = row['Razon_Invalidez'] if razon_invalidez_presente and not pd.isna(row['Razon_Invalidez']) else None
            estado_acta = 'Invalido' if observacion else 'Valido'

            record = {
                'nombre_pdf': row['NombrePdf'],
                'codigo_recinto': codigo_recinto,
                'codigo_mesa_formato': codigo_mesa,
                'nro_mesa': int(row['Nro_Mesa']),
                'electores_habilitados': int(row['Electores_Habilitados']),
                'cant_tot_papeletas_anfora': int(row['Cant_Tot_Papeletas_Anfora']),
                'cant_tot_papeletas_no_usadas': int(row['Cant_Tot_Papeletas_No_Usadas']),
                'primer_partido': int(row['Primer_Partido']),
                'segundo_partido': int(row['Segundo_Partido']),
                'tercer_partido': int(row['Tercer_Partido']),
                'cuarto_partido': int(row['Cuarto_Partido']),
                'votos_validos': int(row['Votos_Validos']),
                'votos_blancos': int(row['Votos_Blancos']),
                'votos_nulos': int(row['Votos_Nulos']),
                'tamano_pdf': int(row['Tamano_PDF']),
                'observacion': observacion,
                'estado_acta': estado_acta
            }
            records.append(record)

        with engine.begin() as connection:
            insertar_recintos_faltantes(df, connection)
            connection.execute(resultados_actas.insert(), records)

        return {"message": f"Se insertaron {len(records)} registros exitosamente."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/upload-actas-oficial/")
async def upload_actas_cambio(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        df = pd.read_excel(io.BytesIO(contents))

        required_columns = [
            'CodigoMesa', 'Mesa', 'CantidadHabilitada', 'CantidadAnfora',
            'PapeletasNoUsadas', 'Partido1', 'Partido2', 'Partido3', 'Partido4',
            'Validos', 'Blancos', 'Nulos', 'CodigoRecintoElectoralD'
        ]

        if not all(col in df.columns for col in required_columns):
            raise HTTPException(status_code=400, detail="El archivo no tiene todas las columnas requeridas.")

        records = []
        for _, row in df.iterrows():
            razones_invalidez = []

            try:
                v1 = int(row['Validos']) == sum(map(int, [
                    row['Partido1'], row['Partido2'], row['Partido3'], row['Partido4'], row['Blancos']
                ]))
                v2 = int(row['CantidadAnfora']) == sum(map(int, [
                    row['Validos'], row['Nulos']
                ]))
                v3 = int(row['CantidadHabilitada']) == sum(map(int, [
                    row['CantidadAnfora'], row['PapeletasNoUsadas']
                ]))

                if not v1:
                    razones_invalidez.append("La suma de votos no coincide con votos blancos y partidos.")
                if not v2:
                    razones_invalidez.append("La cantidad de papeletas en ánfora no coincide con votos válidos y nulos.")
                if not v3:
                    razones_invalidez.append("Electores habilitados no coincide con papeletas en ánfora más papeletas no usadas.")

                validacion = v1 and v2 and v3
                razon_invalidez = ", ".join(razones_invalidez) if not validacion else None

            except ValueError:
                validacion = False
                razon_invalidez = "Error en la conversión de valores numéricos."

            record = {
                'nombre_pdf': None,
                'codigo_recinto': int(row['CodigoRecintoElectoralD']),
                'codigo_mesa_formato': int(row['CodigoMesa']),
                'nro_mesa': int(row['Mesa']),
                'electores_habilitados': int(row['CantidadHabilitada']),
                'cant_tot_papeletas_anfora': int(row['CantidadAnfora']),
                'cant_tot_papeletas_no_usadas': int(row['PapeletasNoUsadas']),
                'primer_partido': int(row['Partido1']),
                'segundo_partido': int(row['Partido2']),
                'tercer_partido': int(row['Partido3']),
                'cuarto_partido': int(row['Partido4']),
                'votos_validos': int(row['Validos']),
                'votos_blancos': int(row['Blancos']),
                'votos_nulos': int(row['Nulos']),
                'tamano_pdf': None,
                'observacion': razon_invalidez,
                'estado_acta': 'Valido' if validacion else 'Invalido'
            }
            records.append(record)

        with engine.begin() as connection:
            insertar_recintos_faltantes_cambio(df, connection)
            connection.execute(resultados_actas.insert(), records)

        return {"message": f"Se insertaron {len(records)} registros exitosamente desde el archivo de cambio."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/totales-nacionales/")
async def get_totales_nacionales():
    try:
        with engine.connect() as connection:
            # Obtener totales de votos válidos, nulos y blancos
            query = text("""
                SELECT 
                    SUM(ra.votos_validos) as total_validos,
                    SUM(ra.votos_nulos) as total_nulos,
                    SUM(ra.votos_blancos) as total_blancos
                FROM resultados_actas ra
                JOIN recintos_electorales re ON ra.codigo_recinto = re.codigo_recinto
                JOIN distribucion_territorial dt ON re.codigo_distribucion = dt.codigo_distribucion
                WHERE ra.estado_acta = 'Valido'
            """)
            result = connection.execute(query)
            totales = result.fetchone()
            
            return {
                "validos": int(totales[0]) if totales[0] else 0,
                "nulos": int(totales[1]) if totales[1] else 0,
                "blancos": int(totales[2]) if totales[2] else 0
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/resultados-departamento/{departamento}")
async def get_resultados_departamento(departamento: str):
    try:
        with engine.connect() as connection:
            # Obtener resultados por departamento usando distribucion_territorial
            query = text("""
                SELECT 
                    SUM(ra.primer_partido) as mas,
                    SUM(ra.segundo_partido) as cc,
                    SUM(ra.tercer_partido) as creemos,
                    SUM(ra.cuarto_partido) as fpv,
                    SUM(ra.votos_validos) as validos,
                    SUM(ra.votos_nulos) as nulos,
                    SUM(ra.votos_blancos) as blancos
                FROM resultados_actas ra
                JOIN recintos_electorales re ON ra.codigo_recinto = re.codigo_recinto
                JOIN distribucion_territorial dt ON re.codigo_distribucion = dt.codigo_distribucion
                WHERE dt.departamento = :departamento AND ra.estado_acta = 'Valido'
            """)
            result = connection.execute(query, {"departamento": departamento})
            resultados = result.fetchone()
            
            return {
                "oficial": {
                    "mas": str(resultados[0]) if resultados[0] else "0",
                    "cc": str(resultados[1]) if resultados[1] else "0",
                    "creemos": str(resultados[2]) if resultados[2] else "0",
                    "fpv": str(resultados[3]) if resultados[3] else "0"
                },
                "totales": {
                    "validos": int(resultados[4]) if resultados[4] else 0,
                    "nulos": int(resultados[5]) if resultados[5] else 0,
                    "blancos": int(resultados[6]) if resultados[6] else 0
                }
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


