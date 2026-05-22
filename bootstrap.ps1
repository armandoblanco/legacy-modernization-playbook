# Script de bootstrapping (PowerShell) equivalente a bootstrap.sh
# Reemplaza placeholders, copia los agentes relevantes a .github/agents/ flat (requisito de Copilot)
# y genera NEXT-STEPS.md con la guía completa de uso post-bootstrap.
#
# Uso:
#   .\bootstrap.ps1
#
# El script NO se autoelimina: puedes re-ejecutarlo para cambiar tech/stack/cloud.

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

function Write-Info { param($Msg) Write-Host "[info] $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "[warn] $Msg" -ForegroundColor Yellow }
function Write-Err  { param($Msg) Write-Host "[error] $Msg" -ForegroundColor Red }
function Write-Step { param($Msg) Write-Host "[paso] $Msg" -ForegroundColor Blue }

if (-not (Test-Path "README.md") -or -not (Test-Path ".github\agents")) {
    Write-Err "Este script debe ejecutarse desde la raíz del repo de la plantilla."
    exit 1
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Bootstrap de Legacy Modernization Playbook" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# === Recolección de valores ===

$ProjectName = Read-Host "Nombre del proyecto (PascalCase, ej: SgapVc)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { Write-Err "Obligatorio."; exit 1 }

$ClientName = Read-Host "Nombre del cliente (ej: BCCR, CFE, Banco Atlas)"
if ([string]::IsNullOrWhiteSpace($ClientName)) { Write-Err "Obligatorio."; exit 1 }

Write-Host ""
Write-Host "Tecnología legacy:"
Write-Host "  1) vb                (Visual Basic 6 / VB.NET legacy)"
Write-Host "  2) dotnet-framework  (.NET Framework 2.0 - 4.8)"
Write-Host "  3) cobol             (placeholder)"
Write-Host "  4) java              (placeholder)"
Write-Host "  5) python            (placeholder)"
Write-Host "  6) other             (placeholder genérico)"
$TechOpt = Read-Host "Elige [1-6]"
$LegacyTech = switch ($TechOpt) {
    "1" { "vb" }
    "2" { "dotnet-framework" }
    "3" { "cobol" }
    "4" { "java" }
    "5" { "python" }
    "6" { "other" }
    default { Write-Err "Opción inválida"; exit 1 }
}

$LegacyLang = ""
$TargetStack = ""
if ($LegacyTech -eq "vb") {
    Write-Host ""
    Write-Host "Sub-lenguaje VB:"
    Write-Host "  1) vb6     (Visual Basic 6, código .frm/.bas/.cls)"
    Write-Host "  2) vbnet   (VB.NET legacy, .NET Framework 1.1 a 4.8)"
    $LangOpt = Read-Host "Elige [1-2]"
    $LegacyLang = switch ($LangOpt) {
        "1" { "vb6" }
        "2" { "vbnet" }
        default { Write-Err "Opción inválida"; exit 1 }
    }

    Write-Host ""
    Write-Host "Stack target:"
    Write-Host "  1) winforms  (.NET 8 desktop conservador)"
    Write-Host "  2) wpf       (.NET 8 desktop con MVVM)"
    Write-Host "  3) blazor    (Blazor Server / ASP.NET Core)"
    $StackOpt = Read-Host "Elige [1-3]"
    $TargetStack = switch ($StackOpt) {
        "1" { "winforms" }
        "2" { "wpf" }
        "3" { "blazor" }
        default { Write-Err "Opción inválida"; exit 1 }
    }
}

Write-Host ""
Write-Host "Proveedor cloud objetivo (Fase 6):"
Write-Host "  1) azure"
Write-Host "  2) aws"
Write-Host "  3) gcp"
Write-Host "  4) on-premise"
Write-Host "  5) undecided"
$CloudOpt = Read-Host "Elige [1-5]"
$CloudProvider = switch ($CloudOpt) {
    "1" { "azure" }
    "2" { "aws" }
    "3" { "gcp" }
    "4" { "on-premise" }
    "5" { "undecided" }
    default { Write-Err "Opción inválida"; exit 1 }
}

Write-Host ""
Write-Info "Configuración elegida:"
Write-Info "  Proyecto:        $ProjectName"
Write-Info "  Cliente:         $ClientName"
Write-Info "  Tech legacy:     $LegacyTech"
if ($LegacyLang)  { Write-Info "  Sub-lenguaje:    $LegacyLang" }
if ($TargetStack) { Write-Info "  Stack target:    $TargetStack" }
Write-Info "  Cloud:           $CloudProvider"
Write-Host ""

$Confirm = Read-Host "¿Continuar? [s/N]"
if ($Confirm -notmatch '^[sSyY]$') { Write-Warn "Cancelado."; exit 0 }

# === Reemplazos en archivos Markdown ===
Write-Step "Aplicando reemplazos en archivos Markdown..."

$replacements = @{
    '{{ProjectName}}'   = $ProjectName
    '{{ClientName}}'    = $ClientName
    '{{LegacyTech}}'    = $LegacyTech
    '{{CloudProvider}}' = $CloudProvider
}
if ($LegacyLang)  { $replacements['{{LegacyLang}}'] = $LegacyLang }
if ($TargetStack) { $replacements['{{TargetStack}}'] = $TargetStack }

Get-ChildItem -Path . -Recurse -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\\.git\\' } |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        foreach ($key in $replacements.Keys) {
            $content = $content.Replace($key, $replacements[$key])
        }
        Set-Content -Path $_.FullName -Value $content -NoNewline
    }

