# Fase 4 — Cloud Deployment (arquitectura cloud target)

> **Objetivo:** definir e implementar **dónde corre** el sistema modernizado, bajo qué arquitectura cloud, y con qué características no funcionales (costo, escalabilidad, disponibilidad, seguridad).

Esta fase ocurre **después de** o **en paralelo con** la última parte de Fase 3. Saltarla o atrasarla genera el peor de los mundos: una app moderna corriendo en un servidor on-premise viejo, sin observabilidad, sin elasticidad, sin las ventajas que justificaron el ROI del business case.

---

## Filosofía

La modernización de código y la modernización de hosting son **dos proyectos distintos** que se confunden. El código moderno necesita una arquitectura cloud que lo aproveche; el hosting moderno necesita un código que sepa correr en él (12-factor, stateless, observabilidad, configuración externalizada).

Esta fase decide:

1. **Modelo de servicio:** IaaS, PaaS, CaaS, FaaS, SaaS
2. **Proveedor:** Azure, AWS, GCP, on-premise, multi-cloud, híbrido
3. **Patrón arquitectónico cloud:** monolito en VM, monolito en App Service, microservicios, event-driven, serverless
4. **Topología:** región(es), zonas, redundancia, DR
5. **Cross-cuttings cloud:** identidad (Entra, Cognito, IAM), observabilidad, secretos, networking, costos

---

## Entradas

- Output completo de Fases 0, 1, 2 y 3
- Restricciones del cliente: nube preferida, contratos existentes, requisitos de soberanía de datos
- Requisitos no funcionales: SLA, RTO/RPO, tráfico esperado, picos
- Presupuesto operativo (OPEX) anual previsto en el business case

---

## Entregables

```
cloud-architectures/
├── <provider>/                              Decisión de arquitectura por proveedor
│   ├── 01-iaas-lift-and-shift.md
│   ├── 02-paas-app-service.md
│   ├── 03-containers-aks.md
│   ├── 04-serverless-functions.md
│   └── 05-microservices-event-driven.md
└── _templates/
    └── architecture-decision.template.md

infra/                                       Infrastructure as Code (en repo cliente)
├── bicep/  o  terraform/  o  pulumi/
└── pipelines/
```

Más:
- ADR de elección de arquitectura cloud (en `docs/adr/`)
- Diagrama de arquitectura (Mermaid o draw.io)
- Estimación de costos cloud mensual (Azure Pricing Calculator, AWS Calculator)
- Plan de despliegue (blue-green, canary, rolling) y rollback

---

## Las 6 R de migración cloud (Gartner)

Se aplican por aplicación o por componente, no al portfolio completo:

| R | Estrategia | Cuándo |
| --- | --- | --- |
| **Rehost** | Lift and shift a IaaS | Tiempo crítico, sin presupuesto para refactor |
| **Replatform** | Cambios mínimos para PaaS (ej. App Service, RDS) | Quick wins de operación sin reescribir |
| **Refactor** | Reescribir para nube (microservicios, serverless) | Caso del repo: hicimos modernización en Fase 3 |
| **Repurchase** | Reemplazar por SaaS | El módulo es commodity (CRM, ERP, mail) |
| **Retire** | Apagar | El módulo ya no aporta valor |
| **Retain** | Dejar on-premise | Restricción regulatoria, costo de migrar > beneficio |

La metodología de este repo cubre principalmente **Refactor**, pero la Fase 4 puede recomendar combinaciones (ej. refactor del core + repurchase de módulos commodity).

---

## Patrones de arquitectura cloud cubiertos

Cada uno tiene su placeholder en [`cloud-architectures/azure/`](../../cloud-architectures/azure/) (con espejos pendientes para AWS y GCP):

1. **Lift-and-shift IaaS** — VMs, mínimo cambio, máximo costo operativo
2. **PaaS managed** — App Service / Container Apps / RDS — buen punto medio
3. **Containers + orquestador** — AKS / EKS / GKE — control total, complejidad alta
4. **Serverless / FaaS** — Functions / Lambda / Cloud Functions — pago por uso
5. **Microservicios event-driven** — Service Bus / EventHub / Kafka — escala extrema, complejidad alta
6. **Híbrido / multi-cloud** — combinación con conectividad (ExpressRoute, DirectConnect)

Para cada patrón, el placeholder incluye: cuándo elegirlo, cuándo NO, componentes típicos, costos aproximados, observabilidad, IaC sugerido.

---

## Decisiones que deben tomarse en esta fase

1. **Proveedor cloud principal** y razón (contratos, certificaciones, presencia regional)
2. **Modelo de servicio dominante** (IaaS / PaaS / CaaS / FaaS) por componente
3. **Región(es) primaria(s) y secundaria(s)** y estrategia de DR
4. **Identidad y acceso:** federación con AD on-prem, Entra ID, IAM, MFA
5. **Networking:** VNet/VPC, peering, private endpoints, egreso, WAF
6. **Datos:** BD gestionada vs auto-administrada, backup, replicación, residencia
7. **Secretos y configuración:** Key Vault / Secrets Manager / Parameter Store
8. **Observabilidad:** logs, métricas, traces, alertas, dashboards
9. **CI/CD:** pipelines, ambientes (dev/qa/uat/prod), aprobaciones
10. **Costos:** budgets, alertas, FinOps, tagging, reservas/savings plans
11. **Seguridad:** Defender / GuardDuty / Security Command Center, hardening, compliance
12. **IaC:** Bicep / Terraform / Pulumi / CloudFormation — uno solo, documentado en ADR

---

## Criterios de salida

1. Existe un ADR por cada decisión de la lista de arriba
2. La arquitectura cloud está dibujada y revisada con el cliente
3. La estimación de costos mensual está validada con FinOps del cliente
4. IaC está versionado en repo y se puede desplegar end-to-end en dev
5. Existe un runbook de despliegue y rollback
6. Existe baseline de observabilidad (al menos: logs centralizados, métricas básicas, alertas críticas)

---

## Anti-patrón clásico

> "Vamos a Kubernetes porque es el estándar moderno."

Kubernetes es la respuesta correcta para una minoría de casos. Para una app monolítica que no escala más allá de 2-3 instancias y la opera un equipo de 4 personas, App Service / Container Apps / Lambda es muchísimo más barato y operable. Elegir K8s "por moda" mata el ROI calculado en Fase 0.

Otras versiones del mismo anti-patrón:
- "Microservicios desde el día 1"
- "Multi-cloud por si acaso"
- "Serverless para todo"
- "Event-driven para todo"

Cada uno tiene su nicho. Ninguno es default.

---

## Agente de Copilot recomendado

[`@cloud-architect`](../../.github/agents/shared/04-cloud-architect.agent.md) — toma el output de Fase 2 y 3, propone 2-3 arquitecturas candidatas con trade-offs, genera ADRs y esqueleto de IaC.

---

## Referencias externas

- AWS Well-Architected Framework, Azure Well-Architected Framework, Google Cloud Architecture Framework
- Gartner 6 R's of Cloud Migration
- 12-Factor App methodology
- CNCF Cloud Native Trail Map
