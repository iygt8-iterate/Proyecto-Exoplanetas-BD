-- CS2041 | Mapeo y deteccion de exoplanetas
-- Verificacion visual: 1 000 000 de registros
-- Cinco consultas con escenarios independientes

-- Q1. Observaciones por estrella
-- Q2. Telescopios y senal
-- Q3. Actividad de mision
-- Q4. Exoplanetas y transitos
-- Q5. Espectro y telescopios

SELECT current_database() AS base_seleccionada,
       (SELECT COUNT(*) FROM public.observacion) AS observaciones,
       (SELECT COUNT(*) FROM public.evento_transito) AS eventos_transito;
