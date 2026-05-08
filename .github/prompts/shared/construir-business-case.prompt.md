---
description: Construye el caso de negocio (TCO actual + ROI + riesgo de no hacer + ejecutivo) usando los templates de business-case/. Pregunta al usuario por datos faltantes en vez de inventar.
---

# Construir Business Case (Fase 0)

Construye el caso de negocio para modernizar **{{ProjectName}}** ({{ClientName}}) de **{{LegacyTech}}** a **{{TargetStack}}**, hospedado en **{{CloudProvider}}**.

## Pasos

1. Lee `assessment/_templates/` para entender la estructura.
2. Entrevista al usuario para los datos faltantes (TCO actual por categoría, FTEs, costos cloud, restricciones).
3. Copia los 4 templates a `assessment/{{ProjectName}}/` con la fecha actual: `<categoria>-DDMMYYYY.md`.
4. Marca cada dato no validado como `{{PENDIENTE: ...}}` en lugar de inventarlo.
5. Cierra con `business-case-ejecutivo-DDMMYYYY.md` consolidado para el sponsor.
6. Genera el HTML autocontenido de cada reporte: `./scripts/md2html.sh assessment/{{ProjectName}}/<archivo>.md`.
7. Lista al final los "Insumos pendientes" y la **recomendación final**: proceder a Fase 1, ajustar alcance, o no modernizar.

## Reglas

- Rangos pesimista / base / optimista en cifras estimadas.
- Fuentes verificables para fechas EOL, multas regulatorias, tarifas de mercado.
- Sensibilidad sobre al menos 3 variables.
- Disclaimer de "estimaciones, no compromisos contractuales".
