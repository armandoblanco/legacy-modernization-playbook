---
description: Migra un proyecto .csproj o feature específica del legacy a .NET 8/9 siguiendo el plan
mode: agent
---

# Migrar proyecto / feature .NET

Ejecuta la migración del proyecto o feature indicada por el usuario, siguiendo `migration/{scenarioId}/plan.md` y los ADRs.

## Pre-requisitos
- `migration/{scenarioId}/scenario-instructions.md` existe (Fase 2 completada).
- `docs/ARQUITECTURA-TARGET.md` existe.
- El proyecto está en el plan en orden migrable (sus deps ya están migradas si bottom-up).

## Pasos

1. **Identifica** la TASK correspondiente en `migration/{scenarioId}/tasks.md`. Si no existe, créala.
2. **Crea branch** `migrate/<proyecto>-to-net8` (a menos que `scenario-instructions.md` diga otra convención).
3. **Convierte a SDK-style** (si aplica) preservando TFM actual primero.
4. **Migra packages.config** → `PackageReference` (con CPM si está habilitado).
5. **Verify:** `dotnet restore` + `dotnet build` con TFM original.
6. **Cambia TargetFramework** a `net8.0` (o multi-target `net48;net8.0` si el plan lo dice).
7. **Resuelve incompatibilidades** uno por uno:
   - Reemplaza APIs no portables según `csharp-modern.instructions.md`.
   - Aplica patrones del agente `@dotnet-migration` (BinaryFormatter, ConfigurationManager, EF6, WCF, etc.).
8. **Verify:** `dotnet build -c Release`.
9. **Verify:** `dotnet test` (todos los tests pasan).
10. **Verify:** `dotnet format --verify-no-changes`.
11. **Commit** según `commit-strategy` del scenario.
12. **Actualiza** `tasks.md` marcando `[✓]` con timestamp.

## Si algo falla
- Diagnostica máximo 2 intentos.
- Si no se resuelve, **revierte cambios locales** y reporta al usuario con:
  - Qué falló
  - Qué intentaste
  - Hipótesis de causa
  - Opciones para desbloquear (¿ADR adicional? ¿saltar este proyecto temporalmente?)

## No hagas
- No tomes decisiones arquitectónicas que no estén en ADRs.
- No cambies comportamiento funcional ("ya que estoy lo mejoro").
- No commitees código que no compila.
- No saltes tests aunque "obviamente funciona".
