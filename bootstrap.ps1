#!/usr/bin/env pwsh
# Script de bootstrapping para adaptar la plantilla a tu proyecto (Windows / PowerShell)

if (-not (Test-Path "README.md") -or -not (Test-Path ".github/agents")) {
    Write-Host "[error] Este script debe ejecutarse desde la raiz del repo de la plantilla." -ForegroundColor Red
    exit 1
}

Write-Host "================================================="
Write-Host "  Bootstrap - plantilla de modernizacion legacy"
Write-Host "================================================="
Write-Host ""

$ProjectName = Read-Host "Nombre del proyecto (PascalCase, ej: SgapVc)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Host "[error] Nombre del proyecto es obligatorio." -ForegroundColor Red
    exit 1
}

$ClientName = Read-Host "Nombre del cliente"
if ([string]::IsNullOrWhiteSpace($ClientName)) {
    Write-Host "[error] Nombre del cliente es obligatorio." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Tecnologia legacy a modernizar:"
Write-Host "  1) vb                Visual Basic 6 o VB.NET (cobertura completa)"
Write-Host "  2) dotnet-framework  .NET Framework 2.0-4.8 (cobertura completa)"
Write-Host "  3) java              Java legacy: J2EE, Spring 3/4, Oracle Forms (cobertura completa)"
Write-Host "  4) cobol             COBOL on mainframe / distributed (placeholder)"
Write-Host "  5) python            Python 2 / 3 antiguo (placeholder)"
Write-Host "  6) other             Otra (no se eliminara nada)"
$TechOpt = Read-Host "Elige [1-6]"
$LegacyTech = switch ($TechOpt) {
    "1" { "vb" }
    "2" { "dotnet-framework" }
    "3" { "java" }
    "4" { "cobol" }
    "5" { "python" }
    "6" { "other" }
    default { Write-Host "[error] Opcion invalida" -ForegroundColor Red; exit 1 }
}

$LegacyLang = ""
$TargetStack = ""
$JavaSubstack = ""

if ($LegacyTech -eq "vb") {
    Write-Host ""
    Write-Host "Sub-lenguaje VB:"
    Write-Host "  1) vb6     (Visual Basic 6, codigo .frm/.bas/.cls)"
    Write-Host "  2) vbnet   (VB.NET legacy, .NET Framework 1.1-4.8)"
    $LangOpt = Read-Host "Elige [1-2]"
    $LegacyLang = switch ($LangOpt) {
        "1" { "vb6" }
        "2" { "vbnet" }
        default { Write-Host "[error] Opcion invalida" -ForegroundColor Red; exit 1 }
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
        default { Write-Host "[error] Opcion invalida" -ForegroundColor Red; exit 1 }
    }
}

if ($LegacyTech -eq "java") {
    Write-Host ""
    Write-Host "Sub-stack Java legacy:"
    Write-Host "  1) j2ee           EJB 2.x/3.x, JSP, Servlets, WebLogic/WebSphere"
    Write-Host "  2) spring-legacy  Spring 3.x/4.x con Struts, Java 6/7/8"
    Write-Host "  3) oracle-forms   Oracle Forms (.fmb), PL/SQL embebido + en BD"
    $JavaOpt = Read-Host "Elige [1-3]"
    $JavaSubstack = switch ($JavaOpt) {
        "1" { "j2ee" }
        "2" { "spring-legacy" }
        "3" { "oracle-forms" }
        default { Write-Host "[error] Opcion invalida" -ForegroundColor Red; exit 1 }
    }
    $LegacyLang = $JavaSubstack
}

Write-Host ""
Write-Host "Proveedor cloud objetivo (Fase 4):"
Write-Host "  1) azure                Microsoft Azure (cobertura completa con @azure-architect)"
Write-Host "  2) on-premise           on-premise / hibrido"
Write-Host "  3) undecided            decidir despues (mantener placeholders)"
$CloudOpt = Read-Host "Elige [1-3]"
$CloudProvider = switch ($CloudOpt) {
    "1" { "azure" }
    "2" { "on-premise" }
    "3" { "undecided" }
    default { Write-Host "[error] Opcion invalida" -ForegroundColor Red; exit 1 }
}

Write-Host ""
Write-Host "[info] Configuracion elegida:" -ForegroundColor Green
Write-Host "[info]   Proyecto: $ProjectName" -ForegroundColor Green
Write-Host "[info]   Cliente:  $ClientName" -ForegroundColor Green
if ($LegacyTech -eq "java") {
    Write-Host "[info]   Legacy:   java/$JavaSubstack" -ForegroundColor Green
} else {
    $legacyDisplay = $LegacyTech
    if ($LegacyLang) { $legacyDisplay = "$LegacyTech/$LegacyLang" }
    Write-Host "[info]   Legacy:   $legacyDisplay" -ForegroundColor Green
}
$targetDisplay = if ($TargetStack) { $TargetStack } else { "(se decide en Fase 2)" }
Write-Host "[info]   Target:   $targetDisplay" -ForegroundColor Green
Write-Host "[info]   Cloud:    $CloudProvider" -ForegroundColor Green
Write-Host ""
$Confirm = Read-Host "Continuar? [s/N]"
if ($Confirm -notmatch "^[sSyY]$") {
    Write-Host "[warn] Cancelado por el usuario." -ForegroundColor Yellow
    exit 0
}

Write-Host "[info] Aplicando reemplazos en archivos Markdown..." -ForegroundColor Green

Get-ChildItem -Recurse -Filter "*.md" -Exclude ".git" | Where-Object { $_.FullName -notmatch "\\\.git\\" } | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace "\{\{ProjectName\}\}", $ProjectName
    $content = $content -replace "\{\{ClientName\}\}", $ClientName
    $content = $content -replace "\{\{LegacyTech\}\}", $LegacyTech
    $content = $content -replace "\{\{LegacyLang\}\}", $LegacyLang
    $content = $content -replace "\{\{TargetStack\}\}", $TargetStack
    $content = $content -replace "\{\{CloudProvider\}\}", $CloudProvider
    Set-Content $_.FullName -Value $content -NoNewline
}

