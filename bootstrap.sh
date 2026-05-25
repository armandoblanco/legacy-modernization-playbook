#!/usr/bin/env bash
# Script de bootstrapping para adaptar la plantilla a tu proyecto.
# Reemplaza los placeholders del repo con valores especificos del proyecto del cliente.

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

info()    { echo -e "${GREEN}[info]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; }

if [[ ! -f "README.md" ]] || [[ ! -d ".github/agents" ]]; then
    error "Este script debe ejecutarse desde la raiz del repo de la plantilla."
    exit 1
fi

echo "================================================="
echo "  Bootstrap - plantilla de modernizacion legacy"
echo "================================================="
echo

read -rp "Nombre del proyecto (PascalCase, ej: SgapVc): " PROJECT_NAME
[[ -z "$PROJECT_NAME" ]] && { error "Nombre del proyecto es obligatorio."; exit 1; }

read -rp "Nombre del cliente: " CLIENT_NAME
[[ -z "$CLIENT_NAME" ]] && { error "Nombre del cliente es obligatorio."; exit 1; }

echo
echo "Tecnologia legacy a modernizar:"
echo "  1) vb                Visual Basic 6 o VB.NET (cobertura completa)"
echo "  2) dotnet-framework  .NET Framework 2.0-4.8 (cobertura completa)"
echo "  3) java              Java legacy: J2EE, Spring 3/4, Oracle Forms (cobertura completa)"
echo "  4) cobol             COBOL on mainframe / distributed (placeholder)"
echo "  5) python            Python 2 / 3 antiguo (placeholder)"
echo "  6) other             Otra (no se eliminara nada)"
read -rp "Elige [1-6]: " TECH_OPT
case "$TECH_OPT" in
    1) LEGACY_TECH="vb" ;;
    2) LEGACY_TECH="dotnet-framework" ;;
    3) LEGACY_TECH="java" ;;
    4) LEGACY_TECH="cobol" ;;
    5) LEGACY_TECH="python" ;;
    6) LEGACY_TECH="other" ;;
    *) error "Opcion invalida"; exit 1 ;;
esac

LEGACY_LANG=""
TARGET_STACK=""
JAVA_SUBSTACK=""

if [[ "$LEGACY_TECH" == "vb" ]]; then
    echo
    echo "Sub-lenguaje VB:"
    echo "  1) vb6     (Visual Basic 6, codigo .frm/.bas/.cls)"
    echo "  2) vbnet   (VB.NET legacy, .NET Framework 1.1-4.8)"
    read -rp "Elige [1-2]: " LANG_OPT
    case "$LANG_OPT" in
        1) LEGACY_LANG="vb6" ;;
        2) LEGACY_LANG="vbnet" ;;
        *) error "Opcion invalida"; exit 1 ;;
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
        *) error "Opcion invalida"; exit 1 ;;
    esac
fi

if [[ "$LEGACY_TECH" == "java" ]]; then
    echo
    echo "Sub-stack Java legacy:"
    echo "  1) j2ee           EJB 2.x/3.x, JSP, Servlets, WebLogic/WebSphere"
    echo "  2) spring-legacy  Spring 3.x/4.x con Struts, Java 6/7/8"
    echo "  3) oracle-forms   Oracle Forms (.fmb), PL/SQL embebido + en BD"
    read -rp "Elige [1-3]: " JAVA_OPT
    case "$JAVA_OPT" in
        1) JAVA_SUBSTACK="j2ee" ;;
        2) JAVA_SUBSTACK="spring-legacy" ;;
        3) JAVA_SUBSTACK="oracle-forms" ;;
        *) error "Opcion invalida"; exit 1 ;;
    esac
    LEGACY_LANG="$JAVA_SUBSTACK"
fi

echo
echo "Proveedor cloud objetivo (Fase 4):"
echo "  1) azure                Microsoft Azure (cobertura completa con @azure-architect)"
echo "  2) on-premise           on-premise / hibrido"
echo "  3) undecided            decidir despues (mantener placeholders)"
read -rp "Elige [1-3]: " CLOUD_OPT
case "$CLOUD_OPT" in
    1) CLOUD_PROVIDER="azure" ;;
    2) CLOUD_PROVIDER="on-premise" ;;
    3) CLOUD_PROVIDER="undecided" ;;
    *) error "Opcion invalida"; exit 1 ;;
