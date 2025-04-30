-----------------------------1-------------------------------
SELECT 
    d.departamento AS Departamento,
    r.nombre AS Recinto,
    COUNT(DISTINCT m.codigo_mesa) AS Mesas
FROM mesas m
JOIN recintos_electorales r ON m.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento, r.nombre;


-----------------------------2-------------------------------
SELECT 
    d.departamento AS Departamento,
    d.municipio AS Municipio,
    SUM(ra.cant_tot_papeletas_anfora) AS Total_Votos
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento, d.municipio
ORDER BY Total_Votos DESC;

-----------------------------3-------------------------------
SELECT 
    d.departamento AS Departamento,
    SUM(ra.votos_validos + ra.votos_blancos + ra.votos_nulos) AS Votos_Totales
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento;

-----------------------------4-------------------------------
SELECT TOP 5
	ra.primer_partido AS P1,
    r.nombre AS recinto,
    SUM(ra.primer_partido) AS votos
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
GROUP BY r.nombre, ra.primer_partido
ORDER BY votos DESC;

-----------------------------5-------------------------------
SELECT 
    d.departamento AS Departamento,
    SUM(ra.votos_nulos) AS Votos_Nulos,
    CAST(100.0 * SUM(ra.votos_nulos) / NULLIF(SUM(ra.votos_validos), 0) AS DECIMAL(5,2)) AS Porcentaje
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento
ORDER BY porcentaje DESC;

-----------------------------6-------------------------------!
SELECT 
    ra.id AS Id_Boleta,
    r.nombre AS Recinto,
    ra.nro_mesa AS Mesa,
    ra.observacion AS Motivo_de_anulacion
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
WHERE ra.estado_acta = 'Invalido';

-----------------------------7-------------------------------!
SELECT 
    'TREP' AS fuente,
    SUM(votos_validos + votos_blancos + votos_nulos) AS votos_totales
FROM resultados_actas

UNION ALL

SELECT 
    'Oficial' AS fuente,
    SUM(votos_validos + votos_blancos + votos_nulos) AS votos_totales
FROM resultados_oficiales;


-----------------------------8-------------------------------!
SELECT 
    'MASISP' AS Candidato,
    (SELECT SUM(primer_partido) FROM DBTrep.dbo.resultados_actas) AS TREP,
    (SELECT SUM(primer_partido) FROM DBOficial.dbo.resultados_actas) AS Oficial

UNION ALL

SELECT 
    'Partido2',
    (SELECT SUM(segundo_partido) FROM DBTrep.dbo.resultados_actas),
    (SELECT SUM(segundo_partido) FROM DBOficial.dbo.resultados_actas)

UNION ALL

SELECT 
    'Partido3',
    (SELECT SUM(tercer_partido) FROM DBTrep.dbo.resultados_actas),
    (SELECT SUM(tercer_partido) FROM DBOficial.dbo.resultados_actas)

UNION ALL

SELECT 
    'Partido4',
    (SELECT SUM(cuarto_partido) FROM DBTrep.dbo.resultados_actas),
    (SELECT SUM(cuarto_partido) FROM DBOficial.dbo.resultados_actas);



-----------------------------9-------------------------------
SELECT 
    d.departamento,
    SUM(ra.votos_nulos) AS votos_nulos,
    SUM(ra.votos_blancos) AS votos_blancos,
    SUM(ra.votos_validos - ra.votos_blancos) AS por_candidatos,
    SUM(ra.votos_nulos + ra.votos_validos) AS total
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento
ORDER BY d.departamento;


-----------------------------10-------------------------------
SELECT 
    r.codigo_recinto AS [ID Centro],
    r.nombre AS [Nombre del Centro],
    d.departamento,
    COUNT(ra.id) AS actas
FROM recintos_electorales r
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
LEFT JOIN resultados_actas ra ON ra.codigo_recinto = r.codigo_recinto
GROUP BY r.codigo_recinto, r.nombre, d.departamento
ORDER BY actas DESC;

-----------------------------11-------------------------------
SELECT 
    d.departamento,
    r.nombre AS recinto,
    ra.nro_mesa,
    CAST(
        100.0 * (ra.electores_habilitados - ra.cant_tot_papeletas_anfora) 
        / NULLIF(ra.electores_habilitados, 0) 
        AS DECIMAL(5,2)
    ) AS [Abstención (%)]
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
WHERE 
    ra.electores_habilitados > 0 AND
    (100.0 * (ra.electores_habilitados - ra.cant_tot_papeletas_anfora) / ra.electores_habilitados) > 20
