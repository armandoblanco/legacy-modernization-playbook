# TODO — Pendientes de la plantilla

Este archivo lista lo que NO está incluido en la versión actual de la plantilla y debería completarse en iteraciones futuras. Está ordenado por prioridad de impacto.

> **Nota de reestructuración (multi-tecnología):** las rutas mencionadas abajo (`docs/02-lecciones.md`, `docs/04a-trampas-vb6.md`, `lab-01-assessment.md`, etc.) son las **anteriores** a la reorganización en `docs/methodology/`, `docs/shared/`, `docs/technologies/<tech>/` y `workshop/<tech>/`. La intención de cada pendiente sigue vigente; solo cambia la ubicación destino:
>
> - Lecciones VB.NET → `docs/technologies/vb/lecciones-vbnet.md`
> - Trampas VB6 / VB.NET → `docs/technologies/vb/trampas-{vb6,vbnet}.md`
> - Decision stack VB → `docs/technologies/vb/decision-stack-vb.md`
> - Anti-patrones → `docs/shared/anti-patrones.md`
> - Labs VB → `workshop/vb/lab-XX-*.md`
> - Labs compartidos (Fase 0 / Fase 4) → `workshop/shared/lab-{00,04}-*.md`
>
> Pendientes adicionales nuevos (multi-tech / cloud):
>
> - **P0** Poblar agentes y prompts reales para `dotnet-framework`, `cobol`, `java`, `python` (hoy son placeholders).
> - **P0** Validar `assessment/_templates/` con un caso real y publicar ejemplo lleno en `assessment/_examples/`.
> - **P1** Documentar 5 patrones equivalentes a los de Azure en `cloud-architectures/aws/` y `cloud-architectures/gcp/`.
> - **P1** Generar IaC de referencia (Bicep, Terraform-AWS, Terraform-GCP) en cada `cloud-architectures/<provider>/iac/`.
> - **P2** Lab 05 — pipeline CI/CD para deploy de la app modernizada al cloud elegido.

---

## P0 — Crítico para uso en producción

### 1. Lecciones específicas de migraciones VB.NET legacy

**Estado:** El documento `docs/02-lecciones.md` actual contiene 15 lecciones, todas de proyectos VB6. Las migraciones VB.NET legacy tienen lecciones distintas:

- `Option Strict Off` resuelto antes vs durante migración
- Migración de WebForms a Blazor — el mapping no es 1:1
- WCF servidor → CoreWCF vs ASP.NET Core (decisión arquitectónica grande)
- Manejo de `My.Settings` con persistencia mutable
- Mezcla de .NET Framework 4.x y .NET 8 con `Microsoft.Windows.Compatibility`
- Migración de `BackgroundWorker` a `async/await` con UI marshaling
- DataSet tipado migrado a EF Core: cuándo SÍ y cuándo NO

**Acción:** agregar sección "Lecciones VB.NET legacy" con 5-8 lecciones reales. Requiere proyectos referenciables.

### 2. Lab 02 (Planning) y Lab 03 (Migración)

**Estado:** solo `lab-01-assessment.md` existe.

**Por qué importa:** sin labs prácticos completos, el workshop no es entregable como material de capacitación. Es solo documentación.

**Acción:**
- `lab-02-planning.md` (~300 líneas): cómo invocar agente de planning, validar ADRs, manejo de OCX bloqueados con ejemplos
- `lab-03-migracion.md` (~400 líneas): bootstrapping, primer feature end-to-end, validación de paridad, manejo de bloqueos

---

## P1 — Importante para calidad

### 3. Sample legacy code para el lab

**Estado:** los labs piden "trae tu propio sistema VB" como input. No hay sistema de ejemplo provisto.

**Por qué importa:** sin código de muestra, los labs requieren que el participante traiga su propio sistema. Esto rara vez funciona en sesiones grupales.

