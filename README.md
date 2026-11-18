# Mapeo y Detección de Exoplanetas

**CS2041 — Bases de Datos I · UTEC · 2026-II**  
**Sistema gestor:** PostgreSQL

Proyecto de diseño, implementación y evaluación de una base de datos relacional para el registro de estrellas anfitrionas, exoplanetas, telescopios, observaciones, eventos de tránsito y misiones espaciales.

## Componentes

El modelo incluye ocho tablas relacionales, restricciones de integridad, tres vistas de usuario, tres procedimientos almacenados, tres triggers y cinco vistas de consulta destinadas a la experimentación.

## Organización

| Directorio | Contenido |
|---|---|
| `sql/` | Definición, implementación, carga y experimentación |
| `experimentos/` | Resultados estadísticos y planes de ejecución |
| `informe/` | Documentación académica en LaTeX |
| `evidencias/` | Evidencia gráfica y audiovisual |

## Scripts SQL

| Archivo | Descripción |
|---|---|
| `01_creacion_exoplanetas.sql` | Esquema relacional y restricciones |
| `02_carga_datos_prueba_exoplanetas.sql` | Datos sintéticos iniciales |
| `03_simulacion_datos_faltantes_exoplanetas.sql` | Simulación de valores NULL |
| `04_vistas_exoplanetas.sql` | Vistas de usuario |
| `05_procedimientos_exoplanetas.sql` | Procedimientos almacenados |
| `06_triggers_exoplanetas.sql` | Triggers de integridad |
| `07_consultas_intermedias_exoplanetas.sql` | Consultas Q1–Q5 |
| `08_escalar_a_10k_exoplanetas.sql` | Escalamiento a 10 000 |
| `09_escalar_a_100k_exoplanetas.sql` | Escalamiento a 100 000 |
| `10_experimento_100k_exoplanetas.sql` | Medición de 100 000 |
| `11_experimento_1k_exoplanetas.sql` | Medición de 1 000 |
| `12_experimento_10k_exoplanetas.sql` | Medición de 10 000 |
| `13_escalar_a_1M_exoplanetas.sql` | Escalamiento a 1 000 000 |
| `14_experimento_1M_exoplanetas.sql` | Medición de 1 000 000 |
| `15_verificacion_visual_1M_exoplanetas.sql` | Verificación comparativa de planes en 1M |

## Experimentación

Se consideran cuatro escalas: 1 000, 10 000, 100 000 y 1 000 000 registros en **cada una** de las tablas `observacion` y `evento_transito`. La comparación evalúa cinco consultas con y sin índices secundarios candidatos, conservando los índices estructurales de las claves primarias.

Los scripts de medición emplean `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` y registran los tiempos y planes en `public.resultados_hito2`. El script 15 documenta la comparación visual en la escala de 1M mediante una transacción revertida al concluir.

Los datos de prueba son sintéticos y no corresponden a un catálogo observacional real.

## Reproducción

La implementación utiliza `exoplanetas_bd` como base principal. Los scripts 01–09 establecen el esquema y las tres primeras escalas; las experimentaciones de 1K y 10K emplean bases restauradas independientes. La carga de 1M parte del escenario de 100K.

Los scripts de escalamiento y medición comprueban la base y el volumen antes de operar. Los índices candidatos de los experimentos automáticos se retiran al concluir cada medición.

## Artefactos complementarios

Los respaldos `.backup`, las grabaciones y los datos de acceso al servidor se distribuyen por separado del código fuente.