esac

echo
info "Configuracion elegida:"
info "  Proyecto: $PROJECT_NAME"
info "  Cliente:  $CLIENT_NAME"
if [[ "$LEGACY_TECH" == "java" ]]; then
    info "  Legacy:   java/$JAVA_SUBSTACK"
else
    info "  Legacy:   $LEGACY_TECH${LEGACY_LANG:+/$LEGACY_LANG}"
fi
info "  Target:   ${TARGET_STACK:-(se decide en Fase 2 segun assessment)}"
info "  Cloud:    $CLOUD_PROVIDER"
echo
read -rp "Continuar? [s/N]: " CONFIRM
[[ ! "$CONFIRM" =~ ^[sSyY]$ ]] && { warn "Cancelado por el usuario."; exit 0; }

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

info "Copiando agentes a .github/agents/ plano..."

for agent_file in .github/agents/shared/*.agent.md; do
    [[ -f "$agent_file" ]] && cp "$agent_file" .github/agents/ 2>/dev/null || true
done

case "$LEGACY_TECH" in
    vb)
        for agent_file in .github/agents/vb/*.agent.md; do
            [[ -f "$agent_file" ]] && cp "$agent_file" .github/agents/ 2>/dev/null || true
        done
        info "  Copiados: agentes VB (3) + compartidos"
        ;;
    dotnet-framework)
        for agent_file in .github/agents/dotnet-framework/*.agent.md; do
            [[ -f "$agent_file" ]] && cp "$agent_file" .github/agents/ 2>/dev/null || true
        done
        info "  Copiados: agentes .NET Framework (3) + compartidos"
        ;;
    java)
        for phase in assessment planning migration; do
            src=".github/agents/java/${JAVA_SUBSTACK}-${phase}.agent.md"
            if [[ -f "$src" ]]; then
                cp "$src" ".github/agents/${JAVA_SUBSTACK}-${phase}.agent.md"
            else
                warn "  No encontrado: $src"
            fi
        done
        info "  Copiados: agentes $JAVA_SUBSTACK (3) + compartidos"
        ;;
esac

read -rp "Eliminar contenido de OTRAS tecnologias legacy (recomendado para repos de cliente)? [s/N]: " DEL_OTHER_TECH
if [[ "$DEL_OTHER_TECH" =~ ^[sSyY]$ ]] && [[ "$LEGACY_TECH" != "other" ]]; then
    for tech in vb dotnet-framework cobol java python; do
        if [[ "$tech" != "$LEGACY_TECH" ]]; then
            rm -rf "docs/technologies/$tech" 2>/dev/null || true
            rm -rf ".github/agents/$tech" 2>/dev/null || true
            rm -rf ".github/prompts/$tech" 2>/dev/null || true
            rm -rf ".github/instructions/${tech}-target" 2>/dev/null || true
            rm -rf "workshop/$tech" 2>/dev/null || true
        fi
    done

    if [[ "$LEGACY_TECH" == "java" ]]; then
        rm -rf ".github/agents/java" 2>/dev/null || true
    fi

    rm -rf ".github/agents/shared" 2>/dev/null || true

    if [[ "$LEGACY_TECH" != "dotnet-framework" ]]; then
        rm -f "docs/QUICKSTART-dotnet.md" 2>/dev/null || true
    fi
    if [[ "$LEGACY_TECH" != "java" ]]; then
        rm -f "docs/QUICKSTART-java.md" 2>/dev/null || true
    fi

    info "  Carpetas de otras tecnologias eliminadas"
fi

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

if [[ "$CLOUD_PROVIDER" != "undecided" ]]; then
    read -rp "Eliminar carpetas de OTROS proveedores cloud no elegidos? [s/N]: " DEL_OTHER_CLOUD
    if [[ "$DEL_OTHER_CLOUD" =~ ^[sSyY]$ ]]; then
        for prov in azure on-premise; do
            if [[ "$prov" != "$CLOUD_PROVIDER" ]]; then
                rm -rf "cloud-architectures/$prov" 2>/dev/null || true
            fi
        done
        info "  Carpetas de otros proveedores cloud eliminadas"
    fi
fi

cat > .copilot-project.yml <<EOF
# Configuracion generada por bootstrap.sh - NO editar manualmente.
project:
  name: $PROJECT_NAME
  client: $CLIENT_NAME
  legacy_tech: $LEGACY_TECH
  legacy_lang: $LEGACY_LANG
  java_substack: $JAVA_SUBSTACK
  target_stack: $TARGET_STACK
  cloud_provider: $CLOUD_PROVIDER
  bootstrapped_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

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
EOF
info ".copilot-project.yml generado"

mkdir -p legacy
if [[ ! -f legacy/README.md ]]; then
    cat > legacy/README.md <<'EOFLEGACY'
# legacy/ - codigo fuente original (READ-ONLY)

Coloca aqui el codigo fuente legacy del cliente **sin modificarlo**. Los agentes lo leen pero nunca escriben sobre el.

## Reglas

1. **Solo lectura.** Toda modernizacion va en `src/`.
2. **No commitear secretos.** Limpia connection strings, API keys, credenciales antes de versionar.
3. **Respeta la estructura original** (.sln, .csproj, pom.xml, descriptores XML, packages.config).
4. **Anonimiza datos sensibles** en archivos de configuracion o scripts SQL.

## Si el legacy no entra en el repo

Deja este README y un archivo `LEGACY_LOCATION.md` con ruta del codigo, como montarlo, y rama/commit/fecha del snapshot.
EOFLEGACY
    info "legacy/README.md creado"
fi

mkdir -p migration
mkdir -p src

read -rp "Eliminar este script de bootstrap? [s/N]: " DEL_BOOTSTRAP
if [[ "$DEL_BOOTSTRAP" =~ ^[sSyY]$ ]]; then
    rm -f bootstrap.sh bootstrap.ps1
    info "Scripts de bootstrap eliminados"
fi

echo
info "Bootstrap completado."
echo
echo "Pasos siguientes:"
echo "  1. Revisar los archivos generados."
echo "  2. (Opcional) Fase 0 - Business Case:"
echo "       @business-case-analyst Construye el caso de negocio para $PROJECT_NAME"
echo "  3. Colocar el codigo legacy del cliente en la carpeta legacy/"
echo "  4. (Recomendado) Fase 0 - Assessment de seguridad whitehat:"
echo "       @security-assessor Revisa la seguridad del codigo en legacy/"
echo "  5. Abrir VS Code con Copilot Chat: code ."
case "$LEGACY_TECH" in
    vb)
        echo "  6. Iniciar Fase 1 (Assessment):"
        echo "       @vb-assessment Analiza el sistema en legacy/"
        echo "     Luego: @vb-planning  ->  @vb-migration"
        ;;
    dotnet-framework)
        echo "  6. Iniciar Fase 1 (Assessment):"
        echo "       @dotnet-assessment Analiza el sistema en legacy/"
        echo "     Luego: @dotnet-planning  ->  @dotnet-migration"
        ;;
    java)
        echo "  6. Iniciar Fase 1 (Assessment):"
        echo "       @${JAVA_SUBSTACK}-assessment Analiza el sistema en legacy/"
        echo "     Luego: @${JAVA_SUBSTACK}-planning  ->  @${JAVA_SUBSTACK}-migration"
        if [[ "$JAVA_SUBSTACK" == "oracle-forms" ]]; then
            echo
            echo "     Nota: Oracle Forms requiere extraer .fmb a XML antes del assessment."
            echo "     Ver docs/technologies/java/03-trampas-oracle-forms.md"
        fi
        ;;
    *)
        echo "  6. Para esta tecnologia los agentes aun son placeholders."
        echo "     Crea los tuyos en .github/agents/$LEGACY_TECH/ usando los templates."
        ;;
esac
if [[ "$CLOUD_PROVIDER" == "azure" ]]; then
    echo "  7. Cuando el codigo este modernizado, Fase 4 (Cloud Azure):"
    echo "       @azure-architect Disena la arquitectura cloud target en Azure"
elif [[ "$CLOUD_PROVIDER" == "on-premise" ]]; then
    echo "  7. Cuando el codigo este modernizado, Fase 4 (on-premise):"
    echo "       Revisar cloud-architectures/on-premise/ para patrones aplicables"
fi
echo
