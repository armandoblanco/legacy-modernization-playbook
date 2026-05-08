# Lab 4 — Diseñar arquitectura cloud

> Lab introductorio que recorre la **Fase 4** sobre el caso ficticio del Lab 0.

## Objetivo

Practicar el diseño de arquitectura cloud usando `@cloud-architect` para el sistema modernizado.

## Pre-requisitos

- Completado [Lab 0 — Business Case](lab-00-business-case.md)
- Completado el lab de assessment correspondiente a la tecnología elegida

## Pasos

1. Invoca:
   ```
   @cloud-architect Diseña la arquitectura cloud para SISCobranzas en {{CloudProvider}}
   ```
2. Responde restricciones: SLA 99.9, RTO 4h, RPO 1h, 100 usuarios pico, equipo de 3 personas, no hay equipo plataforma dedicado.
3. Revisa los ADRs generados en `docs/adr/` y el esqueleto de `infra/`.
4. Compara contra rúbrica.

## Rúbrica

- [ ] Se evaluaron al menos 2 patrones (no solo el "más moderno")
- [ ] Se eligió un patrón **proporcional** al equipo (probablemente PaaS / Container Apps, no AKS)
- [ ] Hay ADR por cada una de las 12 decisiones de Fase 4
- [ ] Diagrama Mermaid en el ADR principal
- [ ] Estimación de costo mensual con desglose
- [ ] Esqueleto de IaC compila sin errores
- [ ] Identidad federada (sin secretos hardcoded)
- [ ] Observabilidad configurada antes de "go live"

## Anti-patrones a evitar en este lab

- Elegir AKS para 100 usuarios y equipo de 3 personas
- Microservicios "porque sí"
- IaC parcial (solo network, el resto a mano)
- Sin estimación de costo o sin compararla con el OPEX del business case
