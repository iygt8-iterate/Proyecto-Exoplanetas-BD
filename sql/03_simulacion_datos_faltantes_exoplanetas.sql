-- CS2041 | Mapeo y deteccion de exoplanetas
-- Simulacion de datos faltantes

BEGIN;

-- Caso 1: 10% de estrellas sin estimacion de distancia (20 de 200)
UPDATE public.estrella
SET distancia = NULL
WHERE id_estrella BETWEEN 1 AND 200
  AND id_estrella % 10 = 0;

-- Caso 2: 10% de exoplanetas sin estimacion de masa (40 de 400)
UPDATE public.exoplaneta
SET masa = NULL
WHERE id_exoplaneta BETWEEN 1 AND 400
  AND id_exoplaneta % 10 = 0;

-- Caso 3: 10% de observaciones sin detalle del filtro (100 de 1000)
UPDATE public.observacion
SET filtro = NULL
WHERE id_observacion BETWEEN 1 AND 1000
  AND id_observacion % 10 = 0;

-- Caso 4: 5% de eventos sin medida SNR (50 de 1000)
UPDATE public.evento_transito
SET snr = NULL
WHERE id_observacion BETWEEN 1 AND 1000
  AND id_observacion % 20 = 0;

-- Caso 5: 1 miembro por mision sin especialidad registrada (4 de 20)
UPDATE public.miembro_mision
SET especialidad = NULL
WHERE nro_miembro = 5
  AND nombre_mision LIKE 'Mision-Simulada-%';

COMMIT;

SELECT 'estrella.distancia' AS campo,
       COUNT(*) AS total,
       COUNT(*) FILTER (WHERE distancia IS NULL) AS faltantes,
       ROUND(100.0 * COUNT(*) FILTER (WHERE distancia IS NULL) / NULLIF(COUNT(*),0), 2) AS porcentaje_faltante
FROM public.estrella
UNION ALL
SELECT 'exoplaneta.masa', COUNT(*),
       COUNT(*) FILTER (WHERE masa IS NULL),
       ROUND(100.0 * COUNT(*) FILTER (WHERE masa IS NULL) / NULLIF(COUNT(*),0), 2)
FROM public.exoplaneta
UNION ALL
SELECT 'observacion.filtro', COUNT(*),
       COUNT(*) FILTER (WHERE filtro IS NULL),
       ROUND(100.0 * COUNT(*) FILTER (WHERE filtro IS NULL) / NULLIF(COUNT(*),0), 2)
FROM public.observacion
UNION ALL
SELECT 'evento_transito.snr', COUNT(*),
       COUNT(*) FILTER (WHERE snr IS NULL),
       ROUND(100.0 * COUNT(*) FILTER (WHERE snr IS NULL) / NULLIF(COUNT(*),0), 2)
FROM public.evento_transito
UNION ALL
SELECT 'miembro_mision.especialidad', COUNT(*),
       COUNT(*) FILTER (WHERE especialidad IS NULL),
       ROUND(100.0 * COUNT(*) FILTER (WHERE especialidad IS NULL) / NULLIF(COUNT(*),0), 2)
FROM public.miembro_mision
ORDER BY campo;
