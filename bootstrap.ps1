# Script de bootstrapping (PowerShell) para adaptar la plantilla a tu proyecto.
# Equivalente al bootstrap.sh para entornos Windows sin Bash.
#
# Uso: .\bootstrap.ps1

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

function Write-Info { param($Message) Write-Host "[info] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[warn] $Message" -ForegroundColor Yellow }
function Write-Err  { param($Message) Write-Host "[error] $Message" -ForegroundColor Red }

if (-not (Test-Path "README.md") -or -not (Test-Path ".github\agents")) {
    Write-Err "Este script debe ejecutarse desde la raíz del repo de la plantilla."
    exit 1
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Bootstrap - plantilla de modernizacion legacy"   -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$ProjectName = Read-Host "Nombre del proyecto (PascalCase)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { Write-Err "Obligatorio."; exit 1 }

$ClientName = Read-Host "Nombre del cliente"
if ([string]::IsNullOrWhiteSpace($ClientName)) { Write-Err "Obligatorio."; exit 1 }

Write-Host ""
Write-Host "Tecnologia legacy a modernizar:"
Write-Host "  1) vb                Visual Basic 6 o VB.NET (cobertura completa)"
Write-Host "  2) dotnet-framework  .NET Framework 2.0-4.8 (completo)"
Write-Host "  3) cobol             COBOL (placeholder)"
Write-Host "  4) java              Java legacy (placeholder)"
Write-Host "  5) python            Python 2 / 3 antiguo (placeholder)"
Write-Host "  6) other"
$TechOpt = Read-Host "Elige [1-6]"
$LegacyTech = switch ($TechOpt) {
    "1" { "vb" }; "2" { "dotnet-framework" }; "3" { "cobol" }
    "4" { "java" }; "5" { "python" }; "6" { "other" }
    default { Write-Err "Opcion invalida"; exit 1 }
}

$LegacyLang = ""
$TargetStack = ""
if ($LegacyTech -eq "vb") {
    Write-Host ""
    Write-Host "Sub-lenguaje VB:"
    Write-Host "  1) vb6     2) vbnet"
    $LangOpt = Read-Host "Elige [1-2]"
    $LegacyLang = switch ($LangOpt) {
        "1" { "vb6" }; "2" { "vbnet" }
        default { Write-Err "Opcion invalida"; exit 1 }
    }

    Write-Host ""
    Write-Host "Stack target:"
    Write-Host "  1) winforms  2) wpf  3) blazor"
    $StackOpt = Read-Host "Elige [1-3]"
    $TargetStack = switch ($StackOpt) {
        "1" { "winforms" }; "2" { "wpf" }; "3" { "blazor" }
        default { Write-Err "Opcion invalida"; exit 1 }
    }
}

Write-Host ""
Write-Host "Proveedor cloud objetivo (Fase 4):"
Write-Host "  1) azure  2) aws  3) gcp  4) on-premise  5) undecided"
$CloudOpt = Read-Host "Elige [1-5]"
$CloudProvider = switch ($CloudOpt) {
    "1" { "azure" }; "2" { "aws" }; "3" { "gcp" }
    "4" { "on-premise" }; "5" { "undecided" }
    default { Write-Err "Opcion invalida"; exit 1 }
}

Write-Host ""
Write-Info "Configuracion: $ProjectName / $ClientName / $LegacyTech$(if($LegacyLang){"/$LegacyLang"}) / target=$TargetStack / cloud=$CloudProvider"
$Confirm = Read-Host "Continuar? [s/N]"
if ($Confirm -notmatch '^[sSyY]$') { Write-Warn "Cancelado."; exit 0 }

# === Reemplazos en MD ===
Write-Info "Aplicando reemplazos..."
$replacements = @{
    '{{ProjectName}}'   = $ProjectName
    '{{ClientName}}'    = $ClientName
    '{{LegacyTech}}'    = $LegacyTech
    '{{LegacyLang}}'    = $LegacyLang
    '{{TargetStack}}'   = $TargetStack
    '{{CloudProvider}}' = $CloudProvider
}
Get-ChildItem -Path . -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch '\\\.git\\' } | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($k in $replacements.Keys) { $content = $content.Replace($k, $replacements[$k]) }
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# === Limpieza de otras tecnologias ===
$DelOther = Read-Host "Eliminar contenido de OTRAS tecnologias legacy? [s/N]"
if ($DelOther -match '^[sSyY]$' -and $LegacyTech -ne "other") {
    foreach ($t in @("vb","dotnet-framework","cobol","java","python")) {
        if ($t -ne $LegacyTech) {
            Remove-Item -Recurse -Force "docs\technologies\$t" -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force ".github\agents\$t" -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force ".github\prompts\$t" -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force "workshop\$t" -ErrorAction SilentlyContinue
        }
    }
    Write-Info "  Otras tecnologias eliminadas"
}