**Acción:** crear repositorio aparte `vb-legacy-samples/` con:
- Mini sistema VB6 funcional (~3-5 KLOC, banca simple)
- Mini sistema VB.NET WinForms .NET FX 4.6.1 (~5 KLOC, gestión de tareas)
- Mini sistema VB.NET WebForms (~3 KLOC, catálogo de productos)
- Cada uno con `docs/features/` esperado para validar el output del agente

Es un proyecto separado, no incluirlo dentro del repo de la plantilla.

### 4. Validación end-to-end del bootstrap script

**Estado:** los scripts `bootstrap.sh` y `bootstrap.ps1` están escritos pero NO ejecutados contra un proyecto real.

**Acción:** ejecutar el script sobre un clone limpio, validar que:
- Todos los placeholders se reemplazan correctamente
- Los archivos eliminados son los correctos según las opciones elegidas
- `.copilot-project.yml` se genera bien
- No queda ningún `{{ProjectName}}` o similar en archivos finales

### 5. Nombres de agentes en VS Code

**Estado:** los nombres `@vb-assessment`, `@vb-planning`, `@vb-migration` que aparecen en el README son la mejor estimación de cómo VS Code va a normalizar el campo `name` del frontmatter de cada agente.

**Por qué importa:** si el nombre real difiere, los ejemplos del README quedan inválidos.

**Acción:** instalar la plantilla en un VS Code real con Copilot Chat habilitado, verificar nombres exactos, actualizar README si difieren.

### 6. Instructions específicas para VB.NET legacy → C#

**Estado:** los instructions actuales (`csharp-style.instructions.md`, `wpf-mvvm.instructions.md`, `winforms.instructions.md`, `blazor.instructions.md`) asumen migración desde VB6 a C# moderno.

**Por qué importa:** migrar VB.NET → C# tiene reglas distintas (eventos `Handles`, `Microsoft.VisualBasic.dll`, `My.Settings`, default properties).

**Acción:** crear `vbnet-to-csharp.instructions.md` con reglas específicas que aplican `applyTo: "src/**/*.cs"` cuando el `legacy_lang` es `vbnet`. Este es un gap real.

---

## P2 — Mejora la experiencia

### 7. Plantilla `dotnet new`

**Estado:** la plantilla se clona con `git clone`. Para uso más profesional, podría empaquetarse como template `dotnet new`:

```bash
dotnet new --install ModernizacionLegacyVB.Templates
dotnet new vb-migration -n MiProyecto -o ./mi-proyecto
```

**Acción:** agregar `.template.config/template.json` en root con definición. Publicar en NuGet.org. Tutorial específico para esto.

### 8. CI/CD inicial para `migrated/`

**Estado:** la plantilla no incluye ningún workflow de GitHub Actions para CI sobre la solución migrada.

**Acción:** agregar `.github/workflows/migrated-ci.yml` que:
- Compila la solución `migrated/*.Migrated.sln`
- Corre los tests
- Reporta coverage
- Falla si hay nuevos warnings en Domain/Application

### 9. Pre-commit hooks

**Estado:** no hay hooks configurados.

**Acción:** agregar configuración para `husky.NET` o `dotnet-format` que valide formato antes de commits en `migrated/`.

---

## P3 — Nice-to-have

### 10. Versión Claude Code (skills) paralela

**Estado:** la plantilla es solo Copilot Chat (agentes en `.github/agents/`).

**Acción:** crear estructura paralela `.claude/skills/` con skills equivalentes para Claude Code. Permite a equipos elegir herramienta sin cambiar metodología. Trabajo significativo: requiere reescribir cada agente como skill respetando las convenciones de Claude Code y validando que produce el mismo output.

### 11. Ejemplo de output esperado (golden samples)

**Estado:** sin ejemplos de cómo se ve un buen `docs/features/X.md`, un buen ADR, un buen migration-log.

**Acción:** crear `docs/_examples/` con muestras de cada artefacto. Sirve como referencia para validar que el agente produjo algo correcto.

### 12. Métricas reales validables

**Estado:** las métricas en el README son rangos defendibles según experiencia, pero no están atadas a proyectos referenciables públicamente.

