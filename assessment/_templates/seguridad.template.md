# Assessment de Seguridad — {{ProjectName}}

> Categoría: `seguridad` · Fase 0 · Fecha: `{{DDMMYYYY}}`
> Auditor: `@security-assessor` (Copilot agent · whitehat / pentester)
> Alcance revisado: `legacy/` (snapshot al {{DDMMYYYY}})
> Cliente: {{ClientName}}
>
> **Disclaimer:** revisión estática asistida por IA sobre el código y configuraciones del repo. **No sustituye** una auditoría profesional ni un pentest dinámico. Las conclusiones deben validarse antes de tomar decisiones contractuales o regulatorias.

---

## 1. Resumen ejecutivo

- **Veredicto general:** {{Crítico / Alto / Medio / Bajo}} riesgo agregado
- **Hallazgos críticos:** {{N}}
- **Hallazgos altos:** {{N}}
- **Hallazgos medios:** {{N}}
- **Hallazgos bajos / informativos:** {{N}}
- **Top 3 riesgos a remediar antes de modernizar:**
  1. {{...}}
  2. {{...}}
  3. {{...}}
- **Riesgos a heredar / re-arquitecturar en Fase 4:** {{...}}

## 2. Alcance

| Item | Detalle |
| --- | --- |
| Tecnología legacy | {{LegacyTech}} {{LegacyLang}} |
| Líneas de código analizadas | {{KLOC}} |
| Archivos analizados | {{N}} |
| Componentes externos / OCX / DLL / JAR | {{N}} |
| Cadenas de conexión halladas | {{N}} |
| Endpoints expuestos | {{N}} |
| Bases de datos referenciadas | {{lista}} |
| Excluido del alcance | {{infra runtime, red, AD, etc.}} |

## 3. Metodología

Mapping de hallazgos contra:

- **OWASP Top 10 (2021)**
- **OWASP ASVS L1/L2** (controles aplicables a app legacy)
- **CWE Top 25**
- **MITRE ATT&CK** (técnicas relevantes a la superficie)
- **{{Marco regulatorio aplicable: PCI-DSS / HIPAA / GDPR / SOX / Ley local}}**

Técnicas usadas (estáticas):

- Búsqueda dirigida de patrones inseguros (regex + lectura contextual)
- Modelado STRIDE sobre flujos identificados
- Revisión de manejo de secretos, sesión, autenticación y autorización
- Análisis de dependencias y versiones (CVE conocidos)
- Revisión de logs / trazas / mensajes de error que filtren información

## 4. Modelo de amenazas (STRIDE)

| Activo | Spoofing | Tampering | Repudio | Info disclosure | DoS | Elevación |
| --- | --- | --- | --- | --- | --- | --- |
| Login / sesión | {{...}} | | | | | |
| BD / datos en reposo | | {{...}} | | | | |
| API / endpoint X | | | | {{...}} | | |
| Componente OCX | | | | | | {{...}} |

## 5. Hallazgos detallados

> Un bloque por hallazgo. Numerar `SEC-001`, `SEC-002`, ...

### SEC-001 — {{Título corto}}

- **Severidad:** Crítico / Alto / Medio / Bajo / Informativo
- **CWE:** CWE-{{...}}
- **OWASP:** A0{{N}}:2021 — {{Categoría}}
- **Ubicación:** `legacy/path/to/file.ext:LINE`
- **Descripción:** {{qué es y por qué es vulnerable}}
- **Evidencia (snippet):**
  ```{{lang}}
  {{línea exacta del código sin redactar al equipo, redactada en HTML público}}
  ```
- **Impacto:** {{exfiltración / RCE / pérdida de integridad / etc.}}
- **Reproducción / explotabilidad:** {{pasos teóricos o PoC. Si requiere acceso interno, dilo}}
- **Probabilidad:** Alta / Media / Baja (con justificación)
- **Riesgo agregado (impacto × probabilidad):** Crítico / Alto / Medio / Bajo
- **Remediación inmediata (parche en legacy):** {{qué cambiar línea por línea}}
- **Remediación arquitectónica (en target moderno):** {{cómo eliminar la categoría}}
- **Estado:** Abierto / En revisión / Mitigado / Aceptado (con justificación firmada)

