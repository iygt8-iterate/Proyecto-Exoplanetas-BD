-- CS2041 Base de Datos I - Hito 2
-- Etapa 4.4: Views (vistas de usuario)
-- Ejecutar SOLO en exoplanetas_bd, despues de la carga inicial.
-- CREATE OR REPLACE permite volver a ejecutar este archivo sin duplicar vistas.
-- NOTA: estas vistas NO sustituyen las cinco consultas del experimento.

-- Vista 1: catalogo de exoplanetas con informacion de la estrella anfitriona.
CREATE OR REPLACE VIEW public.vw_catalogo_exoplanetas AS
SELECT
    p.id_exoplaneta,
    p.nombre AS nombre_exoplaneta,
    p.estado AS estado_exoplaneta,
    p.masa AS masa_exoplaneta,
    p.periodo_orbital,
    s.id_estrella,
    s.nombre AS nombre_estrella,
    s.tipo_espectral,
    s.distancia AS distancia_estrella
FROM public.exoplaneta AS p
JOIN public.estrella AS s ON s.id_estrella = p.id_estrella;

-- Vista 2: observaciones y sus instrumentos, estrella y mision (opcional).
CREATE OR REPLACE VIEW public.vw_observaciones_detalle AS
SELECT
    o.id_observacion,
    o.fecha,
    o.duracion,
    o.metodo,
    o.filtro,
    o.nombre_telescopio,
    t.tipo AS tipo_telescopio,
    o.nombre_mision,
    s.id_estrella,
    s.nombre AS nombre_estrella
FROM public.observacion AS o
JOIN public.telescopio AS t ON t.nombre = o.nombre_telescopio
JOIN public.estrella AS s ON s.id_estrella = o.id_estrella;

-- Vista 3: eventos de transito con sus observaciones, exoplanetas y estrella.
-- Incluye una verificacion explicita de concordancia entre las estrellas.
CREATE OR REPLACE VIEW public.vw_eventos_transito_detalle AS
SELECT
    e.id_observacion,
    e.nro_evento,
    e.fecha_inicio,
    e.duracion AS duracion_evento,
    e.profundidad,
    e.snr,
    e.metodo_deteccion,
    o.fecha AS fecha_observacion,
    o.nombre_telescopio,
    e.id_exoplaneta,
    p.nombre AS nombre_exoplaneta,
    s.id_estrella,
    s.nombre AS nombre_estrella,
    (o.id_estrella = p.id_estrella) AS estrella_consistente
FROM public.evento_transito AS e
JOIN public.observacion AS o ON o.id_observacion = e.id_observacion
JOIN public.exoplaneta AS p ON p.id_exoplaneta = e.id_exoplaneta
JOIN public.estrella AS s ON s.id_estrella = o.id_estrella;

-- Verificacion: actualmente se esperan 400, 1000 y 1000 filas.
SELECT 'vw_catalogo_exoplanetas' AS vista, COUNT(*) AS registros
FROM public.vw_catalogo_exoplanetas
UNION ALL
SELECT 'vw_observaciones_detalle', COUNT(*)
FROM public.vw_observaciones_detalle
UNION ALL
SELECT 'vw_eventos_transito_detalle', COUNT(*)
FROM public.vw_eventos_transito_detalle
ORDER BY vista;