**Acción:** anonimizar 3-5 proyectos reales y crear `docs/case-studies/` con métricas comparables. Esto requiere autorización del cliente o anonimización completa.

### 13. Soporte para VB Classic (anterior a VB6)

**Estado:** alcance es VB6 + VB.NET. VB1 a VB5 no están cubiertos.

**Razón de exclusión:** son lo suficientemente raros en LATAM 2026 que no justifican el trabajo. Si aparece un cliente con VB5, la mayoría de heurísticas de VB6 aplican.

---

## Decisiones de diseño NO pendientes

Para honestidad: estas decisiones se tomaron deliberadamente y NO son TODOs:

- **No se usa `dotnet new` template aún:** porque la mayoría de equipos LATAM están más cómodos con `git clone` que con `dotnet new --install`. Si esto cambia, ver P2.7.
- **No se incluye Visual Studio (no Code) workflow:** los agentes Copilot Chat funcionan en ambos pero la documentación asume VS Code. Si un cliente usa Visual Studio, los agentes funcionan igual; los menús son distintos.
- **No se cubre Mobilize.NET, VBUC, ni otras herramientas comerciales:** la plantilla complementa, no compite. Si el cliente quiere herramienta comercial, debe usar la documentación de esa herramienta.
- **No se cubre migración de VB.NET .NET 6/7 a .NET 8:** eso es upgrade trivial con `.NET Upgrade Assistant`, no requiere esta plantilla.

---

## Versión actual

| Archivo | Líneas | Estado |
| --- | --- | --- |
| README.md (ES) | ~170 | ✅ Completo |
| README.en.md | ~120 | ✅ Completo |
| bootstrap.sh | ~150 | ⚠️ No validado en producción |
| bootstrap.ps1 | ~140 | ⚠️ No validado en producción |
| docs/01-metodologia.md | ~240 | ✅ Completo |
| docs/02-lecciones.md | ~325 | ⚠️ Solo VB6, falta VB.NET (ver P0.1) |
| docs/03-decision-stack.md | ~245 | ✅ Completo |
| docs/04a-trampas-vb6.md | ~560 | ✅ Completo |
| docs/04b-trampas-vbnet.md | ~640 | ✅ Completo |
| docs/05-anti-patrones.md | ~365 | ✅ Aplicable a ambos lenguajes |
| .github/agents/01-vb-assessment.agent.md | ~340 | ✅ Multi-lenguaje |
| .github/agents/02-vb-planning.agent.md | ~390 | ✅ Multi-lenguaje + multi-stack |
| .github/agents/03-vb-migration.agent.md | ~575 | ✅ Multi-lenguaje + multi-stack |
| .github/prompts/*.prompt.md | 4 archivos | ✅ Aplicables |
| .github/instructions/csharp-style.instructions.md | ~178 | ✅ |
| .github/instructions/wpf-mvvm.instructions.md | ~245 | ✅ |
| .github/instructions/winforms.instructions.md | ~290 | ✅ Nuevo |
| .github/instructions/blazor.instructions.md | ~340 | ✅ Nuevo |
| workshop/lab-01-assessment.md | ~350 | ✅ Solo Lab 01 (P0.2) |

**Total:** ~5,500 líneas de contenido sustancial.

---

## Próximos pasos sugeridos

En orden de impacto sobre la calidad de la plantilla:

1. **Validar bootstrap scripts** en VS Code real con un proyecto VB6 chico (acción rápida, antes de cualquier otra cosa)
2. **Lab 02 + Lab 03** para completar el workshop como material de capacitación
3. **Lecciones VB.NET legacy** (P0.1) con 5-8 casos reales referenciables
4. **Sample legacy code** (P1.3) para que los labs sean ejecutables sin código del cliente — proyecto separado, no incluir dentro de esta plantilla
5. **Instructions VB.NET → C#** (P1.6) específicas para reglas que difieren de migración VB6 → C#

Con esos 5 pasos, la plantilla pasa de "buena base" a "producto entregable a clientes y comunidad".
