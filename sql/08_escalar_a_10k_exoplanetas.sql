-- CS2041 Bases de Datos I | Hito 2 | Preparacion para experimentos
-- Escenario 10K: exactamente 10 000 OBSERVACIONES y 10 000 EVENTOS DE TRANSITO.
-- Datos 100% SINTETICOS, basados en el esquema de Andre (Hito 1).
-- IMPORTANTE: guardar ANTES el dump de 1K mediante Backup en pgAdmin.
-- EJECUTAR SOLO sobre exoplanetas_bd, despues de los scripts 01 a 07.
-- Seguro para repetir: las claves existentes no se duplican.
-- Mantiene los triggers de integridad ACTIVADOS y no elimina registros.

BEGIN;

-- Agrega 9 000 observaciones nuevas sin tocar las 1 000 originales.
-- Los patrones de datos se mantienen comparables entre las distintas escalas.
INSERT INTO public.observacion (
    id_observacion, fecha, duracion, filtro, metodo,
    nombre_mision, nombre_telescopio, id_estrella
)
SELECT
    g,
    DATE '2021-01-01' + ((g - 1) % 1500),
    round((20 + (g % 130) * 1.5)::numeric, 2),
    CASE WHEN g % 10 = 0 THEN NULL::text
         ELSE CASE g % 3 WHEN 0 THEN 'visible' WHEN 1 THEN 'infrarrojo' ELSE 'sin filtro' END
    END,
    'fotometria de transito',
    CASE WHEN g % 5 = 0 THEN NULL::text
         ELSE 'Mision-Simulada-' || lpad((((g - 1) % 4) + 1)::text, 2, '0') END,
    'Telescopio-Simulado-' || lpad((((g - 1) % 6) + 1)::text, 2, '0'),
    ((g - 1) % 200) + 1
FROM generate_series(1001, 10000) AS serie(g)
ON CONFLICT (id_observacion) DO NOTHING;

-- Un evento por observacion, siempre asociado a un exoplaneta
-- perteneciente a la misma estrella. El trigger comprueba esa regla.
INSERT INTO public.evento_transito (
    id_observacion, nro_evento, fecha_inicio, duracion,
    profundidad, snr, metodo_deteccion, id_exoplaneta
)
SELECT
    o.id_observacion,
    1,
    o.fecha::timestamp + INTERVAL '1 hour',
    round((0.5 + (o.id_observacion % 60) / 10.0)::numeric, 2),
    round((0.001 + (o.id_observacion % 50) / 10000.0)::numeric, 5),
    CASE WHEN o.id_observacion % 20 = 0 THEN NULL::numeric
         ELSE round((5 + (o.id_observacion % 120) / 10.0)::numeric, 2)
    END,
    'transito',
    o.id_estrella + CASE WHEN o.id_observacion % 3 = 0 THEN 200 ELSE 0 END
FROM public.observacion AS o
WHERE o.id_observacion BETWEEN 1001 AND 10000
ON CONFLICT (id_observacion, nro_evento) DO NOTHING;

-- Si los totales no son correctos, no guardamos una carga incompleta.
DO $$
BEGIN
    IF (SELECT count(*) FROM public.observacion) <> 10000 THEN
        RAISE EXCEPTION 'No hay exactamente 10000 observaciones. Revise los datos antes de seguir.';
    END IF;
    IF (SELECT count(*) FROM public.evento_transito) <> 10000 THEN
        RAISE EXCEPTION 'No hay exactamente 10000 eventos. Revise los datos antes de seguir.';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM public.evento_transito AS e
        JOIN public.observacion AS o ON o.id_observacion = e.id_observacion
        JOIN public.exoplaneta AS p ON p.id_exoplaneta = e.id_exoplaneta
        WHERE o.id_estrella <> p.id_estrella
    ) THEN
        RAISE EXCEPTION 'Se detectaron inconsistencias entre observaciones y exoplanetas.';
    END IF;
END;
$$;

COMMIT;

-- Actualiza las estadisticas del optimizador de PostgreSQL.
ANALYZE public.observacion;
ANALYZE public.evento_transito;

-- EVIDENCIA: deben aparecer 3 filas, con 10000, 10000 y 0.
SELECT 'observaciones' AS comprobacion, count(*)::bigint AS resultado
FROM public.observacion
UNION ALL
SELECT 'eventos_transito', count(*) FROM public.evento_transito
UNION ALL
SELECT 'incoherencias', count(*)
FROM public.evento_transito AS e
JOIN public.observacion AS o ON o.id_observacion = e.id_observacion
JOIN public.exoplaneta AS p ON p.id_exoplaneta = e.id_exoplaneta
WHERE o.id_estrella <> p.id_estrella;