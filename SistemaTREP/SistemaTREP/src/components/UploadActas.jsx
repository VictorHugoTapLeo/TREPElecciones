import React, { useState } from 'react'
import './UploadActas.css'

const UploadActas = ({ onUploadSuccess }) => {
  const [file, setFile] = useState(null)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0]
    if (selectedFile && selectedFile.type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      setFile(selectedFile)
      setError('')
    } else {
      setFile(null)
      setError('Solo archivos Excel (.xlsx)')
    }
  }

  const handleUpload = async () => {
    if (!file) {
      setError('Selecciona un archivo')
      return
    }

    setLoading(true)
    setError('')
    setMessage('')

    const formData = new FormData()
    formData.append('file', file)

    try {
      const response = await fetch('http://localhost:8000/upload-actas/', {
        method: 'POST',
        body: formData
      })

      if (!response.ok) {
        throw new Error('Error al subir')
      }

      const data = await response.json()
      setMessage(data.message)
      setFile(null)
      document.getElementById('file-input').value = ''
      
      if (onUploadSuccess) {
        onUploadSuccess()
      }
    } catch (err) {
      setError('Error: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="upload-container">
      <h3 className="upload-title">Subir Actas</h3>
      <div className="upload-content">
        <input
          id="file-input"
          type="file"
          accept=".xlsx"
          onChange={handleFileChange}
          className="file-input"
        />
        <button 
          onClick={handleUpload}
          disabled={!file || loading}
          className="upload-button"
        >
          {loading ? 'Subiendo...' : 'Subir'}
        </button>
      </div>
      {error && <div className="error-message">{error}</div>}
      {message && <div className="success-message">{message}</div>}
    </div>
  )
}

export default UploadActas 