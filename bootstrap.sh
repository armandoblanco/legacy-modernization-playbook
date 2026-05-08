#!/usr/bin/env bash
# Script de bootstrapping para adaptar la plantilla a tu proyecto.
# Reemplaza los placeholders del repo con valores específicos del proyecto del cliente.
#
# Uso:
#   ./bootstrap.sh
#
# Pregunta interactivamente:
#   - Nombre del proyecto (PascalCase)
#   - Nombre del cliente
#   - Tecnología legacy (vb | dotnet-framework | cobol | java | python | other)
#   - (Si tecnología = vb) sub-lenguaje legacy (vb6 | vbnet)
#   - (Si tecnología = vb) stack target (winforms | wpf | blazor)
#   - Proveedor cloud objetivo (azure | aws | gcp | on-premise | undecided)

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

info()    { echo -e "${GREEN}[info]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; }

if [[ ! -f "README.md" ]] || [[ ! -d ".github/agents" ]]; then
    error "Este script debe ejecutarse desde la raíz del repo de la plantilla."
    exit 1
fi

echo "================================================="
echo "  Bootstrap — plantilla de modernización legacy"
echo "================================================="
echo

# === Recolección de valores ===

read -rp "Nombre del proyecto (PascalCase, ej: SgapVc): " PROJECT_NAME
[[ -z "$PROJECT_NAME" ]] && { error "Nombre del proyecto es obligatorio."; exit 1; }

read -rp "Nombre del cliente: " CLIENT_NAME
[[ -z "$CLIENT_NAME" ]] && { error "Nombre del cliente es obligatorio."; exit 1; }

echo
echo "Tecnología legacy a modernizar:"
echo "  1) vb                Visual Basic 6 o VB.NET (cobertura completa)"
echo "  2) dotnet-framework  .NET Framework 2.0–4.8 (completo)"
echo "  3) cobol             COBOL on mainframe / distributed (placeholder)"
echo "  4) java              Java legacy (J2EE, Java 6/7/8) (placeholder)"
echo "  5) python            Python 2 / 3 antiguo (placeholder)"
echo "  6) other             Otra (no se eliminará nada)"
read -rp "Elige [1-6]: " TECH_OPT
case "$TECH_OPT" in
    1) LEGACY_TECH="vb" ;;
    2) LEGACY_TECH="dotnet-framework" ;;
    3) LEGACY_TECH="cobol" ;;
    4) LEGACY_TECH="java" ;;
    5) LEGACY_TECH="python" ;;
    6) LEGACY_TECH="other" ;;
    *) error "Opción inválida"; exit 1 ;;
esac

LEGACY_LANG=""
TARGET_STACK=""
if [[ "$LEGACY_TECH" == "vb" ]]; then
    echo
    echo "Sub-lenguaje VB:"
    echo "  1) vb6     (Visual Basic 6, código .frm/.bas/.cls)"
    echo "  2) vbnet   (VB.NET legacy, .NET Framework 1.1–4.8)"
    read -rp "Elige [1-2]: " LANG_OPT
    case "$LANG_OPT" in
        1) LEGACY_LANG="vb6" ;;
        2) LEGACY_LANG="vbnet" ;;
        *) error "Opción inválida"; exit 1 ;;
    esac

    echo
    echo "Stack target:"
    echo "  1) winforms  (.NET 8 desktop conservador)"
    echo "  2) wpf       (.NET 8 desktop con MVVM)"
    echo "  3) blazor    (Blazor Server / ASP.NET Core)"
    read -rp "Elige [1-3]: " STACK_OPT
    case "$STACK_OPT" in
        1) TARGET_STACK="winforms" ;;
        2) TARGET_STACK="wpf" ;;
        3) TARGET_STACK="blazor" ;;
        *) error "Opción inválida"; exit 1 ;;
    esac
fi

echo
echo "Proveedor cloud objetivo (Fase 4):"
echo "  1) azure"
echo "  2) aws"
echo "  3) gcp"
echo "  4) on-premise / híbrido"
echo "  5) undecided (mantener todos los placeholders)"
read -rp "Elige [1-5]: " CLOUD_OPT
case "$CLOUD_OPT" in
    1) CLOUD_PROVIDER="azure" ;;
    2) CLOUD_PROVIDER="aws" ;;
    3) CLOUD_PROVIDER="gcp" ;;
    4) CLOUD_PROVIDER="on-premise" ;;
    5) CLOUD_PROVIDER="undecided" ;;
    *) error "Opción inválida"; exit 1 ;;
esac

