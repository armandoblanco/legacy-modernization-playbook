---
description: Ejecuta el assessment de seguridad whitehat sobre legacy/ y genera reporte MD + HTML autocontenido en assessment/{ProjectName}/seguridad-DDMMYYYY.{md,html}.
---

# Ejecutar assessment de seguridad (Fase 0)

Para **{{ProjectName}}** ({{ClientName}}), tecnología legacy **{{LegacyTech}}**:

1. Invoca a `@security-assessor` para revisar el código en `legacy/`.
2. Responde sus preguntas: marco regulatorio aplicable, exposición (intranet/internet/B2B), si el snapshot incluye credenciales reales.
3. El agente debe:
   - Mapear hallazgos a OWASP Top 10, CWE, MITRE ATT&CK
   - Modelar STRIDE sobre los flujos relevantes
   - Listar dependencias con CVE conocidos
   - Cada hallazgo con `archivo:línea` + snippet ≤ 10 líneas
   - Distinguir remediación táctica (legacy) vs arquitectónica (target)
4. Salidas esperadas:
   - `assessment/{{ProjectName}}/seguridad-DDMMYYYY.md`
   - `assessment/{{ProjectName}}/seguridad-DDMMYYYY.html` (vía `./scripts/md2html.sh`)
5. Cierre: top 3 bloqueantes para Fase 1, top 3 categorías que se eliminan en Fase 4, lista de insumos pendientes.

## Reglas

- **Sin exploits.** Análisis estático puro.
- **Sin secretos reales** en el reporte: redactar con `***REDACTED***`.
- **Severidad justificada** (impacto + probabilidad), no copiar de OWASP sin contexto.
- **No sobreescribir** reportes anteriores: nueva fecha = nuevo archivo.