# === FIX CRÍTICO: copiar agentes a .github/agents/ flat ===
# Copilot no descubre agentes en subcarpetas. Copiamos shared + tech a flat.
Write-Step "Copiando agentes Copilot a .github/agents/ flat (requisito de discovery)..."

# Limpiar copies flat previas (las subcarpetas son source-of-truth)
Get-ChildItem -Path ".github\agents" -Filter "*.agent.md" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

# 1) Agentes compartidos: SIEMPRE
$sharedDir = ".github\agents\shared"
if (Test-Path $sharedDir) {
    $sharedAgents = Get-ChildItem -Path $sharedDir -Filter "*.agent.md" -ErrorAction SilentlyContinue
    foreach ($agent in $sharedAgents) {
        Copy-Item -Path $agent.FullName -Destination ".github\agents\" -Force
        Write-Info "  Copiado: $($agent.Name) (shared)"
    }
}

# 2) Agentes de la tecnología elegida
$techDir = ".github\agents\$LegacyTech"
if (Test-Path $techDir) {
    $techAgents = Get-ChildItem -Path $techDir -Filter "*.agent.md" -ErrorAction SilentlyContinue
    if ($techAgents) {
        foreach ($agent in $techAgents) {
            Copy-Item -Path $agent.FullName -Destination ".github\agents\" -Force
            Write-Info "  Copiado: $($agent.Name) ($LegacyTech)"
        }
    } else {
        Write-Warn "  No hay agentes en $techDir. Crea los tuyos usando templates."
    }
} elseif ($LegacyTech -ne "other") {
    Write-Warn "  No existe $techDir. Crea los agentes manualmente y re-ejecuta."
}

# Validar
$flatAgents = (Get-ChildItem -Path ".github\agents" -Filter "*.agent.md" -File -ErrorAction SilentlyContinue).Count
if ($flatAgents -eq 0) {
    Write-Err "Ningún agente quedó en .github/agents/ flat. Copilot no descubrirá agentes."
    exit 1
}
Write-Info "  Total agentes descubribles por Copilot: $flatAgents"

