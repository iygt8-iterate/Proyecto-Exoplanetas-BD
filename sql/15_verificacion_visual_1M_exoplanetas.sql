-- CS2041 | Mapeo y deteccion de exoplanetas
-- Verificacion comparativa: 1 000 000 de registros

-- 1. Validacion del escenario
SELECT current_database() AS base,
       (SELECT COUNT(*) FROM public.observacion) AS observaciones,
       (SELECT COUNT(*) FROM public.evento_transito) AS eventos_transito;

SELECT COUNT(*) AS indices_secundarios_de_prueba
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class t ON t.oid = i.indrelid
JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('observacion', 'evento_transito')
  AND NOT i.indisprimary;

-- 2. Inicio de la comparacion
BEGIN;

-- 3. Consultas sin indices secundarios
-- Q1
SELECT * FROM public.exp_q01_observaciones_estrella;

-- Q2
SELECT * FROM public.exp_q02_telescopios_senal;

-- Q3
SELECT * FROM public.exp_q03_actividad_mision;

-- Q4
SELECT * FROM public.exp_q04_planetas_transitos;

-- Q5
SELECT * FROM public.exp_q05_espectro_telescopio;

-- 4. Indices candidatos
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

-- 5. Consultas con indices secundarios
-- Q1
SELECT * FROM public.exp_q01_observaciones_estrella;

-- Q2
SELECT * FROM public.exp_q02_telescopios_senal;

-- Q3
SELECT * FROM public.exp_q03_actividad_mision;

-- Q4
SELECT * FROM public.exp_q04_planetas_transitos;

-- Q5
SELECT * FROM public.exp_q05_espectro_telescopio;

-- 6. Reversion del escenario
ROLLBACK;

SELECT COUNT(*) AS indices_secundarios_de_prueba
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class t ON t.oid = i.indrelid
JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('observacion','evento_transito')
  AND NOT i.indisprimary;