if ($LegacyTech -eq "vb") {
    if ($LegacyLang -eq "vb6") {
        Remove-Item -Force "docs\technologies\vb\trampas-vbnet.md" -ErrorAction SilentlyContinue
    } elseif ($LegacyLang -eq "vbnet") {
        Remove-Item -Force "docs\technologies\vb\trampas-vb6.md" -ErrorAction SilentlyContinue
    }

    $remove = switch ($TargetStack) {
        "winforms" { @("wpf-mvvm.instructions.md","blazor.instructions.md") }
        "wpf"      { @("winforms.instructions.md","blazor.instructions.md") }
        "blazor"   { @("wpf-mvvm.instructions.md","winforms.instructions.md") }
    }
    foreach ($f in $remove) {
        Remove-Item -Force ".github\instructions\vb-target\$f" -ErrorAction SilentlyContinue
    }
    Write-Info "  Instructions del stack target ajustadas"
}

# === Limpieza de proveedores cloud no elegidos ===
if ($CloudProvider -ne "undecided") {
    $DelCloud = Read-Host "Eliminar carpetas de OTROS proveedores cloud? [s/N]"
    if ($DelCloud -match '^[sSyY]$') {
        foreach ($p in @("azure","aws","gcp","on-premise")) {
            if ($p -ne $CloudProvider) {
                Remove-Item -Recurse -Force "cloud-architectures\$p" -ErrorAction SilentlyContinue
            }
        }
        Write-Info "  Otros proveedores cloud eliminados"
    }
}

# === Config ===
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
@"
# Configuracion generada por bootstrap.ps1 - NO editar manualmente.
project:
  name: $ProjectName
  client: $ClientName
  legacy_tech: $LegacyTech
  legacy_lang: $LegacyLang
  target_stack: $TargetStack
  cloud_provider: $CloudProvider
  bootstrapped_at: $timestamp

models:
  default: Claude Sonnet 4.6
  assessment: Claude Opus 4.6
  planning: Claude Opus 4.6
  migration: Claude Sonnet 4.6
  security: Claude Opus 4.6
  cloud_architecture: Claude Opus 4.6

paths:
  legacy: legacy/
  modern: src/
  docs: docs/
  assessment: assessment/
  migration: migration/
  cloud: cloud-architectures/
"@ | Set-Content -Path ".copilot-project.yml" -NoNewline
Write-Info ".copilot-project.yml generado"

# === Crear carpetas de trabajo ===
New-Item -ItemType Directory -Force -Path "legacy","migration","src" | Out-Null
if (-not (Test-Path "legacy/README.md")) {
@'
# legacy/ - codigo fuente original (READ-ONLY)

Coloca aqui el codigo fuente legacy del cliente sin modificarlo. Los agentes lo leen pero nunca escriben sobre el.

## Reglas
1. Solo lectura. Toda modernizacion va en src/ o migrated/.
2. No commitear secretos. Limpia connection strings, API keys, credenciales.
3. Respeta la estructura original.
4. Anonimiza datos sensibles si aplica regulacion.
'@ | Set-Content -Path "legacy/README.md"
    Write-Info "legacy/README.md creado"
}

$DelBoot = Read-Host "Eliminar scripts de bootstrap? [s/N]"
if ($DelBoot -match '^[sSyY]$') {
    Remove-Item bootstrap.ps1 -Force -ErrorAction SilentlyContinue
    Remove-Item bootstrap.sh  -Force -ErrorAction SilentlyContinue
    Write-Info "Scripts eliminados"
}

Write-Host ""
Write-Info "Bootstrap completado."
Write-Host ""
Write-Host "Pasos siguientes:"
Write-Host "  1. Revisar archivos generados."
Write-Host "  2. (Opcional) Fase 0 - Business Case:  @business-case-analyst"
Write-Host "  3. Colocar codigo legacy en carpeta legacy/"
Write-Host "  4. (Recomendado) Fase 0 - Assessment de seguridad: @security-assessor"
Write-Host "     Outputs en assessment\$ProjectName\<categoria>-DDMMYYYY.{md,html}"
Write-Host "  5. Abrir VS Code: code ."
if ($LegacyTech -eq "vb") {
    Write-Host "  6. Fase 1 - Assessment:  @vb-assessment Analiza el sistema legacy/"
} elseif ($LegacyTech -eq "dotnet-framework") {
    Write-Host "  6. Fase 1 - Assessment:  @dotnet-assessment Analiza el sistema legacy/"
    Write-Host "     Luego: @dotnet-planning  ->  @dotnet-migration"
} else {
    Write-Host "  6. Crear tus agentes en .github\agents\$LegacyTech\ desde templates."
}
Write-Host "  7. Fase 4 - Cloud:  @cloud-architect Disena arquitectura en $CloudProvider"
Write-Host ""