# === Limpieza de tecnologías no elegidas (opcional) ===
Write-Host ""
$DelOtherTech = Read-Host "¿Eliminar contenido de OTRAS tecnologías legacy (recomendado para repos de cliente)? [s/N]"
if ($DelOtherTech -match '^[sSyY]$' -and $LegacyTech -ne "other") {
    foreach ($tech in @("vb", "dotnet-framework", "cobol", "java", "python")) {
        if ($tech -ne $LegacyTech) {
            Remove-Item -Recurse -Force "docs\technologies\$tech" -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force ".github\agents\$tech" -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force ".github\prompts\$tech" -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force "workshop\$tech" -ErrorAction SilentlyContinue
        }
    }
    Write-Info "  Carpetas de otras tecnologías eliminadas"
}

if ($LegacyTech -eq "vb") {
    if ($LegacyLang -eq "vb6") {
        Remove-Item -Force "docs\technologies\vb\trampas-vbnet.md" -ErrorAction SilentlyContinue
    } elseif ($LegacyLang -eq "vbnet") {
        Remove-Item -Force "docs\technologies\vb\trampas-vb6.md" -ErrorAction SilentlyContinue
    }

    switch ($TargetStack) {
        "winforms" {
            Remove-Item -Force ".github\instructions\vb-target\wpf-mvvm.instructions.md" -ErrorAction SilentlyContinue
            Remove-Item -Force ".github\instructions\vb-target\blazor.instructions.md" -ErrorAction SilentlyContinue
        }
        "wpf" {
            Remove-Item -Force ".github\instructions\vb-target\winforms.instructions.md" -ErrorAction SilentlyContinue
            Remove-Item -Force ".github\instructions\vb-target\blazor.instructions.md" -ErrorAction SilentlyContinue
        }
        "blazor" {
            Remove-Item -Force ".github\instructions\vb-target\wpf-mvvm.instructions.md" -ErrorAction SilentlyContinue
            Remove-Item -Force ".github\instructions\vb-target\winforms.instructions.md" -ErrorAction SilentlyContinue
        }
    }
    Write-Info "  Instructions del stack target ajustadas"
}

# === Limpieza de proveedores cloud no elegidos (opcional) ===
if ($CloudProvider -ne "undecided") {
    Write-Host ""
    $DelOtherCloud = Read-Host "¿Eliminar carpetas de OTROS proveedores cloud? [s/N]"
    if ($DelOtherCloud -match '^[sSyY]$') {
        foreach ($prov in @("azure", "aws", "gcp", "on-premise")) {
            if ($prov -ne $CloudProvider) {
                Remove-Item -Recurse -Force "cloud-architectures\$prov" -ErrorAction SilentlyContinue
            }
        }
        Write-Info "  Carpetas de otros proveedores cloud eliminadas"
    }
}

# === Generar archivo de configuración ===
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$langLine  = if ($LegacyLang) { $LegacyLang } else { "null" }
$stackLine = if ($TargetStack) { $TargetStack } else { "null" }
@"
# Configuración generada por bootstrap.ps1
# Re-ejecuta el script para cambiar tech, stack o cloud (sobrescribe).
project:
  name: $ProjectName
  client: $ClientName
  legacy_tech: $LegacyTech
  legacy_lang: $langLine
  target_stack: $stackLine
  cloud_provider: $CloudProvider
  bootstrapped_at: $timestamp
"@ | Set-Content -Path ".copilot-project.yml" -NoNewline
Write-Info ".copilot-project.yml generado"

# === Crear carpetas de trabajo ===
@("legacy", "src", "migration", "testing", "assessment\$ProjectName", "docs\adr", "docs\features") | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}
Write-Info "Carpetas creadas: legacy/, src/, migration/, testing/, assessment/$ProjectName/, docs/adr/, docs/features/"

# === Generar NEXT-STEPS.md persistente ===
$nextSteps = @"
# Next Steps — $ProjectName

Este archivo lo generó ``bootstrap.ps1`` con tus elecciones. Es tu guía
personalizada del flujo de modernización. Re-ejecuta el bootstrap si
cambias de stack/tech/cloud y este archivo se regenera.

## Tu configuración

- Proyecto: ``$ProjectName``
- Cliente: ``$ClientName``
- Tech legacy: ``$LegacyTech``
"@

