-- CS2041 UTEC 2026-II | Hito 2 | 15 VERIFICACION VISUAL DEL MILLON
-- Inspirado en el procedimiento de verificacion en videos del proyecto de Fabricio.
-- Estas consultas, tablas e indices pertenecen UNICAMENTE al proyecto Exoplanetas.
-- EJECUTAR EN LA BASE: exoplanetas_bd
-- REQUISITOS: 1M ya cargado; backup de 1M guardado; script 14 ya medido.
-- NOTA: Este script es para MOSTRAR planes en pgAdmin, no reemplaza las 30 mediciones de 14.
-- Cada bloque compara UN indice candidato para su consulta. Las medias oficiales
-- de script 14 comparan los CINCO indices candidatos activados juntos y pueden diferir.
--
-- IMPORTANTE: NO pulses F5 con todo el archivo seleccionado.
-- Ve ejecutando las sentencias SEPARADAMENTE, tal como en el video de referencia.
-- Para los SELECT de consulta, selecciona solo la sentencia y usa EXPLAIN ANALYZE
-- del Query Tool; en la pestana Explain abre el apartado Summary.
-- Si no ves la opcion grafica, puedes ejecutar EXPLAIN (ANALYZE, BUFFERS)
-- antes del SELECT copiando su sentencia; no falsifiques tiempos ni planes.
-- Todos los indices creados dentro de cada bloque se deshacen con ROLLBACK.
-- Si ocurre un error a mitad de bloque, ejecuta ROLLBACK antes de continuar.

-- ETAPA 0: Comprobacion inicial (selecciona y F5)
SELECT current_database() AS base_seleccionada,
       (SELECT COUNT(*) FROM public.observacion) AS observaciones,
       (SELECT COUNT(*) FROM public.evento_transito) AS eventos_transito;
-- Debe devolver exoplanetas_bd, 1000000, 1000000.

SELECT COUNT(*) AS indices_secundarios_de_prueba
FROM pg_catalog.pg_index AS i
JOIN pg_catalog.pg_class AS t ON t.oid = i.indrelid
JOIN pg_catalog.pg_namespace AS n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('observacion','evento_transito')
  AND NOT i.indisprimary;
-- Resultado esperado: 0. Si es distinto, revisar antes de grabar.

-- ======================================================================
-- Q1. OBSERVACIONES POR ESTRELLA
-- ======================================================================
-- 1) Selecciona BEGIN; y pulsa F5.
BEGIN;

-- 2) SIN indice candidato: selecciona el SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q01_observaciones_estrella;

-- 3) Crea SOLO el indice candidato de Q1. Selecciona CREATE INDEX y F5.
CREATE INDEX idx_h2_q1_observacion_estrella_fecha
  ON public.observacion (id_estrella, fecha) INCLUDE (duracion);
ANALYZE public.observacion;

-- 4) CON indice candidato: selecciona este SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q01_observaciones_estrella;

-- 5) MUY IMPORTANTE: selecciona ROLLBACK; y pulsa F5.
ROLLBACK;

-- ======================================================================
-- Q2. TELESCOPIOS Y SENAL DE TRANSITO
-- ======================================================================
-- 1) Selecciona BEGIN; y pulsa F5.
BEGIN;

-- 2) SIN indice candidato: selecciona el SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q02_telescopios_senal;

-- 3) Crea SOLO el indice candidato de Q2. Selecciona CREATE INDEX y F5.
CREATE INDEX idx_h2_q2_evento_snr_profundidad
  ON public.evento_transito (snr, profundidad) INCLUDE (id_observacion);
ANALYZE public.evento_transito;

-- 4) CON indice candidato: selecciona este SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q02_telescopios_senal;

-- 5) MUY IMPORTANTE: selecciona ROLLBACK; y pulsa F5.
ROLLBACK;

-- ======================================================================
-- Q3. ACTIVIDAD DE MISION
-- ======================================================================
-- 1) Selecciona BEGIN; y pulsa F5.
BEGIN;

-- 2) SIN indice candidato: selecciona el SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q03_actividad_mision;

-- 3) Crea SOLO el indice candidato de Q3. Selecciona CREATE INDEX y F5.
CREATE INDEX idx_h2_q3_observacion_mision_fecha
  ON public.observacion (nombre_mision, fecha) INCLUDE (id_estrella);
ANALYZE public.observacion;

-- 4) CON indice candidato: selecciona este SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q03_actividad_mision;

-- 5) MUY IMPORTANTE: selecciona ROLLBACK; y pulsa F5.
ROLLBACK;

-- ======================================================================
-- Q4. EXOPLANETAS Y TRANSITOS PROFUNDOS
-- ======================================================================
-- 1) Selecciona BEGIN; y pulsa F5.
BEGIN;

-- 2) SIN indice candidato: selecciona el SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q04_planetas_transitos;

-- 3) Crea SOLO el indice candidato de Q4. Selecciona CREATE INDEX y F5.
CREATE INDEX idx_h2_q4_evento_fecha_planeta
  ON public.evento_transito (fecha_inicio, id_exoplaneta)
  INCLUDE (profundidad, snr) WHERE profundidad >= 0.0050;
ANALYZE public.evento_transito;

-- 4) CON indice candidato: selecciona este SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q04_planetas_transitos;

-- 5) MUY IMPORTANTE: selecciona ROLLBACK; y pulsa F5.
ROLLBACK;

-- ======================================================================
-- Q5. TIPO ESPECTRAL Y TELESCOPIOS
-- ======================================================================
-- 1) Selecciona BEGIN; y pulsa F5.
BEGIN;

-- 2) SIN indice candidato: selecciona el SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q05_espectro_telescopio;

-- 3) Crea SOLO el indice candidato de Q5. Selecciona CREATE INDEX y F5.
CREATE INDEX idx_h2_q5_observacion_telescopio_duracion
  ON public.observacion (nombre_telescopio, duracion) INCLUDE (id_estrella);
ANALYZE public.observacion;

-- 4) CON indice candidato: selecciona este SELECT y usa Explain Analyze.
SELECT * FROM public.exp_q05_espectro_telescopio;

-- 5) MUY IMPORTANTE: selecciona ROLLBACK; y pulsa F5.
ROLLBACK;

-- FIN. Cada bloque revierte su indice y deja los datos intactos.
-- Nota metodologica: los tiempos de este video son demostrativos, no los
-- promedios oficiales del script 14.
