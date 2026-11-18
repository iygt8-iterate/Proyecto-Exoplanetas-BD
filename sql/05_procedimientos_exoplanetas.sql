-- CS2041 | Mapeo y deteccion de exoplanetas
-- Procedimientos almacenados

BEGIN;

-- 1) Registrar una observacion con las referencias definidas en el H
CREATE OR REPLACE PROCEDURE public.registrar_observacion(
    p_id_observacion INTEGER,
    p_fecha DATE,
    p_duracion NUMERIC,
    p_nombre_telescopio TEXT,
    p_id_estrella INTEGER,
    p_nombre_mision TEXT DEFAULT NULL,
    p_filtro TEXT DEFAULT NULL,
    p_metodo TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_duracion IS NULL OR p_duracion <= 0 THEN
        RAISE EXCEPTION 'La duracion de la observacion debe ser positiva';
    END IF;

    INSERT INTO public.observacion (
        id_observacion, fecha, duracion, filtro, metodo,
        nombre_mision, nombre_telescopio, id_estrella
    ) VALUES (
        p_id_observacion, p_fecha, p_duracion, p_filtro, p_metodo,
        p_nombre_mision, p_nombre_telescopio, p_id_estrella
    );
END;
$$;

-- 2) Registrar un transito
CREATE OR REPLACE PROCEDURE public.registrar_evento_transito(
    p_id_observacion INTEGER,
    p_nro_evento INTEGER,
    p_fecha_inicio TIMESTAMP,
    p_duracion NUMERIC,
    p_profundidad NUMERIC,
    p_snr NUMERIC,
    p_metodo_deteccion TEXT,
    p_id_exoplaneta INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estrella_observada INTEGER;
    v_estrella_planeta INTEGER;
BEGIN
    SELECT id_estrella INTO v_estrella_observada
    FROM public.observacion
    WHERE id_observacion = p_id_observacion;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la observacion %', p_id_observacion;
    END IF;

    SELECT id_estrella INTO v_estrella_planeta
    FROM public.exoplaneta
    WHERE id_exoplaneta = p_id_exoplaneta;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el exoplaneta %', p_id_exoplaneta;
    END IF;

    IF v_estrella_observada <> v_estrella_planeta THEN
        RAISE EXCEPTION 'El exoplaneta % no pertenece a la estrella observada en %',
            p_id_exoplaneta, p_id_observacion;
    END IF;

    INSERT INTO public.evento_transito (
        id_observacion, nro_evento, fecha_inicio, duracion,
        profundidad, snr, metodo_deteccion, id_exoplaneta
    ) VALUES (
        p_id_observacion, p_nro_evento, p_fecha_inicio, p_duracion,
        p_profundidad, p_snr, p_metodo_deteccion, p_id_exoplaneta
    );
END;
$$;

-- 3) Actualizar el estado de un exoplaneta existente
CREATE OR REPLACE PROCEDURE public.actualizar_estado_exoplaneta(
    p_id_exoplaneta INTEGER,
    p_estado TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_estado IS NULL OR btrim(p_estado) = '' THEN
        RAISE EXCEPTION 'El nuevo estado no puede estar vacio';
    END IF;

    UPDATE public.exoplaneta
    SET estado = p_estado
    WHERE id_exoplaneta = p_id_exoplaneta;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el exoplaneta %', p_id_exoplaneta;
    END IF;
END;
$$;

COMMIT;

BEGIN;
DO $$
DECLARE
    v_id_obs INTEGER;
    v_telescopio TEXT;
    v_id_estrella INTEGER;
    v_id_exoplaneta INTEGER;
BEGIN
    SELECT COALESCE(MAX(id_observacion), 0) + 1 INTO v_id_obs
    FROM public.observacion;

    SELECT nombre INTO v_telescopio FROM public.telescopio ORDER BY nombre LIMIT 1;
    SELECT id_estrella INTO v_id_estrella FROM public.estrella ORDER BY id_estrella LIMIT 1;
    SELECT id_exoplaneta INTO v_id_exoplaneta FROM public.exoplaneta
    WHERE id_estrella = v_id_estrella ORDER BY id_exoplaneta LIMIT 1;

    IF v_telescopio IS NULL OR v_id_estrella IS NULL OR v_id_exoplaneta IS NULL THEN
        RAISE EXCEPTION 'No hay suficientes datos para las pruebas';
    END IF;

    CALL public.registrar_observacion(
        v_id_obs, CURRENT_DATE, 30, v_telescopio, v_id_estrella,
        NULL, 'prueba', 'fotometria'
    );

    CALL public.registrar_evento_transito(
        v_id_obs, 1, CURRENT_TIMESTAMP::TIMESTAMP, 2,
        0.01, 12, 'transito', v_id_exoplaneta
    );

    CALL public.actualizar_estado_exoplaneta(v_id_exoplaneta, 'confirmado');

    IF NOT EXISTS (SELECT 1 FROM public.observacion WHERE id_observacion = v_id_obs)
       OR NOT EXISTS (SELECT 1 FROM public.evento_transito
                      WHERE id_observacion = v_id_obs AND nro_evento = 1)
       OR NOT EXISTS (SELECT 1 FROM public.exoplaneta
                      WHERE id_exoplaneta = v_id_exoplaneta AND estado = 'confirmado')
    THEN
        RAISE EXCEPTION 'Fallo la verificacion de algun procedimiento';
    END IF;

    RAISE NOTICE 'Prueba completada: los 3 procedimientos funcionan; se revertiran los datos de prueba';
END;
$$;
ROLLBACK;

SELECT p.proname AS procedimiento
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.prokind = 'p'
  AND p.proname IN (
      'registrar_observacion',
      'registrar_evento_transito',
      'actualizar_estado_exoplaneta'
  )
ORDER BY p.proname;
