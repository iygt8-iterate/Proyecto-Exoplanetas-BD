-- CS2041 | Mapeo y deteccion de exoplanetas
-- Q2. Telescopios y senal | Escala 1 000 000

-- Validacion de escala
SELECT current_database() AS base,
       (SELECT COUNT(*) FROM public.observacion) AS observaciones,
       (SELECT COUNT(*) FROM public.evento_transito) AS eventos_transito;

-- Estado de indices
SELECT COUNT(*) AS indices_secundarios
FROM pg_catalog.pg_index AS i
JOIN pg_catalog.pg_class AS t ON t.oid = i.indrelid
JOIN pg_catalog.pg_namespace AS n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('observacion', 'evento_transito')
  AND NOT i.indisprimary;

-- Inicio de comparacion
BEGIN;

-- Q2. Sin indices secundarios candidatos
SELECT * FROM public.exp_q02_telescopios_senal;

-- Indices secundarios candidatos
CREATE INDEX idx_h2_q1_observacion_estrella_fecha
  ON public.observacion (id_estrella, fecha) INCLUDE (duracion);
CREATE INDEX idx_h2_q2_evento_snr_profundidad
  ON public.evento_transito (snr, profundidad) INCLUDE (id_observacion);
CREATE INDEX idx_h2_q3_observacion_mision_fecha
  ON public.observacion (nombre_mision, fecha) INCLUDE (id_estrella);
CREATE INDEX idx_h2_q4_evento_fecha_planeta
  ON public.evento_transito (fecha_inicio, id_exoplaneta)
  INCLUDE (profundidad, snr) WHERE profundidad >= 0.0050;
CREATE INDEX idx_h2_q5_observacion_telescopio_duracion
  ON public.observacion (nombre_telescopio, duracion) INCLUDE (id_estrella);
ANALYZE public.observacion;
ANALYZE public.evento_transito;

-- Q2. Con indices secundarios candidatos
SELECT * FROM public.exp_q02_telescopios_senal;

-- Reversion
ROLLBACK;

-- Estado final de indices
SELECT COUNT(*) AS indices_secundarios
FROM pg_catalog.pg_index AS i
JOIN pg_catalog.pg_class AS t ON t.oid = i.indrelid
JOIN pg_catalog.pg_namespace AS n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('observacion', 'evento_transito')
  AND NOT i.indisprimary;