echo
info "Configuración elegida:"
info "  Proyecto: $PROJECT_NAME"
info "  Cliente:  $CLIENT_NAME"
info "  Legacy:   $LEGACY_TECH${LEGACY_LANG:+/$LEGACY_LANG}"
info "  Target:   ${TARGET_STACK:-(no aplica para esta tech aún)}"
info "  Cloud:    $CLOUD_PROVIDER"
echo
read -rp "¿Continuar? [s/N]: " CONFIRM
[[ ! "$CONFIRM" =~ ^[sSyY]$ ]] && { warn "Cancelado por el usuario."; exit 0; }

# === Reemplazos en archivos Markdown ===

info "Aplicando reemplazos en archivos Markdown..."

sed_inplace() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|$1|$2|g" "$3"
    else
        sed -i "s|$1|$2|g" "$3"
    fi
}

find . -type f -name "*.md" -not -path "./.git/*" | while read -r file; do
    sed_inplace "{{ProjectName}}" "$PROJECT_NAME" "$file"
    sed_inplace "{{ClientName}}" "$CLIENT_NAME" "$file"
    sed_inplace "{{LegacyTech}}" "$LEGACY_TECH" "$file"
    sed_inplace "{{LegacyLang}}" "$LEGACY_LANG" "$file"
    sed_inplace "{{TargetStack}}" "$TARGET_STACK" "$file"
    sed_inplace "{{CloudProvider}}" "$CLOUD_PROVIDER" "$file"
done

# === Limpieza de tecnologías no elegidas (opcional) ===

read -rp "¿Eliminar contenido de OTRAS tecnologías legacy (recomendado para repos de cliente)? [s/N]: " DEL_OTHER_TECH
if [[ "$DEL_OTHER_TECH" =~ ^[sSyY]$ ]] && [[ "$LEGACY_TECH" != "other" ]]; then
    for tech in vb dotnet-framework cobol java python; do
        if [[ "$tech" != "$LEGACY_TECH" ]]; then
            rm -rf "docs/technologies/$tech" 2>/dev/null || true
            rm -rf ".github/agents/$tech" 2>/dev/null || true
            rm -rf ".github/prompts/$tech" 2>/dev/null || true
            rm -rf "workshop/$tech" 2>/dev/null || true
        fi
    done
    info "  Carpetas de otras tecnologías eliminadas"
fi

# Si tech = vb, limpiar trampas y stack instructions del sub-lenguaje no elegido
if [[ "$LEGACY_TECH" == "vb" ]]; then
    if [[ "$LEGACY_LANG" == "vb6" ]]; then
        rm -f docs/technologies/vb/trampas-vbnet.md 2>/dev/null || true
    elif [[ "$LEGACY_LANG" == "vbnet" ]]; then
        rm -f docs/technologies/vb/trampas-vb6.md 2>/dev/null || true
    fi

    case "$TARGET_STACK" in
        winforms)
            rm -f .github/instructions/vb-target/wpf-mvvm.instructions.md 2>/dev/null || true
            rm -f .github/instructions/vb-target/blazor.instructions.md 2>/dev/null || true
            ;;
        wpf)
            rm -f .github/instructions/vb-target/winforms.instructions.md 2>/dev/null || true
            rm -f .github/instructions/vb-target/blazor.instructions.md 2>/dev/null || true
            ;;
        blazor)
            rm -f .github/instructions/vb-target/wpf-mvvm.instructions.md 2>/dev/null || true
            rm -f .github/instructions/vb-target/winforms.instructions.md 2>/dev/null || true
            ;;
    esac
    info "  Instructions del stack target ajustadas"
fi

# === Limpieza de proveedores cloud no elegidos (opcional) ===

if [[ "$CLOUD_PROVIDER" != "undecided" ]]; then
    read -rp "¿Eliminar carpetas de OTROS proveedores cloud no elegidos? [s/N]: " DEL_OTHER_CLOUD
    if [[ "$DEL_OTHER_CLOUD" =~ ^[sSyY]$ ]]; then
        for prov in azure aws gcp on-premise; do
            if [[ "$prov" != "$CLOUD_PROVIDER" ]]; then
                rm -rf "cloud-architectures/$prov" 2>/dev/null || true
            fi
        done
        info "  Carpetas de otros proveedores cloud eliminadas"
    fi
fi

# === Generar archivo de configuración ===

