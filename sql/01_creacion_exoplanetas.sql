-- CS2041 | Mapeo y deteccion de exoplanetas
-- Esquema relacional

BEGIN;

CREATE TABLE public.mision_espacial (
    nombre TEXT PRIMARY KEY,
    agencia TEXT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    objetivo TEXT,
    estado TEXT NOT NULL,
    CONSTRAINT ck_mision_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE public.telescopio (
    nombre TEXT PRIMARY KEY,
    tipo TEXT NOT NULL,
    ubicacion TEXT,
    apertura NUMERIC,
    longitud_onda NUMERIC,
    estado TEXT NOT NULL,
    CONSTRAINT ck_telescopio_apertura CHECK (apertura IS NULL OR apertura > 0),
    CONSTRAINT ck_telescopio_longitud_onda CHECK (longitud_onda IS NULL OR longitud_onda > 0)
);

CREATE TABLE public.estrella (
    id_estrella INTEGER PRIMARY KEY,
    nombre TEXT,
    declinacion NUMERIC NOT NULL,
    distancia NUMERIC,
    ascension_recta NUMERIC NOT NULL,
    radio NUMERIC,
    masa NUMERIC,
    tipo_espectral TEXT,
    CONSTRAINT ck_estrella_distancia CHECK (distancia IS NULL OR distancia >= 0),
    CONSTRAINT ck_estrella_radio CHECK (radio IS NULL OR radio > 0),
    CONSTRAINT ck_estrella_masa CHECK (masa IS NULL OR masa > 0)
);

CREATE TABLE public.exoplaneta (
    id_exoplaneta INTEGER PRIMARY KEY,
    nombre TEXT,
    masa NUMERIC,
    radio NUMERIC,
    periodo_orbital NUMERIC,
    estado TEXT NOT NULL,
    id_estrella INTEGER NOT NULL,
    CONSTRAINT fk_exoplaneta_estrella FOREIGN KEY (id_estrella)
        REFERENCES public.estrella(id_estrella),
    CONSTRAINT ck_exoplaneta_masa CHECK (masa IS NULL OR masa > 0),
    CONSTRAINT ck_exoplaneta_radio CHECK (radio IS NULL OR radio > 0),
    CONSTRAINT ck_exoplaneta_periodo CHECK (periodo_orbital IS NULL OR periodo_orbital > 0)
);

CREATE TABLE public.observacion (
    id_observacion INTEGER PRIMARY KEY,
    fecha DATE NOT NULL,
    duracion NUMERIC NOT NULL,
    filtro TEXT,
    metodo TEXT,
    nombre_mision TEXT,
    nombre_telescopio TEXT NOT NULL,
    id_estrella INTEGER NOT NULL,
    CONSTRAINT fk_observacion_mision FOREIGN KEY (nombre_mision)
        REFERENCES public.mision_espacial(nombre),
    CONSTRAINT fk_observacion_telescopio FOREIGN KEY (nombre_telescopio)
        REFERENCES public.telescopio(nombre),
    CONSTRAINT fk_observacion_estrella FOREIGN KEY (id_estrella)
        REFERENCES public.estrella(id_estrella),
    CONSTRAINT ck_observacion_duracion CHECK (duracion > 0)
);

CREATE TABLE public.miembro_mision (
    nombre_mision TEXT NOT NULL,
    nro_miembro INTEGER NOT NULL,
    nombre TEXT NOT NULL,
    rol TEXT NOT NULL,
    especialidad TEXT,
    correo TEXT,
    CONSTRAINT pk_miembro_mision PRIMARY KEY (nombre_mision, nro_miembro),
    CONSTRAINT fk_miembro_mision FOREIGN KEY (nombre_mision)
        REFERENCES public.mision_espacial(nombre)
);

CREATE TABLE public.evento_transito (
    id_observacion INTEGER NOT NULL,
    nro_evento INTEGER NOT NULL,
    fecha_inicio TIMESTAMP NOT NULL,
    duracion NUMERIC NOT NULL,
    profundidad NUMERIC NOT NULL,
    snr NUMERIC,
    metodo_deteccion TEXT,
    id_exoplaneta INTEGER NOT NULL,
    CONSTRAINT pk_evento_transito PRIMARY KEY (id_observacion, nro_evento),
    CONSTRAINT fk_evento_observacion FOREIGN KEY (id_observacion)
        REFERENCES public.observacion(id_observacion),
    CONSTRAINT fk_evento_exoplaneta FOREIGN KEY (id_exoplaneta)
        REFERENCES public.exoplaneta(id_exoplaneta),
    CONSTRAINT ck_evento_duracion CHECK (duracion > 0),
    CONSTRAINT ck_evento_profundidad CHECK (profundidad >= 0),
    CONSTRAINT ck_evento_snr CHECK (snr IS NULL OR snr >= 0)
);

CREATE TABLE public.utiliza (
    nombre_mision TEXT NOT NULL,
    nro_miembro INTEGER NOT NULL,
    nombre_telescopio TEXT NOT NULL,
    CONSTRAINT pk_utiliza PRIMARY KEY (nombre_mision, nro_miembro, nombre_telescopio),
    CONSTRAINT fk_utiliza_miembro FOREIGN KEY (nombre_mision, nro_miembro)
        REFERENCES public.miembro_mision(nombre_mision, nro_miembro),
    CONSTRAINT fk_utiliza_telescopio FOREIGN KEY (nombre_telescopio)
        REFERENCES public.telescopio(nombre)
);

COMMIT;

SELECT table_name AS tabla_creada
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
  AND table_name IN (
      'mision_espacial', 'telescopio', 'estrella', 'exoplaneta',
      'observacion', 'miembro_mision', 'evento_transito', 'utiliza'
  )
ORDER BY table_name;
