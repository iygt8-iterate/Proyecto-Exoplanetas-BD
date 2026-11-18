# Experimentación

Resultados de rendimiento por escala, consulta y configuración de índices.

Los cinco archivos CSV de este directorio presentan **promedios resumidos** transcritos de las tablas de resultados de pgAdmin, para las escalas 1K, 10K, 100K y 1M. Hay cinco consultas por escala. Cada consulta se midió tres veces por escenario: sin los índices secundarios candidatos y con los cinco índices candidatos activos simultáneamente.

**Estos CSV no son las exportaciones originales de las mediciones individuales** ni incluyen los planes JSON. Los scripts de experimento (10, 11, 12 y 14) registran los 120 tiempos individuales y los planes en la tabla `public.resultados_hito2` de cada base PostgreSQL. Las cifras se mantienen con la precisión mostrada en las capturas originales; los porcentajes provienen del resumen del experimento.

El resultado adverso de Q4 en 10K (**2.454 ms frente a 15.185 ms; mejora -518.79 %**) se conserva íntegramente.

Los respaldos de las cuatro escalas y los videos se conservan fuera de este directorio.