Write-Host "[info] Copiando agentes a .github/agents/ plano..." -ForegroundColor Green

Get-ChildItem ".github/agents/shared" -Filter "*.agent.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName ".github/agents/" -Force
}

switch ($LegacyTech) {
    "vb" {
        Get-ChildItem ".github/agents/vb" -Filter "*.agent.md" -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item $_.FullName ".github/agents/" -Force
        }
        Write-Host "[info]   Copiados: agentes VB (3) + compartidos" -ForegroundColor Green
    }
    "dotnet-framework" {
        Get-ChildItem ".github/agents/dotnet-framework" -Filter "*.agent.md" -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item $_.FullName ".github/agents/" -Force
        }
        Write-Host "[info]   Copiados: agentes .NET Framework (3) + compartidos" -ForegroundColor Green
    }
    "java" {
        foreach ($phase in @("assessment", "planning", "migration")) {
            $src = ".github/agents/java/$JavaSubstack-$phase.agent.md"
            $dest = ".github/agents/$JavaSubstack-$phase.agent.md"
            if (Test-Path $src) {
                Copy-Item $src $dest -Force
            } else {
                Write-Host "[warn]   No encontrado: $src" -ForegroundColor Yellow
            }
        }
        Write-Host "[info]   Copiados: agentes $JavaSubstack (3) + compartidos" -ForegroundColor Green
    }
}

