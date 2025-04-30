import React, { useState } from 'react'
import './MapaBolivia.css'
import Card from './Card'
import mapaBolivia from '../assets/mapa-bolivia.png'

const MapaBolivia = ({ departamentos }) => {
  const [selectedDepartamento, setSelectedDepartamento] = useState(null)

  const puntos = {
    'La Paz': { top: '45%', left: '22%' },
    'Cochabamba': { top: '55%', left: '39%' },
    'Santa Cruz': { top: '55%', left: '65%' },
    'Oruro': { top: '64%', left: '27%' },
    'Potosí': { top: '80%', left: '32%' },
    'Tarija': { top: '83%', left: '52%' },
    'Chuquisaca': { top: '75%', left: '48%' },
    'Beni': { top: '35%', left: '40%' },
    'Pando': { top: '17%', left: '30%' }
  }

  return (
    <div className="mapa-container">
      <div className="mapa-wrapper">
        <img 
          src={mapaBolivia}
          alt="Mapa de Bolivia" 
          className="mapa-imagen"
        />
        {Object.entries(puntos).map(([depto, position]) => (
          <button
            key={depto}
            className={`punto-departamento ${selectedDepartamento === depto ? 'active' : ''}`}
            style={{ top: position.top, left: position.left }}
            onClick={() => setSelectedDepartamento(depto)}
            title={depto}
          >
            <span className="punto-label">{depto}</span>
          </button>
        ))}
      </div>
      {selectedDepartamento && (
        <div className="card-overlay">
          <div className="card-wrapper">
            <button 
              className="close-button"
              onClick={() => setSelectedDepartamento(null)}
            >
              ×
            </button>
            <Card
              departamento={selectedDepartamento}
              resultados={departamentos.find(d => d.nombre === selectedDepartamento).resultados}
            />
          </div>
        </div>
      )}
    </div>
  )
}

export default MapaBolivia 