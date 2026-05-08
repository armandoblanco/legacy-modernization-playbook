# Cloud Architectures — Fase 4

Esta carpeta contiene **placeholders y plantillas** para diseñar la arquitectura cloud target del sistema modernizado. Es la **Fase 4** de la metodología.

Ver [`docs/methodology/05-cloud-deployment.md`](../docs/methodology/05-cloud-deployment.md) para la guía metodológica completa.

---

## Estructura

```
cloud-architectures/
├── README.md                                    (este archivo)
├── azure/
│   ├── 01-iaas-lift-and-shift.md
│   ├── 02-paas-app-service.md
│   ├── 03-containers-aks.md
│   ├── 04-serverless-functions.md
│   └── 05-microservices-event-driven.md
├── aws/                                         (placeholder)
├── gcp/                                         (placeholder)
├── on-premise/                                  (placeholder, para casos híbridos / no-cloud)
└── _templates/
    └── architecture-decision.template.md
```

Cada archivo describe **un patrón** de arquitectura aplicable a la modernización: cuándo elegirlo, cuándo NO, componentes típicos, IaC sugerido, costos aproximados, observabilidad y riesgos.

---

## Cómo elegir

1. Leer [`docs/methodology/05-cloud-deployment.md`](../docs/methodology/05-cloud-deployment.md) para principios y las "6 R" de migración.
2. Revisar 2-3 patrones candidatos del proveedor elegido.
3. Para cada candidato, completar plantilla `_templates/architecture-decision.template.md` con tradeoffs, costos y supuestos del cliente.
4. Generar ADR formal en `docs/adr/` con la decisión elegida y justificación.
5. Materializar la decisión en IaC (Bicep / Terraform / Pulumi / CloudFormation) en el repo del cliente.

---

## Agente Copilot recomendado

[`@cloud-architect`](../.github/agents/shared/04-cloud-architect.agent.md) — toma el output de Fases 1-3 y el business case, propone arquitecturas candidatas, genera ADRs y esqueleto de IaC.

---

## Proveedores

| Proveedor | Estado |
| --- | --- |
| Azure | Placeholders por patrón |
| AWS | Placeholder único, pendiente espejar patrones |
| GCP | Placeholder único, pendiente espejar patrones |
| On-premise / híbrido | Placeholder, para casos donde regulación obliga |
