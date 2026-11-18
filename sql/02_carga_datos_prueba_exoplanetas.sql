-- CS2041 - Hito 2 - Etapa 2: carga inicial de datos sinteticos
-- Proyecto: Mapeo y Deteccion de Exoplanetas
-- EJECUTAR SOLO en exoplanetas_bd, DESPUES de 01_creacion_exoplanetas.sql
-- Prueba inicial: 1 000 observaciones y 1 000 eventos de transito.
-- Todos los registros de este script son SINTETICOS; no representan datos reales de NASA.
-- No elimina datos. ON CONFLICT permite ejecutarlo nuevamente sin duplicar claves.

BEGIN;

-- 1. Misiones (4) y telescopios (6): entidades referenciadas por otras tablas.
INSERT INTO public.mision_espacial
    (nombre, agencia, fecha_inicio, fecha_fin, objetivo, estado)
SELECT
    'Mision-Simulada-' || lpad(g::text, 2, '0'),
    'Agencia academica simulada',
    DATE '2020-01-01' + (g * 90),
    NULL::date,
    'Estudiar exoplanetas mediante observaciones sinteticas',
    'activa'
FROM generate_series(1, 4) AS s(g)
ON CONFLICT DO NOTHING;

INSERT INTO public.telescopio
    (nombre, tipo, ubicacion, apertura, longitud_onda, estado)
SELECT
    'Telescopio-Simulado-' || lpad(g::text, 2, '0'),
    CASE WHEN g % 2 = 0 THEN 'espacial' ELSE 'terrestre' END,
    'Ubicacion simulada ' || g,
    round((0.8 + g * 0.35)::numeric, 2),
    round((350 + g * 55)::numeric, 2),
    'operativo'
FROM generate_series(1, 6) AS s(g)
ON CONFLICT DO NOTHING;

-- 2. Estrellas (200) y exoplanetas (400 = 2 por estrella).
INSERT INTO public.estrella
    (id_estrella, nombre, declinacion, distancia, ascension_recta, radio, masa, tipo_espectral)
SELECT
    g,
    'Estrella-Simulada-' || lpad(g::text, 4, '0'),
    round((-80 + (g * 13 % 161))::numeric, 2),
    round((10 + (g * 37 % 1500) / 10.0)::numeric, 2),
    round(((g * 19 % 3600) / 10.0)::numeric, 2),
    round((0.45 + (g % 30) / 20.0)::numeric, 2),
    round((0.55 + (g % 25) / 25.0)::numeric, 2),
    CASE g % 4 WHEN 0 THEN 'G' WHEN 1 THEN 'K' WHEN 2 THEN 'M' ELSE 'F' END
FROM generate_series(1, 200) AS s(g)
ON CONFLICT DO NOTHING;

INSERT INTO public.exoplaneta
    (id_exoplaneta, nombre, masa, radio, periodo_orbital, estado, id_estrella)
SELECT
    g,
    'Exoplaneta-Simulado-' || lpad(g::text, 4, '0'),
    round((0.25 + (g % 80) / 10.0)::numeric, 2),
    round((0.35 + (g % 40) / 10.0)::numeric, 2),
    round((1 + (g % 250) * 0.73)::numeric, 2),
    CASE WHEN g % 7 = 0 THEN 'candidato' ELSE 'confirmado' END,
    ((g - 1) % 200) + 1
FROM generate_series(1, 400) AS s(g)
ON CONFLICT DO NOTHING;

-- 3. Miembros de mision (20) y relaciones de uso de telescopio (20).
INSERT INTO public.miembro_mision
    (nombre_mision, nro_miembro, nombre, rol, especialidad, correo)
SELECT
    'Mision-Simulada-' || lpad(m::text, 2, '0'),
    n,
    'Investigador Simulado ' || m || '-' || n,
    CASE WHEN n = 1 THEN 'coordinador' ELSE 'analista' END,
    'astronomia',
    'investigador' || m || '_' || n || '@example.invalid'
