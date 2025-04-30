import { useState, useEffect } from 'react'
import './App.css'
import MapaBolivia from './components/MapaBolivia'
import TotalesNacionales from './components/TotalesNacionales'
import UploadActas from './components/UploadActas'

function App() {
  const [departamentos, setDepartamentos] = useState([])
  const [totalesNacionales, setTotalesNacionales] = useState({
    validos: 0,
    nulos: 0,
    blancos: 0
  })
  const [loading, setLoading] = useState(true)
  const [serverError, setServerError] = useState(false)

  const resetData = () => {
    const departamentosList = [
      "La Paz", "Cochabamba", "Santa Cruz", "Oruro", 
      "Potosí", "Tarija", "Chuquisaca", "Beni", "Pando"
    ]
    
    const emptyData = departamentosList.map(depto => ({
      nombre: depto,
      resultados: {
        oficial: {
          mas: "0",
          cc: "0",
          creemos: "0",
          fpv: "0"
        }
      }
    }))
    
    setDepartamentos(emptyData)
    setTotalesNacionales({
      validos: 0,
      nulos: 0,
      blancos: 0
    })
  }

  const fetchData = async () => {
    try {
      setServerError(false)
      // Verificar si el servidor está disponible
      const healthCheck = await fetch('http://localhost:8000/totales-nacionales/')
      if (!healthCheck.ok) {
        throw new Error('Servidor no disponible')
      }

      // Obtener totales nacionales
      const dataTotales = await healthCheck.json()
      setTotalesNacionales(dataTotales)

      // Obtener datos por departamento
      const departamentosList = [
        "La Paz", "Cochabamba", "Santa Cruz", "Oruro", 
        "Potosí", "Tarija", "Chuquisaca", "Beni", "Pando"
      ]

      const departamentosData = await Promise.all(
        departamentosList.map(async (depto) => {
          const response = await fetch(`http://localhost:8000/resultados-departamento/${depto}`)
          if (!response.ok) {
            throw new Error(`Error al obtener datos de ${depto}`)
          }
          const data = await response.json()
          return {
            nombre: depto,
            resultados: {
              oficial: {
                mas: data.oficial.mas,
                cc: data.oficial.cc,
                creemos: data.oficial.creemos,
                fpv: data.oficial.fpv
              }
            }
          }
        })
      )

      setDepartamentos(departamentosData)
    } catch (error) {
      console.error('Error al cargar los datos:', error)
      setServerError(true)
      resetData()
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
    // Verificar el estado del servidor cada 30 segundos
    const interval = setInterval(fetchData, 30000)
    return () => clearInterval(interval)
  }, [])

  if (loading) {
    return (
      <div className="app-container">
        <nav className="navbar">
          <div className="nav-content">
            <h1 className="nav-title">Sistema TREP Elecciones 2025 Bolivia</h1>
          </div>
        </nav>
        <main className="main-content">
          <div className="loading">Cargando datos...</div>
        </main>
      </div>
    )
  }

  return (
    <div className="app-container">
      <nav className="navbar">
        <div className="nav-content">
          <h1 className="nav-title">Sistema TREP Elecciones 2025 Bolivia</h1>
        </div>
      </nav>
      <main className="main-content">
        {serverError && (
          <div className="error-banner">
            El servidor no está disponible. Los datos mostrados podrían no estar actualizados.
          </div>
        )}
        <UploadActas onUploadSuccess={fetchData} />
        <MapaBolivia departamentos={departamentos} />
        <TotalesNacionales totales={totalesNacionales} />
      </main>
    </div>
  )
}

export default App