ORDER BY [Abstención (%)] DESC;


-----------------------------12-------------------------------!!!!!
SELECT 
    FORMAT(fecha_recepcion, 'HH:00') + ' - ' + FORMAT(DATEADD(HOUR, 1, fecha_recepcion), 'HH:00') AS Hora,
    COUNT(*) AS [Actas Recibidas]
FROM DBTrep.dbo.resultados_actas  -- o DBOficial.dbo.resultados_actas
WHERE CAST(fecha_recepcion AS DATE) = '2024-04-18'  -- Ajusta fecha si es necesario
GROUP BY DATEPART(HOUR, fecha_recepcion), FORMAT(fecha_recepcion, 'HH:00')
ORDER BY Hora;

-----------------------------Dos bases-------------------------------!!!!!
SELECT 
    'TREP' AS fuente,
    SUM(votos_validos + votos_blancos + votos_nulos) AS total_votos
FROM DBTrep.dbo.resultados_actas

UNION ALL

SELECT 
    'OFICIAL',
    SUM(votos_validos + votos_blancos + votos_nulos)
FROM DBOficial.dbo.resultados_actas;

-----------------------------13-------------------------------!!!!!!!!!
SELECT 
    d.departamento,
    COUNT(CASE WHEN ra.estado_acta = 'Invalido' THEN 1 END) AS [Total actas anuladas TREP],
    COUNT(*) AS [Total actas TREP],
    COUNT(CASE WHEN roa.estado_acta = 'Invalido' THEN 1 END) AS [Total actas anuladas Oficial],
    COUNT(*) AS [Total actas Oficial],
    CAST(
        100.0 * COUNT(CASE WHEN ra.estado_acta = 'Invalido' THEN 1 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS [% Anulación TREP],
    CAST(
        100.0 * COUNT(CASE WHEN roa.estado_acta = 'Invalido' THEN 1 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS [% Anulación Oficial]
FROM DBTrep.dbo.resultados_actas ra
JOIN DBTrep.dbo.recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN DBTrep.dbo.distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
JOIN DBOficial.dbo.resultados_actas roa ON ra.nombre_pdf = roa.nombre_pdf
GROUP BY d.departamento
ORDER BY d.departamento;


-----------------------------14-------------------------------!!!!!!!!!!
SELECT 
    d.departamento,
    MIN(ro.fecha_recepcion) AS [Primera Acta],
    MAX(ro.fecha_recepcion) AS [Última Acta],
    DATEDIFF(MINUTE, MIN(ro.fecha_recepcion), MAX(ro.fecha_recepcion)) AS [Tiempo Promedio (min)]
FROM DBOficial.dbo.resultados_actas ro
JOIN DBOficial.dbo.recintos_electorales r ON ro.codigo_recinto = r.codigo_recinto
JOIN DBOficial.dbo.distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento
ORDER BY d.departamento;

--% Confiabilidad = 100 - (∑ diferencias absolutas de votos por partido entre TREP y Oficial) ÷ total de votos en Oficial × 100
-----------------------------15-------------------------------!!!!!!!!!!!!!
-- Suma de votos por partido en ambas bases
WITH votos AS (
    SELECT 
        (SELECT SUM(primer_partido) FROM DBTrep.dbo.resultados_actas) AS trep_p1,
        (SELECT SUM(primer_partido) FROM DBOficial.dbo.resultados_actas) AS ofi_p1,
        (SELECT SUM(segundo_partido) FROM DBTrep.dbo.resultados_actas) AS trep_p2,
        (SELECT SUM(segundo_partido) FROM DBOficial.dbo.resultados_actas) AS ofi_p2,
        (SELECT SUM(tercer_partido) FROM DBTrep.dbo.resultados_actas) AS trep_p3,
        (SELECT SUM(tercer_partido) FROM DBOficial.dbo.resultados_actas) AS ofi_p3,
        (SELECT SUM(cuarto_partido) FROM DBTrep.dbo.resultados_actas) AS trep_p4,
        (SELECT SUM(cuarto_partido) FROM DBOficial.dbo.resultados_actas) AS ofi_p4
)
SELECT 
    'TREP' AS Fuente,
    CAST(100 - (
        ABS(trep_p1 - ofi_p1) +
        ABS(trep_p2 - ofi_p2) +
        ABS(trep_p3 - ofi_p3) +
        ABS(trep_p4 - ofi_p4)
    ) * 100.0 / NULLIF((
        ofi_p1 + ofi_p2 + ofi_p3 + ofi_p4
    ), 0) AS DECIMAL(5,2)) AS [% de confianza]
FROM votos

UNION ALL

SELECT 
    'OFICIAL',
    100.00;  -- Oficial es referencia base (confiabilidad 100%)


-----------------------------16-------------------------------
SELECT 
    d.departamento,
    CAST(
        100.0 * SUM(ra.cant_tot_papeletas_anfora) / NULLIF(SUM(ra.electores_habilitados), 0)
        AS DECIMAL(5,2)
    ) AS [Participación (%)]
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento
ORDER BY [Participación (%)] DESC;


-----------------------------17-------------------------------!!!!!!!!!!!
SELECT 
    trep.codigo_mesa_formato + '-' + CAST(trep.nro_mesa AS VARCHAR) AS [ID Acta],
    'TREP vs OFICIAL' AS Fuente,
    (ofi.primer_partido - trep.primer_partido) AS [Diff_primer_partido],
    (ofi.segundo_partido - trep.segundo_partido) AS [Diff_segundo_partido],
    (ofi.tercer_partido - trep.tercer_partido) AS [Diff_tercer_partido],
    (ofi.cuarto_partido - trep.cuarto_partido) AS [Diff_cuarto_partido],
    (ofi.votos_validos - trep.votos_validos) AS [Diff_votos_validos],
    (ofi.votos_blancos - trep.votos_blancos) AS [Diff_votos_blancos],
    (ofi.votos_nulos - trep.votos_nulos) AS [Diff_votos_nulos],
    (ofi.cant_tot_papeletas_anfora - trep.cant_tot_papeletas_anfora) AS [Diff_papeletas_anfora],
    (ofi.cant_tot_papeletas_no_usadas - trep.cant_tot_papeletas_no_usadas) AS [Diff_papeletas_no_usadas],
    (ofi.electores_habilitados - trep.electores_habilitados) AS [Diff_electores_habilitados]
FROM DBTrep.dbo.resultados_actas trep
JOIN DBOficial.dbo.resultados_actas ofi 
    ON trep.codigo_mesa_formato = ofi.codigo_mesa_formato 
    AND trep.nro_mesa = ofi.nro_mesa
WHERE 
    (ofi.primer_partido - trep.primer_partido) <> 0 OR
    (ofi.segundo_partido - trep.segundo_partido) <> 0 OR
    (ofi.tercer_partido - trep.tercer_partido) <> 0 OR
    (ofi.cuarto_partido - trep.cuarto_partido) <> 0 OR
    (ofi.votos_validos - trep.votos_validos) <> 0 OR
    (ofi.votos_blancos - trep.votos_blancos) <> 0 OR
    (ofi.votos_nulos - trep.votos_nulos) <> 0 OR
    (ofi.cant_tot_papeletas_anfora - trep.cant_tot_papeletas_anfora) <> 0 OR
    (ofi.cant_tot_papeletas_no_usadas - trep.cant_tot_papeletas_no_usadas) <> 0 OR
    (ofi.electores_habilitados - trep.electores_habilitados) <> 0
ORDER BY [ID Acta];


-----------------------------18-------------------------------
SELECT 
    d.departamento AS Recinto,
    COUNT(ra.id) AS [Archivos PDF],
    CAST(SUM(ra.tamano_pdf) / 1048576.0 AS DECIMAL(10, 2)) AS [Tamaño PDF (MB)]
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
GROUP BY d.departamento
ORDER BY [Tamaño PDF (MB)] DESC;


-----------------------------19-------------------------------
SELECT 
    'MASISP' AS Candidato,
    SUM(ra.primer_partido) AS [Total Votos]
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
WHERE d.departamento = 'Chuquisaca' 
UNION ALL
SELECT 
    'Partido2',
    SUM(ra.segundo_partido)
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
WHERE d.departamento = 'Chuquisaca'
UNION ALL
SELECT 
    'Partido3',
    SUM(ra.tercer_partido)
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
WHERE d.departamento = 'Chuquisaca'
UNION ALL
SELECT 
    'Partido4',
    SUM(ra.cuarto_partido)
FROM resultados_actas ra
JOIN recintos_electorales r ON ra.codigo_recinto = r.codigo_recinto
JOIN distribucion_territorial d ON r.codigo_distribucion = d.codigo_distribucion
WHERE d.departamento = 'Chuquisaca'



-----------------------------20-------------------------------
SELECT 
    observacion AS [Tipo de Error],
    COUNT(*) AS [Frecuencia]
FROM resultados_actas
WHERE observacion IS NOT NULL
GROUP BY observacion
ORDER BY [Frecuencia] DESC;

