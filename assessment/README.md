# assessment/

Outputs de **Fase 0** (todos los assessments previos a la decisión de modernizar).

> Esta carpeta antes se llamaba `business-case/`. Ahora consolida **todos** los reportes de Fase 0 (caso de negocio + seguridad + futuros: arquitectura legacy, calidad, regulatorio, etc.) en una sola estructura indexada por proyecto y fecha.

## Estructura

```
assessment/
├── _templates/                          Plantillas reusables
│   ├── tco-actual.template.md
│   ├── roi-modernizacion.template.md
│   ├── riesgo-no-hacer.template.md
│   ├── business-case-ejecutivo.template.md
│   └── seguridad.template.md
└── {ProjectName}/                       Una carpeta por proyecto (cliente)
    ├── tco-actual-DDMMYYYY.md
    ├── tco-actual-DDMMYYYY.html
    ├── roi-modernizacion-DDMMYYYY.md
    ├── roi-modernizacion-DDMMYYYY.html
    ├── riesgo-no-hacer-DDMMYYYY.md
    ├── riesgo-no-hacer-DDMMYYYY.html
    ├── business-case-ejecutivo-DDMMYYYY.md
    ├── business-case-ejecutivo-DDMMYYYY.html
    ├── seguridad-DDMMYYYY.md
    └── seguridad-DDMMYYYY.html
```

## Convención de nombres

`{categoria}-{DDMMYYYY}.{md|html}`

- **`{categoria}`**: identificador estable y kebab-case. Ej: `seguridad`, `tco-actual`, `roi-modernizacion`, `riesgo-no-hacer`, `business-case-ejecutivo`.
- **`{DDMMYYYY}`**: fecha UTC del día de generación. Ej. `08052026`.
- **No se sobreescribe.** Cada ejecución nueva del agente genera un archivo con la fecha actual; los anteriores quedan como histórico.

## Doble formato: `.md` + `.html`

- **`.md`**: fuente, editable, versionable.
- **`.html`**: gemelo autocontenido (CSS embebido). **Abre offline** en cualquier navegador, sin servidor ni dependencias. Pensado para compartir con sponsors/auditores que no usan Git ni Markdown.

Para regenerar el HTML después de editar el MD:

```bash
./scripts/md2html.sh assessment/MiProyecto/seguridad-08052026.md
```

Ver [`scripts/README.md`](../scripts/README.md) para detalles e instalación.

## Agentes que escriben aquí

| Agente | Categorías que produce |
| --- | --- |
| [`@business-case-analyst`](../.github/agents/shared/00-business-case.agent.md) | `tco-actual`, `roi-modernizacion`, `riesgo-no-hacer`, `business-case-ejecutivo` |
| [`@security-assessor`](../.github/agents/shared/02-security-assessor.agent.md) | `seguridad` |

## Agregar una nueva categoría

1. Copia un template de `_templates/` y renómbralo `<categoria>.template.md`.
2. Ajusta secciones al objetivo (compliance, calidad, accesibilidad, etc.).
3. Crea un agente en `.github/agents/shared/` que lo use, siguiendo el patrón de `02-security-assessor.agent.md`.
4. Documenta la categoría en la tabla de arriba.

## Reglas

- **No comitear secretos** que aparezcan en los reportes. Redactar (`***REDACTED***`) antes de versionar.
- **No sobreescribir** reportes anteriores: el histórico es evidencia.
- Mantener `.md` y `.html` **sincronizados** (regenerar HTML tras editar MD).
- Carpeta `{ProjectName}/` puede ir a `.gitignore` si el cliente exige confidencialidad estricta.