cat > .copilot-project.yml <<EOF
# Configuración generada por bootstrap.sh — NO editar manualmente.
project:
  name: $PROJECT_NAME
  client: $CLIENT_NAME
  legacy_tech: $LEGACY_TECH
  legacy_lang: $LEGACY_LANG
  target_stack: $TARGET_STACK
  cloud_provider: $CLOUD_PROVIDER
  bootstrapped_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Modelos sugeridos por tipo de tarea (override por agente con frontmatter "model:")
models:
  default: Claude Sonnet 4.5
  assessment: Claude Sonnet 4.5     # alto volumen de lectura
  planning: Claude Opus 4.1         # decisiones / ADRs
  migration: Claude Opus 4.1        # razonamiento sobre código
  security: Claude Opus 4.1
  cloud_architecture: Claude Opus 4.1

# Convención de carpetas
paths:
  legacy: legacy/                   # código fuente legacy (read-only)
  modern: src/                      # código modernizado
  docs: docs/                       # outputs de assessment / planning
  assessment: assessment/           # outputs Fase 0 (md + html)
  migration: migration/             # tasks.md + plan.md por scenarioId
  cloud: cloud-architectures/       # arquitectura target Fase 4
EOF
info ".copilot-project.yml generado"

# === Crear carpeta legacy/ con README ===
mkdir -p legacy
if [[ ! -f legacy/README.md ]]; then
    cat > legacy/README.md <<'EOF'
# legacy/ — código fuente original (READ-ONLY)

Coloca aquí el código fuente legacy del cliente **sin modificarlo**. Los agentes lo leen pero nunca escriben sobre él.

## Reglas

1. **Solo lectura.** Toda modernización va en `src/` o en `migrated/`.
2. **No commitear secretos.** Limpia connection strings, API keys, credenciales antes de versionar.
3. **Respeta la estructura original** (.sln, .csproj, packages.config, Web.config). Los agentes la usan para clasificar.
4. **Anonimiza datos sensibles** en archivos de configuración o scripts SQL si aplica regulación.

## Estructura típica esperada

```
legacy/
├── <Solution>.sln          (.NET) o equivalente
├── src/                    código
├── tests/                  tests existentes
├── scripts/                BD, despliegue
└── config/                 web.config, app.config (anonimizados)
```

## Si el legacy no entra en el repo (>500MB, propietario, etc.)

Deja este README y un archivo `LEGACY_LOCATION.md` con:
- Ruta donde está el código (red interna, share, etc.)
- Cómo montarlo localmente
- Rama / commit / fecha del snapshot analizado
EOF
    info "legacy/README.md creado"
fi

# === Crear carpeta migration/ ===
mkdir -p migration

# === Crear carpeta src/ vacía para código moderno ===
mkdir -p src

read -rp "¿Eliminar este script de bootstrap? [s/N]: " DEL_BOOTSTRAP
if [[ "$DEL_BOOTSTRAP" =~ ^[sSyY]$ ]]; then
    rm -f bootstrap.sh bootstrap.ps1
    info "Scripts de bootstrap eliminados"
fi

echo
info "Bootstrap completado."
echo
echo "Pasos siguientes:"
echo "  1. Revisar los archivos generados (han sido personalizados)."
echo "  2. (Opcional) Iniciar con Fase 0 — Business Case:"
echo "       @business-case-analyst Construye el caso de negocio para $PROJECT_NAME"
echo "  3. Colocar el código legacy del cliente en la carpeta legacy/"
echo "  4. (Recomendado) Fase 0 — Assessment de seguridad whitehat:"
echo "       @security-assessor Revisa la seguridad del código en legacy/"
echo "     Outputs en assessment/$PROJECT_NAME/<categoria>-DDMMYYYY.{md,html}"
echo "  5. Abrir VS Code con Copilot Chat: code ."
if [[ "$LEGACY_TECH" == "vb" ]]; then
    echo "  6. Iniciar Fase 1 (Assessment):"
    echo "       @vb-assessment Analiza el sistema legacy/"
elif [[ "$LEGACY_TECH" == "dotnet-framework" ]]; then
    echo "  6. Iniciar Fase 1 (Assessment):"
    echo "       @dotnet-assessment Analiza el sistema legacy/"
    echo "     Luego: @dotnet-planning  →  @dotnet-migration"
else
    echo "  6. Para esta tecnología los agentes aún son placeholders."
    echo "     Crea los tuyos en .github/agents/$LEGACY_TECH/ usando los templates."
fi
echo "  7. Cuando el código esté modernizado, Fase 4 (Cloud):"
echo "       @cloud-architect Diseña la arquitectura cloud target en $CLOUD_PROVIDER"
echo
