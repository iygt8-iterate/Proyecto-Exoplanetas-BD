-- CS2041 / UTEC 2026-II / EXOPLANETAS
-- SCRIPT 15 - DEMOSTRACION VISUAL DE 1 MILLON DE REGISTROS
--
-- Este script es para UN SOLO VIDEO de las cinco consultas (Q1-Q5).
-- Compatible con el experimento 14: compara SIN vs CON EL MISMO CONJUNTO DE 5 INDICES.
-- No reemplaza al script 14, que calcula 30 mediciones y guarda planes JSON.
--
-- IMPORTANTE: NO ejecutes TODO con F5 de golpe. Selecciona solo una sentencia
-- cada vez y ejecutala, o usa el boton Explain Analyze para cada SELECT.
-- En pgAdmin, el modo EXPLAIN ANALYZE grafico permite ver Summary.
-- Ejecutar en la MISMA ventana Query Tool sobre exoplanetas_bd.
-- El ROLLBACK final deshace los indices que se creen en esta demostracion.
-- Los indices de claves primarias NO se eliminan ni modifican.

-- 0. Verificar base y escala; selecciona cada consulta y F5.
SELECT current_database() AS base,
       (SELECT COUNT(*) FROM public.observacion) AS observaciones,
       (SELECT COUNT(*) FROM public.evento_transito) AS eventos_transito;
-- Esperado: exoplanetas_bd | 1000000 | 1000000.

SELECT COUNT(*) AS indices_secundarios_de_prueba
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class t ON t.oid = i.indrelid
JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('observacion', 'evento_transito')
  AND NOT i.indisprimary;
-- Esperado: 0, de lo contrario DETENERSE y revisar indices.

-- 1. Iniciar transaccion. Seleccionar SOLO BEGIN; y F5.
BEGIN;

-- 2. SIN indices secundarios candidatos.
-- Para cada SELECT, seleccionarlo y pulsar Explain Analyze en pgAdmin.
-- Mostrar Summary y tiempo. Alternativa: selecciona solo el SELECT y
-- antecedelo temporalmente por EXPLAIN (ANALYZE, BUFFERS) para ejecutarlo con F5.

-- Q1 SIN INDICES: Observaciones por estrella
SELECT * FROM public.exp_q01_observaciones_estrella;

-- Q2 SIN INDICES: Telescopios y senal
SELECT * FROM public.exp_q02_telescopios_senal;

-- Q3 SIN INDICES: Actividad de mision
SELECT * FROM public.exp_q03_actividad_mision;

-- Q4 SIN INDICES: Exoplanetas y transitos
SELECT * FROM public.exp_q04_planetas_transitos;

-- Q5 SIN INDICES: Espectro y telescopio
SELECT * FROM public.exp_q05_espectro_telescopio;

-- 3. ACTIVAR LOS CINCO INDICES, COMO EN EL SCRIPT 14.
-- Seleccionar y ejecutar cada CREATE INDEX con F5. NO pulses ROLLBACK todavia.
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

-- Actualizar estadisticas para el optimizador, seleccionando cada ANALYZE.
ANALYZE public.observacion;
ANALYZE public.evento_transito;

-- 4. CON LOS CINCO INDICES ACTIVOS.
-- Mismo SQL y misma herramienta Explain Analyze; mostrar Summary de Q1-Q5.


-- Q1 CON INDICES: Observaciones por estrella
SELECT * FROM public.exp_q01_observaciones_estrella;

-- Q2 CON INDICES: Telescopios y senal
SELECT * FROM public.exp_q02_telescopios_senal;

-- Q3 CON INDICES: Actividad de mision
SELECT * FROM public.exp_q03_actividad_mision;

-- Q4 CON INDICES: Exoplanetas y transitos
SELECT * FROM public.exp_q04_planetas_transitos;

-- Q5 CON INDICES: Espectro y telescopio
SELECT * FROM public.exp_q05_espectro_telescopio;

-- 5. FIN DE LA DEMOSTRACION: seleccionar SOLO ROLLBACK; y F5.
-- Esto retira automaticamente los 5 indices temporales de la transaccion.
ROLLBACK;

-- 6. Comprobacion posterior, selecciona y F5.
SELECT COUNT(*) AS indices_secundarios_de_prueba
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class t ON t.oid = i.indrelid
JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('observacion','evento_transito')
  AND NOT i.indisprimary;
-- Esperado: 0.

-- Todos los tiempos y planes provienen de PostgreSQL. Las medias OFICIALES
-- del informe se obtienen con el script 14, no con este video demostrativo.
