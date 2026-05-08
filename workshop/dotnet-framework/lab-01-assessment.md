# Lab 01 — Assessment de un sistema .NET Framework legacy

## Caso ficticio: **MvcMovieFx48** (back-office bancario)

> Sistema de gestión de pólizas y reportes regulatorios de un banco mediano LATAM, en producción desde 2011.

### Datos del sistema
- **Solución:** `MvcMovieFx48.sln` con 17 proyectos.
- **Stack legacy:**
  - 4 librerías de dominio en `net472` (legacy `<Project ToolsVersion="15.0">`)
  - 2 librerías compartidas en `net48`
  - 1 ASP.NET MVC 5 (`net48`, EF6, Forms Authentication)
  - 1 ASP.NET WebForms (`net48`, reportes con `<asp:GridView>`)
  - 2 servicios WCF auto-hosted (`net472`, NetTcpBinding)
  - 1 WinService de batch (`net472`, MSMQ, log4net, Quartz.NET)
  - 6 proyectos de tests xUnit (`net472`)
- **Paquetes notables:** EntityFramework 6.4, Newtonsoft.Json 11, log4net 2.0.8, Unity 5.11, Microsoft.Owin 3.1, ServiceStack.Redis 4.x, Crystal Reports runtime, COM Interop con OCX de firma digital.
- **Datos:** SQL Server 2014 (on-prem) con 320 tablas, 180 stored procedures.
- **Auth:** Forms Authentication contra tabla local + LDAP corporativo vía OWIN.
- **Despliegue:** IIS 8.5 en Windows Server 2012 R2, MSI clásico, sin CI/CD.
- **Tests:** ~22% cobertura, mayormente en libs de dominio.

### Restricciones de negocio
- **24/7** durante semanas hábiles, ventana de mantenimiento sábado 02:00-05:00.
- Auditor regulatorio audita firma digital con OCX específico — no se puede romper.
- Equipo: 4 devs (3 senior .NET, 1 junior), 1 QA, sin DevOps dedicado.
- Presupuesto: 9 meses, sin extensión.

---

## Objetivos del lab

Como participante, vas a:

1. **Invocar `@dotnet-assessment`** apuntando al árbol `legacy/` con el código del sistema MvcMovieFx48.
2. **Verificar** que se generen los siguientes outputs:
   - `docs/SUMMARY.md` con métricas (proyectos, líneas, paquetes, bloqueantes).
   - `docs/inventory/projects.md` con tabla clasificatoria (crítico/corto/migrable/multi-target).
   - `docs/inventory/packages.md` con mapping a reemplazos.
   - `docs/inventory/dependency-graph.md` (Mermaid).
   - `docs/inventory/runtime-surface.md` con BinaryFormatter, WCF servidor, EF6, OWIN, MSMQ, COM Interop, Crystal Reports.
   - `docs/features/<feature>.md` por cada feature de negocio detectada (esperado: 8-15 features).
   - `docs/frontend/README.md` cubriendo MVC + WebForms.
   - `docs/cross-cuttings/README.md` con log4net, Unity, Forms Auth, ConfigurationManager, Newtonsoft.

3. **Validar coverage 100%** — el agente debe haber leído **todos** los archivos `.cs` del proyecto.

4. **Identificar bloqueantes top 5** y discutir en grupo:
   - Crystal Reports (no soporta .NET 8 nativamente)
   - OCX de firma digital (COM Interop, x86)
   - WCF servidor con NetTcpBinding (CoreWCF lo soporta, pero el cliente legacy debe seguir conectando)
   - WebForms (sin migración directa)
   - Unity (deprecado, sin equivalente 1:1)

5. **Plantear preguntas para Fase 2** (`@dotnet-planning`):
   - ¿Mantenemos Crystal Reports en un proceso net48 separado o reemplazamos por QuestPDF / Telerik?
   - ¿Aislamos OCX en un proceso "shim" net48 invocado vía gRPC?
   - ¿WebForms → Blazor Server (recomendación conservadora) o Razor Pages?
   - ¿Multi-target net48+net8.0 en libs compartidas o all-at-once?

---

## Pasos guiados

### Paso 1 — Bootstrap
```bash
./bootstrap.sh
# ProjectName: MvcMovieFx48
# ClientName: BancoEjemplo
# LegacyTech: dotnet-framework
# LegacyLang: csharp
# TargetStack: dotnet8
# CloudProvider: azure
```

### Paso 2 — Coloca el legacy
Copia el código fuente legacy en `legacy/` (read-only). Estructura sugerida:
```
legacy/
├── MvcMovieFx48.sln
├── src/
│   ├── Domain/...
│   ├── Application/...
│   ├── Web.Mvc/...
│   ├── Web.Forms/...
│   ├── Services.Wcf/...
│   └── Worker.Batch/...
└── tests/
```

### Paso 3 — Fase 0 (opcional pero recomendado)
```text
@business-case-analyst Construye el business case para BancoEjemplo MvcMovieFx48
@security-assessor Analiza el código en legacy/ y produce el assessment de seguridad
```

### Paso 4 — Fase 1 (este lab)
```text
@dotnet-assessment Analiza el sistema legacy/ MvcMovieFx48 y genera el assessment completo en docs/
```

### Paso 5 — Verificación

Checklist:

- [ ] `docs/SUMMARY.md` existe y muestra métricas.
- [ ] `docs/README.md` existe (índice maestro).
- [ ] Los 4 archivos en `docs/inventory/` existen.
- [ ] Hay al menos 8 archivos en `docs/features/`.
- [ ] `docs/frontend/README.md` distingue MVC y WebForms con detalle.
- [ ] `docs/cross-cuttings/README.md` lista logging, DI, auth, config, errors.
- [ ] La métrica `files_analyzed/total` es **1.0**.
- [ ] El agente terminó preguntando "¿revisamos hallazgos antes de pasar a Fase 2?".

### Paso 6 — Discusión
- ¿Qué clasificación dio el agente a las libs `net472` legacy?
- ¿Detectó concatenación SQL en algún feature? ¿Lo cruzó con SEC del security assessment?
- ¿Cómo agrupó las features? ¿Coincide con tu modelo mental del sistema?
- ¿Qué le falta al output que sería útil para `@dotnet-planning`?

---

## Entregable

PR (o carpeta) con:
- `docs/` completo
- Lista de top 5 bloqueantes con evidencia (path:line)
- 3 preguntas abiertas para Fase 2

## Tiempo estimado
3-4 horas.

## Siguiente lab
`workshop/dotnet-framework/lab-02-planning.md` (pendiente — usa `@dotnet-planning` con los outputs de este lab).
