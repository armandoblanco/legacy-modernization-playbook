---
description: Diseña la arquitectura cloud target (Fase 4) generando ADRs por cada decisión, diagrama Mermaid y esqueleto de IaC para el proveedor elegido.
---

# Diseñar arquitectura cloud target (Fase 4)

Para **{{ProjectName}}**, hospedado en **{{CloudProvider}}**:

1. Lee el `business-case-ejecutivo-DDMMYYYY.md` más reciente en `assessment/{{ProjectName}}/` (presupuesto OPEX) y los ADRs existentes en `docs/adr/`.
2. Identifica 2-3 patrones candidatos de `cloud-architectures/{{CloudProvider}}/`.
3. Pregunta restricciones no funcionales (SLA, RTO/RPO, tráfico, soberanía, equipo de operación).
4. Genera tabla comparativa (costo, complejidad operativa, tiempo de implementación, riesgos) y recomienda **uno**.
5. Genera ADRs en `docs/adr/` (uno por cada una de las 12 decisiones de Fase 4).
6. Incluye diagrama Mermaid en el ADR principal.
7. Genera esqueleto de IaC en `infra/` con módulos por bloque (network, identity, compute, data, observability).
8. Estima costos mensuales con desglose y compara contra OPEX del business case.
9. Lista próximos pasos: validar con FinOps, primer deploy en dev, configurar pipeline.

## Reglas

- No "Kubernetes por moda". Justificar contra alternativas más simples.
- IaC versionado desde día 0.
- Identidad federada (Managed Identity / Workload Identity / OIDC) preferida sobre credenciales locales.
- Secretos siempre en Key Vault / Secrets Manager / Parameter Store.
- Observabilidad antes de producción (logs + métricas + traces + alertas).