### SEC-002 — ...

## 6. Hallazgos por categoría

### 6.1 Autenticación y gestión de sesión
{{...}}

### 6.2 Autorización y control de acceso
{{...}}

### 6.3 Manejo de secretos
- Cadenas de conexión hardcoded: {{N}}
- API keys en código: {{N}}
- Certificados / claves privadas en repo: {{N}}
- Secretos en logs / mensajes de error: {{N}}

### 6.4 Inyección
- SQL injection: {{N hallazgos}}
- Command injection: {{N}}
- LDAP / XPath / NoSQL: {{N}}

### 6.5 Criptografía
- Algoritmos débiles (MD5, SHA-1, DES, RC4): {{N}}
- Modos inseguros (ECB, IV estático): {{N}}
- TLS < 1.2 forzado: {{sí/no}}
- Aleatoriedad insegura (Rnd, Random): {{N}}

### 6.6 Validación y sanitización
- Concatenación directa de input → query / shell / HTML: {{N}}
- XSS reflejado / almacenado: {{N}}
- Path traversal: {{N}}
- Deserialización insegura: {{N}}

### 6.7 Manejo de errores y logging
- Stack traces expuestos al usuario: {{N}}
- PII en logs: {{N}}
- Falta de logging en eventos de seguridad: {{N}}

### 6.8 Componentes y dependencias
- Componentes EOL sin soporte: {{lista}}
- CVE conocidos en versiones usadas: {{tabla con CVE-ID, score, componente}}
- OCX / COM no firmados o de fuentes dudosas: {{N}}

### 6.9 Configuración
- `web.config` / `app.config` con `debug=true`: {{sí/no}}
- Cookies sin `HttpOnly` / `Secure` / `SameSite`: {{N}}
- CORS abierto (`*`): {{N}}
- Headers de seguridad faltantes (CSP, HSTS, X-Frame-Options): {{lista}}

### 6.10 Datos sensibles
- PII en BD sin cifrado en reposo: {{tablas/columnas}}
- Datos de tarjetas / salud / biométricos: {{...}}
- Backups con datos productivos: {{...}}

## 7. Cumplimiento regulatorio

| Marco | Control | Estado | Hallazgo asociado |
| --- | --- | --- | --- |
| {{PCI-DSS / HIPAA / etc.}} | {{Req X.Y}} | Cumple / Parcial / No cumple | SEC-### |

## 8. Quick wins (parche rápido en legacy antes de migrar)

| # | Hallazgo | Esfuerzo | Riesgo de aplicar | Owner |
| --- | --- | --- | --- | --- |
| 1 | SEC-### | XS / S / M | Bajo | {{equipo}} |

## 9. Recomendaciones para Fase 1-4

- **Fase 1 (Assessment funcional):** marcar features que tocan superficie crítica (SEC-001, SEC-007) para revisión humana adicional.
- **Fase 2 (Planning):** generar ADRs para cada decisión arquitectónica que **elimine** una categoría entera (auth centralizada, secret manager, ORM parametrizado).
- **Fase 3 (Execution):** controles a inyectar en CI:
  - SAST: {{herramienta}}
  - SCA: {{herramienta}}
  - Secret scanning: {{herramienta}}
  - DAST en staging: {{herramienta}}
- **Fase 4 (Cloud):** controles de plataforma a configurar:
  - Identidad: managed identity / federada, MFA admin, RBAC mínimo
  - Red: private endpoints, WAF, egress controlado
  - Datos: cifrado en reposo + tránsito, KMS gestionado, backups inmutables
  - Observabilidad: SIEM, alertas de anomalía, retención mínima 90 días

## 10. Insumos pendientes

- {{Acceso a runtime para validar config real}}
- {{Lista de cuentas de servicio y roles}}
- {{Confirmación de marco regulatorio aplicable}}

## 11. Anexos

- A. Tabla completa CVE de dependencias
- B. Inventario de cadenas de conexión halladas (anonimizado)
- C. Diagrama de superficie de ataque
- D. Snapshot de comandos / búsquedas usados durante el análisis
