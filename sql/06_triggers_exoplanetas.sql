-- CS2041 | Mapeo y deteccion de exoplanetas
-- Triggers de integridad

BEGIN;
-- Trigger 1. Integridad de eventos
CREATE OR REPLACE FUNCTION public.fn_validar_evento_estrella()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_estrella_observacion INTEGER;
    v_estrella_exoplaneta INTEGER;
BEGIN
    SELECT id_estrella INTO v_estrella_observacion
    FROM public.observacion
    WHERE id_observacion = NEW.id_observacion;
    SELECT id_estrella INTO v_estrella_exoplaneta
    FROM public.exoplaneta
    WHERE id_exoplaneta = NEW.id_exoplaneta;
    IF v_estrella_observacion IS NOT NULL
       AND v_estrella_exoplaneta IS NOT NULL
       AND v_estrella_observacion <> v_estrella_exoplaneta THEN
        RAISE EXCEPTION 'Evento incoherente: observacion % y exoplaneta % corresponden a estrellas diferentes',
            NEW.id_observacion, NEW.id_exoplaneta
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_validar_evento_estrella ON public.evento_transito;
CREATE TRIGGER trg_validar_evento_estrella
BEFORE INSERT OR UPDATE OF id_observacion, id_exoplaneta
ON public.evento_transito
FOR EACH ROW
EXECUTE FUNCTION public.fn_validar_evento_estrella();
-- Trigger 2. Integridad de observaciones
CREATE OR REPLACE FUNCTION public.fn_validar_cambio_estrella_observacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.evento_transito AS e
        JOIN public.exoplaneta AS p ON p.id_exoplaneta = e.id_exoplaneta
        WHERE e.id_observacion = NEW.id_observacion
          AND p.id_estrella <> NEW.id_estrella
    ) THEN
        RAISE EXCEPTION 'No se puede cambiar la estrella de la observacion %: sus eventos quedarian incoherentes',
            NEW.id_observacion
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_validar_estrella_observacion ON public.observacion;
CREATE TRIGGER trg_validar_estrella_observacion
BEFORE UPDATE OF id_estrella
ON public.observacion
FOR EACH ROW
WHEN (OLD.id_estrella IS DISTINCT FROM NEW.id_estrella)
EXECUTE FUNCTION public.fn_validar_cambio_estrella_observacion();
-- Trigger 3. Integridad de exoplanetas
CREATE OR REPLACE FUNCTION public.fn_validar_cambio_estrella_exoplaneta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.evento_transito AS e
        JOIN public.observacion AS o ON o.id_observacion = e.id_observacion
        WHERE e.id_exoplaneta = NEW.id_exoplaneta
          AND o.id_estrella <> NEW.id_estrella
    ) THEN
        RAISE EXCEPTION 'No se puede cambiar la estrella del exoplaneta %: sus eventos quedarian incoherentes',
            NEW.id_exoplaneta
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_validar_estrella_exoplaneta ON public.exoplaneta;
CREATE TRIGGER trg_validar_estrella_exoplaneta
BEFORE UPDATE OF id_estrella
ON public.exoplaneta
FOR EACH ROW
WHEN (OLD.id_estrella IS DISTINCT FROM NEW.id_estrella)
EXECUTE FUNCTION public.fn_validar_cambio_estrella_exoplaneta();
COMMIT;
BEGIN;
DO $$
DECLARE
    v_observacion INTEGER;
    v_planeta INTEGER;
    v_estrella_original INTEGER;
    v_otra_estrella INTEGER;
    v_otro_planeta INTEGER;
    v_nro_evento INTEGER;
    v_rechazo BOOLEAN;
BEGIN
    SELECT e.id_observacion, e.id_exoplaneta, o.id_estrella
    INTO v_observacion, v_planeta, v_estrella_original
    FROM public.evento_transito AS e
    JOIN public.observacion AS o ON o.id_observacion = e.id_observacion
    ORDER BY e.id_observacion, e.nro_evento
    LIMIT 1;
    SELECT id_estrella INTO v_otra_estrella
    FROM public.estrella WHERE id_estrella <> v_estrella_original
    ORDER BY id_estrella LIMIT 1;
    SELECT id_exoplaneta INTO v_otro_planeta
    FROM public.exoplaneta WHERE id_estrella = v_otra_estrella
    ORDER BY id_exoplaneta LIMIT 1;
    SELECT COALESCE(MAX(nro_evento), 0) + 1 INTO v_nro_evento
    FROM public.evento_transito WHERE id_observacion = v_observacion;
    IF v_observacion IS NULL OR v_planeta IS NULL
       OR v_otra_estrella IS NULL OR v_otro_planeta IS NULL THEN
        RAISE EXCEPTION 'Faltan datos para probar los triggers';
    END IF;
    v_rechazo := FALSE;
    BEGIN
        INSERT INTO public.evento_transito
            (id_observacion, nro_evento, fecha_inicio, duracion,
             profundidad, snr, metodo_deteccion, id_exoplaneta)
        VALUES
            (v_observacion, v_nro_evento, CURRENT_TIMESTAMP::timestamp,
             1, 0.01, 10, 'prueba', v_otro_planeta);
    EXCEPTION WHEN check_violation THEN
        v_rechazo := TRUE;
    END;
    IF NOT v_rechazo THEN
        RAISE EXCEPTION 'Fallo la prueba del trigger de evento';
    END IF;
    v_rechazo := FALSE;
    BEGIN
        UPDATE public.observacion
        SET id_estrella = v_otra_estrella
        WHERE id_observacion = v_observacion;
    EXCEPTION WHEN check_violation THEN
        v_rechazo := TRUE;
    END;
    IF NOT v_rechazo THEN
        RAISE EXCEPTION 'Fallo la prueba del trigger de observacion';
    END IF;
    v_rechazo := FALSE;
    BEGIN
        UPDATE public.exoplaneta
        SET id_estrella = v_otra_estrella
        WHERE id_exoplaneta = v_planeta;
    EXCEPTION WHEN check_violation THEN
        v_rechazo := TRUE;
    END;
    IF NOT v_rechazo THEN
        RAISE EXCEPTION 'Fallo la prueba del trigger de exoplaneta';
    END IF;
    RAISE NOTICE 'OK: los 3 triggers rechazaron las inconsistencias de prueba';
END;
$$;
ROLLBACK;
SELECT c.relname AS tabla, t.tgname AS trigger, t.tgenabled AS enabled
FROM pg_catalog.pg_trigger AS t
JOIN pg_catalog.pg_class AS c ON c.oid = t.tgrelid
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND NOT t.tgisinternal
  AND t.tgname IN (
      'trg_validar_evento_estrella',
      'trg_validar_estrella_observacion',
      'trg_validar_estrella_exoplaneta'
  )
ORDER BY tabla, trigger;