FROM generate_series(1, 4) AS mis(m)
CROSS JOIN generate_series(1, 5) AS miem(n)
ON CONFLICT DO NOTHING;

INSERT INTO public.utiliza (nombre_mision, nro_miembro, nombre_telescopio)
SELECT
    'Mision-Simulada-' || lpad(m::text, 2, '0'),
    n,
    'Telescopio-Simulado-' || lpad(((((m - 1) * 5 + n - 1) % 6) + 1)::text, 2, '0')
FROM generate_series(1, 4) AS mis(m)
CROSS JOIN generate_series(1, 5) AS miem(n)
ON CONFLICT DO NOTHING;

-- 4. Observaciones (1 000). Cada observacion referencia estrella y telescopio existentes.
-- Algunas observaciones no pertenecen a ninguna mision, tal como permite el Hito 1.
INSERT INTO public.observacion
    (id_observacion, fecha, duracion, filtro, metodo,
     nombre_mision, nombre_telescopio, id_estrella)
SELECT
    g,
    DATE '2021-01-01' + ((g - 1) % 1500),
    round((20 + (g % 130) * 1.5)::numeric, 2),
    CASE g % 3 WHEN 0 THEN 'visible' WHEN 1 THEN 'infrarrojo' ELSE 'sin filtro' END,
    'fotometria de transito',
    CASE WHEN g % 5 = 0 THEN NULL::text
         ELSE 'Mision-Simulada-' || lpad((((g - 1) % 4) + 1)::text, 2, '0') END,
    'Telescopio-Simulado-' || lpad((((g - 1) % 6) + 1)::text, 2, '0'),
    ((g - 1) % 200) + 1
FROM generate_series(1, 1000) AS s(g)
ON CONFLICT DO NOTHING;

-- 5. Eventos (1 000). El exoplaneta elegido pertenece a la MISMA estrella observada.
INSERT INTO public.evento_transito
    (id_observacion, nro_evento, fecha_inicio, duracion,
     profundidad, snr, metodo_deteccion, id_exoplaneta)
SELECT
    o.id_observacion,
    1,
    o.fecha::timestamp + INTERVAL '1 hour',
    round((0.5 + (o.id_observacion % 60) / 10.0)::numeric, 2),
    round((0.001 + (o.id_observacion % 50) / 10000.0)::numeric, 5),
    round((5 + (o.id_observacion % 120) / 10.0)::numeric, 2),
    'transito',
    o.id_estrella + CASE WHEN o.id_observacion % 3 = 0 THEN 200 ELSE 0 END
FROM public.observacion AS o
WHERE o.id_observacion BETWEEN 1 AND 1000
ON CONFLICT DO NOTHING;

COMMIT;

-- VERIFICACION B: debe dar 0 incoherencias entre estrella observada y exoplaneta.
SELECT count(*) AS incoherencias_estrella_exoplaneta
FROM public.evento_transito AS e
JOIN public.observacion AS o ON o.id_observacion = e.id_observacion
JOIN public.exoplaneta AS p ON p.id_exoplaneta = e.id_exoplaneta
WHERE o.id_estrella <> p.id_estrella;

-- VERIFICACION A: debe haber 8 filas con las cantidades indicadas.
SELECT 'mision_espacial' AS tabla, count(*) AS registros FROM public.mision_espacial
UNION ALL SELECT 'telescopio', count(*) FROM public.telescopio
UNION ALL SELECT 'estrella', count(*) FROM public.estrella
UNION ALL SELECT 'exoplaneta', count(*) FROM public.exoplaneta
UNION ALL SELECT 'miembro_mision', count(*) FROM public.miembro_mision
UNION ALL SELECT 'utiliza', count(*) FROM public.utiliza
UNION ALL SELECT 'observacion', count(*) FROM public.observacion
UNION ALL SELECT 'evento_transito', count(*) FROM public.evento_transito
ORDER BY tabla;
