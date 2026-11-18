-- CS2041 | Mapeo y deteccion de exoplanetas
-- Consultas de experimentacion

-- Q1. Observaciones por estrella
CREATE OR REPLACE VIEW public.exp_q01_observaciones_estrella AS
SELECT
    s.id_estrella,
    s.nombre AS estrella,
    s.tipo_espectral,
    COUNT(*)::bigint AS total_observaciones,
    ROUND(AVG(o.duracion), 2) AS duracion_promedio
FROM public.observacion AS o
JOIN public.estrella AS s ON s.id_estrella = o.id_estrella
WHERE o.id_estrella BETWEEN 10 AND 30
  AND o.fecha >= DATE '2022-01-01'
  AND o.fecha < DATE '2024-01-01'
GROUP BY s.id_estrella, s.nombre, s.tipo_espectral
HAVING COUNT(*) >= 2;
-- Q2. Ranking de telescopios por transitos con SNR y p
CREATE OR REPLACE VIEW public.exp_q02_telescopios_senal AS
SELECT
    t.nombre AS telescopio,
    t.tipo AS tipo_telescopio,
    COUNT(*)::bigint AS eventos_filtrados,
    ROUND(AVG(e.snr), 2) AS snr_promedio,
    ROUND(AVG(e.profundidad), 5) AS profundidad_promedio
FROM public.evento_transito AS e
JOIN public.observacion AS o ON o.id_observacion = e.id_observacion
JOIN public.telescopio AS t ON t.nombre = o.nombre_telescopio
WHERE e.snr >= 15.5
  AND e.profundidad >= 0.0045
GROUP BY t.nombre, t.tipo
HAVING COUNT(*) >= 1;
-- Q3. Actividad de una mision en un periodo concreto.
CREATE OR REPLACE VIEW public.exp_q03_actividad_mision AS
SELECT
    m.nombre AS mision,
    m.agencia,
    COUNT(DISTINCT o.id_observacion)::bigint AS observaciones,
    COUNT(e.id_observacion)::bigint AS eventos,
    COUNT(DISTINCT o.id_estrella)::bigint AS estrellas_observadas,
    ROUND(AVG(e.snr), 2) AS snr_promedio
FROM public.mision_espacial AS m
JOIN public.observacion AS o ON o.nombre_mision = m.nombre
LEFT JOIN public.evento_transito AS e ON e.id_observacion = o.id_observacion
WHERE o.nombre_mision = 'Mision-Simulada-01'
  AND o.fecha >= DATE '2022-01-01'
  AND o.fecha < DATE '2024-01-01'
GROUP BY m.nombre, m.agencia;
-- Q4. Exoplanetas confirmados con transitos profundos 
CREATE OR REPLACE VIEW public.exp_q04_planetas_transitos AS
WITH eventos_seleccionados AS (
    SELECT id_observacion, id_exoplaneta, fecha_inicio, profundidad, snr
    FROM public.evento_transito
    WHERE fecha_inicio >= TIMESTAMP '2023-01-01 00:00:00'
      AND fecha_inicio < TIMESTAMP '2025-01-01 00:00:00'
      AND profundidad >= 0.0050
)
SELECT
    p.id_exoplaneta,
    p.nombre AS exoplaneta,
    s.nombre AS estrella,
    COUNT(*)::bigint AS transitos_profundos,
    ROUND(AVG(e.profundidad), 5) AS profundidad_promedio,
    ROUND(MAX(e.snr), 2) AS snr_maximo
FROM eventos_seleccionados AS e
JOIN public.exoplaneta AS p ON p.id_exoplaneta = e.id_exoplaneta
JOIN public.estrella AS s ON s.id_estrella = p.id_estrella
WHERE p.estado = 'confirmado'
GROUP BY p.id_exoplaneta, p.nombre, s.nombre;
-- Q5. Comparar tipos espectrales y telescopios para ev
CREATE OR REPLACE VIEW public.exp_q05_espectro_telescopio AS
SELECT
    s.tipo_espectral,
    o.nombre_telescopio,
    COUNT(*)::bigint AS eventos,
    COUNT(DISTINCT s.id_estrella)::bigint AS estrellas_distintas,
    ROUND(AVG(o.duracion), 2) AS duracion_promedio,
    ROUND(AVG(e.snr), 2) AS snr_promedio
FROM public.observacion AS o
JOIN public.estrella AS s ON s.id_estrella = o.id_estrella
JOIN public.evento_transito AS e ON e.id_observacion = o.id_observacion
WHERE o.nombre_telescopio IN ('Telescopio-Simulado-01', 'Telescopio-Simulado-02')
  AND o.duracion >= 160
  AND e.snr >= 10
  AND e.snr < 14
GROUP BY s.tipo_espectral, o.nombre_telescopio
HAVING COUNT(*) >= 1;
SELECT 'Q1 - Observaciones por estrella' AS consulta,
       COUNT(*)::bigint AS filas_resultado FROM public.exp_q01_observaciones_estrella
UNION ALL
SELECT 'Q2 - Telescopios y senal', COUNT(*) FROM public.exp_q02_telescopios_senal
UNION ALL
SELECT 'Q3 - Actividad de mision', COUNT(*) FROM public.exp_q03_actividad_mision
UNION ALL
SELECT 'Q4 - Planetas y transitos', COUNT(*) FROM public.exp_q04_planetas_transitos
UNION ALL
SELECT 'Q5 - Espectro y telescopio', COUNT(*) FROM public.exp_q05_espectro_telescopio
ORDER BY consulta;
