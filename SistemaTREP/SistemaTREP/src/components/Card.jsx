import React from 'react'
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts'
import './Card.css'

const Card = ({ departamento, resultados }) => {
  const COLORS = {
    mas: '#1E88E5', // Azul para MAS
    cc: '#E53935',  // Rojo para CC
    creemos: '#43A047', // Verde para Creemos
    fpv: '#FDD835'  // Amarillo para FPV
  }
  
  const formatData = (data) => {
    return [
      { name: 'MAS', value: parseInt(data.mas.replace(/,/g, '')) },
      { name: 'CC', value: parseInt(data.cc.replace(/,/g, '')) },
      { name: 'Creemos', value: parseInt(data.creemos.replace(/,/g, '')) },
      { name: 'FPV', value: parseInt(data.fpv.replace(/,/g, '')) }
    ]
  }

  const dataOficial = formatData(resultados.oficial)

  const renderCustomizedLabel = ({ cx, cy, midAngle, innerRadius, outerRadius, percent, name }) => {
    const RADIAN = Math.PI / 180;
    const radius = innerRadius + (outerRadius - innerRadius) * 0.5;
    const x = cx + radius * Math.cos(-midAngle * RADIAN);
    const y = cy + radius * Math.sin(-midAngle * RADIAN);

    return (
      <text
        x={x}
        y={y}
        fill="white"
        textAnchor={x > cx ? 'start' : 'end'}
        dominantBaseline="central"
        className="pie-label"
      >
        {`${name}: ${(percent * 100).toFixed(0)}%`}
      </text>
    );
  };

  return (
    <div className="card-container">
      <h2 className="card-title">{departamento}</h2>
      <div className="card-content">
        <div className="resultado-section">
          <h3>CONTEO DE VOTOS</h3>
          <div className="chart-container">
            <ResponsiveContainer width="100%" height={160}>
              <PieChart>
                <Pie
                  data={dataOficial}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                  label={renderCustomizedLabel}
                >
                  {dataOficial.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[entry.name.toLowerCase()]} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="partidos-grid">
            {dataOficial.map((partido, index) => (
              <div key={index} className="partido-resultado" style={{ borderLeft: `4px solid ${COLORS[partido.name.toLowerCase()]}` }}>
                <span className="partido-nombre">{partido.name}</span>
                <span className="votos">{partido.value.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default Card 