$DelOtherTech = Read-Host "Eliminar contenido de OTRAS tecnologias legacy (recomendado para repos de cliente)? [s/N]"
if ($DelOtherTech -match "^[sSyY]$" -and $LegacyTech -ne "other") {
    foreach ($tech in @("vb", "dotnet-framework", "cobol", "java", "python")) {
        if ($tech -ne $LegacyTech) {
            Remove-Item "docs/technologies/$tech" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item ".github/agents/$tech" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item ".github/prompts/$tech" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item ".github/instructions/$tech-target" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "workshop/$tech" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if ($LegacyTech -eq "java") {
        Remove-Item ".github/agents/java" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Remove-Item ".github/agents/shared" -Recurse -Force -ErrorAction SilentlyContinue

    if ($LegacyTech -ne "dotnet-framework") {
        Remove-Item "docs/QUICKSTART-dotnet.md" -Force -ErrorAction SilentlyContinue
    }
    if ($LegacyTech -ne "java") {
        Remove-Item "docs/QUICKSTART-java.md" -Force -ErrorAction SilentlyContinue
    }

    Write-Host "[info]   Carpetas de otras tecnologias eliminadas" -ForegroundColor Green
}

if ($LegacyTech -eq "vb") {
    if ($LegacyLang -eq "vb6") {
        Remove-Item "docs/technologies/vb/trampas-vbnet.md" -Force -ErrorAction SilentlyContinue
    } elseif ($LegacyLang -eq "vbnet") {
        Remove-Item "docs/technologies/vb/trampas-vb6.md" -Force -ErrorAction SilentlyContinue
    }

    switch ($TargetStack) {
        "winforms" {
            Remove-Item ".github/instructions/vb-target/wpf-mvvm.instructions.md" -Force -ErrorAction SilentlyContinue
            Remove-Item ".github/instructions/vb-target/blazor.instructions.md" -Force -ErrorAction SilentlyContinue
        }
        "wpf" {
            Remove-Item ".github/instructions/vb-target/winforms.instructions.md" -Force -ErrorAction SilentlyContinue
            Remove-Item ".github/instructions/vb-target/blazor.instructions.md" -Force -ErrorAction SilentlyContinue
        }
        "blazor" {
            Remove-Item ".github/instructions/vb-target/wpf-mvvm.instructions.md" -Force -ErrorAction SilentlyContinue
            Remove-Item ".github/instructions/vb-target/winforms.instructions.md" -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "[info]   Instructions del stack target ajustadas" -ForegroundColor Green
}

if ($CloudProvider -ne "undecided") {
    $DelOtherCloud = Read-Host "Eliminar carpetas de OTROS proveedores cloud no elegidos? [s/N]"
    if ($DelOtherCloud -match "^[sSyY]$") {
        foreach ($prov in @("azure", "on-premise")) {
            if ($prov -ne $CloudProvider) {
                Remove-Item "cloud-architectures/$prov" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Host "[info]   Carpetas de otros proveedores cloud eliminadas" -ForegroundColor Green
    }
}

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$yamlContent = @"
# Configuracion generada por bootstrap.ps1 - NO editar manualmente.
project:
  name: $ProjectName
  client: $ClientName
  legacy_tech: $LegacyTech
  legacy_lang: $LegacyLang
  java_substack: $JavaSubstack
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
"@
Set-Content ".copilot-project.yml" -Value $yamlContent
Write-Host "[info] .copilot-project.yml generado" -ForegroundColor Green

if (-not (Test-Path "legacy")) { New-Item -ItemType Directory -Path "legacy" | Out-Null }
if (-not (Test-Path "legacy/README.md")) {
    $legacyReadme = @"
# legacy/ - codigo fuente original (READ-ONLY)

Coloca aqui el codigo fuente legacy del cliente sin modificarlo.

## Reglas

1. Solo lectura. Toda modernizacion va en src/.
2. No commitear secretos.
3. Respeta la estructura original.
4. Anonimiza datos sensibles.
"@
    Set-Content "legacy/README.md" -Value $legacyReadme
    Write-Host "[info] legacy/README.md creado" -ForegroundColor Green
}

if (-not (Test-Path "migration")) { New-Item -ItemType Directory -Path "migration" | Out-Null }
if (-not (Test-Path "src")) { New-Item -ItemType Directory -Path "src" | Out-Null }

$DelBootstrap = Read-Host "Eliminar este script de bootstrap? [s/N]"
if ($DelBootstrap -match "^[sSyY]$") {
    Remove-Item "bootstrap.sh" -Force -ErrorAction SilentlyContinue
    Remove-Item "bootstrap.ps1" -Force -ErrorAction SilentlyContinue
    Write-Host "[info] Scripts de bootstrap eliminados" -ForegroundColor Green
}

Write-Host ""
Write-Host "[info] Bootstrap completado." -ForegroundColor Green
Write-Host ""
Write-Host "Pasos siguientes:"
Write-Host "  1. Revisar los archivos generados."
Write-Host "  2. (Opcional) Fase 0 - Business Case:"
Write-Host "       @business-case-analyst Construye el caso de negocio para $ProjectName"
Write-Host "  3. Colocar el codigo legacy del cliente en la carpeta legacy/"
Write-Host "  4. (Recomendado) Fase 0 - Assessment de seguridad whitehat:"
Write-Host "       @security-assessor Revisa la seguridad del codigo en legacy/"
Write-Host "  5. Abrir VS Code con Copilot Chat: code ."

switch ($LegacyTech) {
    "vb" {
        Write-Host "  6. Iniciar Fase 1 (Assessment):"
        Write-Host "       @vb-assessment Analiza el sistema en legacy/"
        Write-Host "     Luego: @vb-planning  ->  @vb-migration"
    }
    "dotnet-framework" {
        Write-Host "  6. Iniciar Fase 1 (Assessment):"
        Write-Host "       @dotnet-assessment Analiza el sistema en legacy/"
        Write-Host "     Luego: @dotnet-planning  ->  @dotnet-migration"
    }
    "java" {
        Write-Host "  6. Iniciar Fase 1 (Assessment):"
        Write-Host "       @$JavaSubstack-assessment Analiza el sistema en legacy/"
        Write-Host "     Luego: @$JavaSubstack-planning  ->  @$JavaSubstack-migration"
        if ($JavaSubstack -eq "oracle-forms") {
            Write-Host ""
            Write-Host "     Nota: Oracle Forms requiere extraer .fmb a XML antes del assessment."
            Write-Host "     Ver docs/technologies/java/03-trampas-oracle-forms.md"
        }
    }
    default {
        Write-Host "  6. Para esta tecnologia los agentes aun son placeholders."
    }
}

if ($CloudProvider -eq "azure") {
    Write-Host "  7. Cuando el codigo este modernizado, Fase 4 (Cloud Azure):"
    Write-Host "       @azure-architect Disena la arquitectura cloud target en Azure"
} elseif ($CloudProvider -eq "on-premise") {
    Write-Host "  7. Cuando el codigo este modernizado, Fase 4 (on-premise):"
    Write-Host "       Revisar cloud-architectures/on-premise/ para patrones aplicables"
}
Write-Host ""
