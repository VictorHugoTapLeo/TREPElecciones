import React from 'react'
import './TotalesNacionales.css'

const TotalesNacionales = ({ totales }) => {
  return (
    <div className="totales-container">
      <h2 className="totales-titulo">TOTALES NACIONALES</h2>
      <div className="totales-grid">
        <div className="total-item">
          <span className="total-label">Votos Válidos</span>
          <span className="total-value">{totales.validos.toLocaleString()}</span>
        </div>
        <div className="total-item">
          <span className="total-label">Votos Nulos</span>
          <span className="total-value">{totales.nulos.toLocaleString()}</span>
        </div>
        <div className="total-item">
          <span className="total-label">Votos en Blanco</span>
          <span className="total-value">{totales.blancos.toLocaleString()}</span>
        </div>
      </div>
    </div>
  )
}

export default TotalesNacionales 