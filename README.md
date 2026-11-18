# Proyecto-Exoplanetas-BD

**CS2041 — Bases de Datos I · UTEC · 2026-II**  
**Proyecto:** Mapeo y Detección de Exoplanetas · PostgreSQL

Implementación académica de una base relacional de estrellas, exoplanetas, observaciones, eventos de tránsito, telescopios y misiones espaciales.

## Estructura

- `sql/`: scripts SQL originales, numerados según su desarrollo.
- `experimentos/`: espacio para resultados CSV y análisis de rendimiento.
- `informe/`: espacio para el informe final en LaTeX.
- `evidencias/`: espacio para capturas y enlaces de demostración.

## Orden de scripts

| Script | Función |
|---|---|
| 01 | Creación de tablas y restricciones |
| 02 | Carga sintética inicial |
| 03 | Simulación de datos faltantes |
| 04 | Vistas |
| 05 | Procedimientos almacenados |
| 06 | Triggers |
| 07 | Cinco consultas intermedias |
| 08 | Escalamiento hasta 10K |
| 09 | Escalamiento hasta 100K |
| 10 | Experimento de 100K |
| 11 | Experimento de 1K |
| 12 | Experimento de 10K |
| 13 | Escalamiento hasta 1M (pendiente de verificar ejecución) |

Los archivos se encuentran en `sql/` y conservan sus nombres originales.

## Reproducción

1. Preparar una base PostgreSQL vacía denominada `exoplanetas_bd`.
2. Ejecutar los scripts 01–07 en orden. Revisar cada script antes de volver a ejecutarlo: no todos son idempotentes.
3. Generar y respaldar cada escala con 08 y 09, partiendo de la anterior.
4. Ejecutar los experimentos 1K y 10K sobre bases restauradas independientes; el experimento 100K sobre la base de 100K.
5. Ejecutar 13 **una sola vez** sobre la base principal de 100K, después de verificar sus condiciones iniciales.

**Nota:** 1K, 10K, 100K y 1M se refieren a la cantidad de filas de cada una de las tablas `observacion` y `evento_transito`, no al total de filas de toda la base. Los índices de claves primarias permanecen presentes en los experimentos; se compara la adición de índices secundarios.

## Material pendiente

- CSV originales de 1K, 10K y 100K, aún no recuperados de la laptop.
- Resultados y planes del millón, una vez ejecutados y verificados.
- Informe LaTeX, capturas y enlaces reales a videos.

Los respaldos `.backup`, credenciales y videos pesados deben permanecer fuera del repositorio. Los datos de prueba son sintéticos.
