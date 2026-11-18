-- UTEC / CS2041 / Hito 2 / Seccion 5 - Experimentacion de 1M
-- Este script NO genera nuevos datos ni cambia las 8 tablas del proyecto.
-- Requiere: scripts 01-13 ejecutados, escala 1M verificada y backup exoplanetas_1M.backup ya guardado.
-- Genera 5 consultas x 2 escenarios x 3 repeticiones = 30 mediciones reales.
-- Los indices candidatos se crean, se prueban y SE ELIMINAN al finalizar.
-- Las mediciones se guardan en public.resultados_hito2 y se muestran al final.
-- IMPORTANTE: exporta el resultado a CSV desde pgAdmin para usarlo en LaTeX.

BEGIN;

-- Evita medir por accidente otra base o un tamano distinto.
DO $$
DECLARE
  n_obs BIGINT;
  n_evt BIGINT;
  n_indices INTEGER;
BEGIN
  IF current_database() <> 'exoplanetas_bd' THEN
    RAISE EXCEPTION 'Base incorrecta: debes estar en exoplanetas_bd';
  END IF;
  SELECT count(*) INTO n_obs FROM public.observacion;
  SELECT count(*) INTO n_evt FROM public.evento_transito;
  IF n_obs <> 1000000 OR n_evt <> 1000000 THEN
    RAISE EXCEPTION 'Se requiere escala 1M: hay % observaciones y % eventos', n_obs, n_evt;
  END IF;

  -- Las claves primarias SI conservan sus indices obligatorios.
  -- Este experimento compara ausencia/presencia de indices SECUNDARIOS candidatos.
  SELECT count(*) INTO n_indices
  FROM pg_catalog.pg_index AS i
  JOIN pg_catalog.pg_class AS t ON t.oid = i.indrelid
  JOIN pg_catalog.pg_namespace AS n ON n.oid = t.relnamespace
  WHERE n.nspname = 'public'
    AND t.relname IN ('observacion','evento_transito')
    AND NOT i.indisprimary;
  IF n_indices > 0 THEN
    RAISE EXCEPTION 'Hay % indices secundarios en observacion/evento_transito; revisarlos antes de medir escenario sin indices', n_indices;
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.resultados_hito2 (
  escala INTEGER NOT NULL,
  consulta TEXT NOT NULL,
  escenario TEXT NOT NULL CHECK (escenario IN ('sin_indices','con_indices')),
  repeticion SMALLINT NOT NULL,
  tiempo_ms NUMERIC(14,4) NOT NULL,
  plan_json JSONB NOT NULL,
  PRIMARY KEY (escala,consulta,escenario,repeticion)
);

-- En una repeticion del script, sustituye SOLO las mediciones de 1M.
DELETE FROM public.resultados_hito2 WHERE escala = 1000000;

ANALYZE public.observacion;
ANALYZE public.evento_transito;

-- Fase A: 5 consultas con indices de clave primaria, SIN indices candidatos.
DO $$
DECLARE
  q TEXT;
  r INTEGER;
  v_plan_txt TEXT;
  v_plan JSONB;
  qlist TEXT[] := ARRAY[
    'exp_q01_observaciones_estrella',
    'exp_q02_telescopios_senal',
    'exp_q03_actividad_mision',
    'exp_q04_planetas_transitos',
    'exp_q05_espectro_telescopio'
  ];
BEGIN
  FOREACH q IN ARRAY qlist LOOP
    -- Calentamiento no contabilizado para reducir sesgo por cache fria.
    EXECUTE format('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT * FROM public.%I', q)
      INTO v_plan_txt;
    FOR r IN 1..3 LOOP
      EXECUTE format('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT * FROM public.%I', q)
        INTO v_plan_txt;
      v_plan := v_plan_txt::jsonb;
      INSERT INTO public.resultados_hito2
        (escala, consulta, escenario, repeticion, tiempo_ms, plan_json)
      VALUES
        (1000000, q, 'sin_indices', r,
         (v_plan #>> '{0,Execution Time}')::numeric, v_plan);
    END LOOP;
  END LOOP;
END;
$$;

-- Fase B: indices candidatos, elegidos por los filtros/joins de Q1-Q5.
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

DO $$
DECLARE
  q TEXT;
  r INTEGER;
  v_plan_txt TEXT;
  v_plan JSONB;
  qlist TEXT[] := ARRAY[
    'exp_q01_observaciones_estrella',
    'exp_q02_telescopios_senal',
    'exp_q03_actividad_mision',
    'exp_q04_planetas_transitos',
    'exp_q05_espectro_telescopio'
  ];
BEGIN
  FOREACH q IN ARRAY qlist LOOP
    EXECUTE format('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT * FROM public.%I', q)
      INTO v_plan_txt;
    FOR r IN 1..3 LOOP
      EXECUTE format('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT * FROM public.%I', q)
        INTO v_plan_txt;
      v_plan := v_plan_txt::jsonb;
      INSERT INTO public.resultados_hito2
        (escala, consulta, escenario, repeticion, tiempo_ms, plan_json)
      VALUES
        (1000000, q, 'con_indices', r,
         (v_plan #>> '{0,Execution Time}')::numeric, v_plan);
    END LOOP;
  END LOOP;
END;
$$;

-- Retiramos los indices candidatos: queda igual el esquema previo,
-- salvo por la tabla de mediciones. Los indices PK no se tocan.
DROP INDEX public.idx_h2_q1_observacion_estrella_fecha;
DROP INDEX public.idx_h2_q2_evento_snr_profundidad;
DROP INDEX public.idx_h2_q3_observacion_mision_fecha;
DROP INDEX public.idx_h2_q4_evento_fecha_planeta;
DROP INDEX public.idx_h2_q5_observacion_telescopio_duracion;

COMMIT;

-- RESULTADO FINAL: 5 filas. Tiempos reales de PostgreSQL en MILISEGUNDOS.
-- Un resultado negativo en "mejora_pct" significa que el conjunto de indices
-- fue PEOR para esa consulta; tambien es un resultado valido a discutir.
SELECT
    consulta,
    ROUND(AVG(tiempo_ms) FILTER (WHERE escenario = 'sin_indices'),3) AS sin_indices_ms,
    ROUND(AVG(tiempo_ms) FILTER (WHERE escenario = 'con_indices'),3) AS con_indices_ms,
    ROUND(
      100.0 * (
        AVG(tiempo_ms) FILTER (WHERE escenario='sin_indices') -
        AVG(tiempo_ms) FILTER (WHERE escenario='con_indices')
      ) / NULLIF(AVG(tiempo_ms) FILTER (WHERE escenario='sin_indices'),0),2
    ) AS mejora_pct,
    COUNT(*) AS mediciones
FROM public.resultados_hito2
WHERE escala = 1000000
GROUP BY consulta
ORDER BY consulta;