if ($LegacyLang)  { $nextSteps += "`n- Sub-lenguaje: ``$LegacyLang```" }
if ($TargetStack) { $nextSteps += "`n- Stack target: ``$TargetStack```" }
$nextSteps += "`n- Cloud target: ``$CloudProvider```"

$nextSteps += @"


## Cómo invocar los agentes (depende del entorno)

| Entorno | Cómo |
| --- | --- |
| VS Code (Copilot Chat) | Dropdown del agent picker. ``@nombre`` solo funciona para built-ins. |
| Visual Studio 2026 (18.4+) | ``@nombre`` directo en el chat |
| GitHub Copilot CLI | ``/agent <nombre>`` o argumento ``--agent`` |
| GitHub.com | Dropdown en página de Agents |

Si los agentes no aparecen: ``Cmd/Ctrl+Shift+P`` → "Developer: Reload Window".

---

## Flujo completo de modernización (7 fases)

### Fase 0 — Business Case (¿conviene modernizar?)

``````
@business-case-analyst Construye el caso de negocio para $ProjectName
``````

Entregables: ``assessment/$ProjectName/{tco-actual,roi,riesgo,ejecutivo}-DDMMYYYY.{md,html}``

Y assessment de seguridad whitehat:
``````
@security-assessor Revisa la seguridad del código en legacy/
``````

---

### Fase 1 — Assessment (¿qué tiene el legacy?)

Coloca primero el código legacy del cliente:
``````powershell
Copy-Item -Recurse C:\ruta\al\codigo-legacy\* legacy\
``````

Luego invoca:
"@

if ($LegacyTech -eq "vb") {
    $nextSteps += @"

``````
@vb-assessment Analiza el sistema en legacy/
``````
"@
} elseif ($LegacyTech -eq "dotnet-framework") {
    $nextSteps += @"

``````
@dotnet-assessment Analiza el sistema en legacy/
``````
"@
} else {
    $nextSteps += @"

``````
# Para $LegacyTech los agentes aún son placeholders.
# Crea los tuyos en .github/agents/$LegacyTech/ usando templates en .github/agents/_templates/
# y re-ejecuta el bootstrap para que se copien al nivel flat.
``````
"@
}

$nextSteps += @"


Entregables: ``docs/features/`` con un ``.md`` por feature funcional + grafo de dependencias.

---

### Fase 2 — Planning (¿hacia dónde y por qué?)

"@

if ($LegacyTech -eq "vb") {
    $nextSteps += "``````" + "`n@vb-planning`n" + "``````"
} elseif ($LegacyTech -eq "dotnet-framework") {
    $nextSteps += "``````" + "`n@dotnet-planning`n" + "``````"
}

$nextSteps += @"


Entregables: ``docs/ARQUITECTURA-TARGET.md`` + ADRs en ``docs/adr/``.

---

### Fase 2.5 — Plan Refinement (ajustar scope con el usuario)

**Nuevo agente colaborativo.** Trabaja CONTIGO para refinar el plan:
features muertos que no se migran, código que el cliente abandonó,
ambigüedades del plan, scope reducido vs scope total.

``````
@plan-refiner Revisa el plan de migración conmigo para ajustar scope
``````

Entregable: ``docs/MIGRATION-SCOPE.md`` con scope final acordado + features descartados.

---

### Fase 3 — Modernization Strategy (¿qué patrón de modernización?)

Decide entre las 6 R's de Gartner (Rehost / Replatform / Refactor /
Rearchitect / Rebuild / Retire) y, si es app Windows desktop, propone
path específico a web/contenedor/k8s.

``````
@modernization-strategy Recomienda path de modernización para $ProjectName
``````

Entregable: ``docs/MODERNIZATION-PATH.md`` con la 6R elegida + arquitectura conceptual target.

---

### Fase 4 — Execution (construir)

"@

if ($LegacyTech -eq "vb") {
    $nextSteps += "``````" + "`n@vb-migration Migra el sistema según los ADRs aprobados`n" + "``````"
} elseif ($LegacyTech -eq "dotnet-framework") {
    $nextSteps += "``````" + "`n@dotnet-migration Migra el sistema según los ADRs aprobados`n" + "``````"
}

$nextSteps += @"


Entregable: código modernizado en ``src/`` con paridad funcional vs ``legacy/``.

---

### Fase 5 — Testing & QA (validar que funciona)

**Nuevo agente.** Genera tests de paridad sistemáticos, valida cobertura,
corre los tests y reporta gaps.

``````
@migration-tester Genera y ejecuta tests de paridad para el código en src/
``````

Entregables:
- ``testing/parity-report.md`` con tabla de paridad por feature
- ``testing/coverage-report.md`` con cobertura por capa
- Tests unitarios + integración en ``tests/`` o equivalente del stack elegido

---

### Fase 6 — Cloud Deployment (¿dónde corre?)

"@

if ($CloudProvider -eq "azure") {
    $nextSteps += @"

``````
@azure-architect Diseña la arquitectura Azure target con Mermaid y precios validados
``````

O para análisis multi-cloud genérico:

``````
@cloud-architect Diseña la arquitectura cloud target en azure
``````
"@
} else {
    $nextSteps += @"

``````
@cloud-architect Diseña la arquitectura cloud target en $CloudProvider
``````
"@
}

$nextSteps += @"


---

## Notas importantes

- **El bootstrap NO se autoeliminó.** Re-ejecútalo si quieres cambiar tech/stack/cloud.
- **No edites** los archivos en ``.github/agents/*.agent.md`` flat — son copias.
  Edita las fuentes en ``.github/agents/shared/`` o ``.github/agents/<tech>/`` y re-ejecuta.
- Para validar localmente que todo funcione: ``cat VALIDATION-CHECKLIST.md``.
- Metodología detallada: ``docs/methodology/00-overview.md``.
"@

$nextSteps | Set-Content -Path "NEXT-STEPS.md" -NoNewline
Write-Info "NEXT-STEPS.md generado con tu flujo personalizado"

# === Mensaje final en pantalla (NO autoelimina el script) ===
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  ✓ Bootstrap completado." -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resumen:"
Write-Host "  - Placeholders reemplazados en todos los .md"
Write-Host "  - $flatAgents agentes copiados a .github/agents/ (descubribles por Copilot)"
Write-Host "  - .copilot-project.yml generado"
Write-Host "  - NEXT-STEPS.md generado con tu flujo personalizado"
Write-Host "  - Carpetas creadas: legacy/, src/, testing/, assessment/$ProjectName/"
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  Siguientes pasos" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) Lee la guía personalizada que se generó:"
Write-Host "     cat NEXT-STEPS.md   (o ábrelo en VS Code)"
Write-Host ""
Write-Host "2) Coloca el código legacy del cliente en legacy/"
Write-Host ""
Write-Host "3) Abre VS Code:"
Write-Host "     code ."
Write-Host ""
Write-Host "4) Verifica que Copilot detecta los agentes:"
Write-Host "     - VS Code: click en el dropdown del agent picker (NO @nombre)"
Write-Host "     - Visual Studio 2026: @nombre directo"
Write-Host "     - Copilot CLI: /agent <nombre>"
Write-Host ""
Write-Host "Los agentes que deben aparecer:"

Get-ChildItem -Path ".github\agents" -Filter "*.agent.md" -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '(?m)^name:\s*(.+)$') {
        $name = $matches[1].Trim().Trim('"')
        Write-Host "       $name"
    }
}

Write-Host ""
Write-Host "Notas importantes:"
Write-Host "  - Este script NO se autoelimina. Puedes re-ejecutarlo para"
Write-Host "    cambiar tech, stack o cloud sin perder trabajo."
Write-Host "  - Los agentes en .github/agents/<subcarpeta>/ son la fuente"
Write-Host "    de verdad. Las copias en .github/agents/ flat las regenera"
Write-Host "    el bootstrap. NO edites las copias flat."
Write-Host "  - Para validar funcionalidad: cat VALIDATION-CHECKLIST.md"
Write-Host ""
