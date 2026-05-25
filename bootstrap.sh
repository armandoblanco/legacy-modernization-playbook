#!/usr/bin/env bash
# Script de bootstrapping para adaptar la plantilla a tu proyecto.
# Reemplaza placeholders, copia los agentes relevantes a .github/agents/ flat (requisito de Copilot)
# y genera NEXT-STEPS.md con la guía completa de uso post-bootstrap.
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
#
# IMPORTANTE: este script NO se auto-elimina. Quédate con él para re-ejecutarlo si necesitas
# cambiar la configuración del proyecto.

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info()    { echo -e "${GREEN}[info]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; }
step()    { echo -e "${BLUE}[paso]${NC} $*"; }

if [[ ! -f "README.md" ]] || [[ ! -d ".github/agents" ]]; then
    error "Este script debe ejecutarse desde la raíz del repo de la plantilla."
    exit 1
fi

echo "================================================="
echo "  Bootstrap — plantilla de modernización legacy"
echo "================================================="
echo
echo "Este script:"
echo "  1. Pregunta por la configuración de tu proyecto"
echo "  2. Reemplaza placeholders en archivos Markdown"
echo "  3. Copia los agentes Copilot relevantes a .github/agents/ (flat — Copilot no lee subcarpetas)"
echo "  4. Limpia carpetas de tecnologías/clouds no elegidos (opcional)"
echo "  5. Genera NEXT-STEPS.md con la guía de uso completa"
echo
echo "El script NO se elimina al terminar. Puedes re-ejecutarlo si cambias de opinión."
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
echo "Proveedor cloud objetivo (Fase 6):"
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

step "Aplicando reemplazos en archivos Markdown..."

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

# === FIX CRÍTICO: copiar agentes a .github/agents/ flat ===
#
# GitHub Copilot (VS Code, Visual Studio, Copilot CLI) NO descubre agentes en subcarpetas
# de .github/agents/. Solo lee archivos .agent.md directamente bajo .github/agents/.
# Esto está documentado en issues abiertos del repo github/copilot-cli (#1859, #2245, #1506).
#
# Este paso copia los agentes shared + los de la tecnología elegida al nivel flat
# para que Copilot los descubra. Los originales en subcarpetas se mantienen como referencia.

step "Copiando agentes Copilot relevantes a .github/agents/ (requisito de discovery)..."

# Agentes compartidos: SIEMPRE se copian
SHARED_AGENTS_DIR=".github/agents/shared"
if [[ -d "$SHARED_AGENTS_DIR" ]]; then
    for agent in "$SHARED_AGENTS_DIR"/*.agent.md; do
        [[ -f "$agent" ]] || continue
        cp "$agent" ".github/agents/$(basename "$agent")"
        info "  Copiado: $(basename "$agent") (shared)"
    done
fi

# Agentes específicos de la tecnología elegida
if [[ -d ".github/agents/$LEGACY_TECH" ]]; then
    for agent in ".github/agents/$LEGACY_TECH"/*.agent.md; do
        [[ -f "$agent" ]] || continue
        cp "$agent" ".github/agents/$(basename "$agent")"
        info "  Copiado: $(basename "$agent") ($LEGACY_TECH)"
    done
elif [[ "$LEGACY_TECH" != "other" ]]; then
    warn "  No hay agentes para '$LEGACY_TECH' aún. Crea los tuyos en .github/agents/$LEGACY_TECH/"
    warn "  y vuelve a correr este script. Ver .github/agents/_templates/"
fi

# Validación: confirmar que al menos UN .agent.md quedó en el nivel flat
AGENT_COUNT=$(find .github/agents -maxdepth 1 -name "*.agent.md" -type f | wc -l | tr -d ' ')
if [[ "$AGENT_COUNT" -eq 0 ]]; then
    error "Ningún agente quedó en .github/agents/ flat. Copilot no descubrirá agentes."
    error "Revisa que las subcarpetas .github/agents/shared/ y .github/agents/$LEGACY_TECH/ tengan archivos .agent.md."
    exit 1
fi
info "  Total de agentes descubribles por Copilot: $AGENT_COUNT"

# === Limpieza de tecnologías no elegidas (opcional) ===

echo
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
  default: Claude Sonnet 4.6
  assessment: Claude Opus 4.6       # razonamiento profundo en análisis de código
  planning: Claude Opus 4.6         # decisiones / ADRs
  plan_refinement: Claude Opus 4.6  # diálogo con usuario para ajustar scope
  migration: Claude Sonnet 4.6      # velocidad + precisión en transformaciones
  testing: Claude Sonnet 4.6        # generación y ejecución de tests
  security: Claude Opus 4.6
  cloud_architecture: Claude Opus 4.6
  modernization_strategy: Claude Opus 4.6  # 6R's framework + path advisory

# Convención de carpetas
paths:
  legacy: legacy/                   # código fuente legacy (read-only)
  modern: src/                      # código modernizado
  docs: docs/                       # outputs de assessment / planning
  assessment: assessment/           # outputs Fase 0 (md + html)
  migration: migration/             # tasks.md + plan.md por scenarioId
  testing: testing/                 # outputs de Fase 5 (cobertura, parity reports)
  cloud: cloud-architectures/       # arquitectura target Fase 6
EOF
info ".copilot-project.yml generado"

# === Crear carpetas de trabajo ===
mkdir -p legacy src migration testing "assessment/$PROJECT_NAME" docs/adr docs/features

if [[ ! -f legacy/README.md ]]; then
    cat > legacy/README.md <<'EOF'
# legacy/ — código fuente original (READ-ONLY)

Coloca aquí el código fuente legacy del cliente **sin modificarlo**. Los agentes lo leen pero nunca escriben sobre él.

## Reglas

1. **Solo lectura.** Toda modernización va en `src/`.
2. **No commitear secretos.** Limpia connection strings, API keys, credenciales antes de versionar.
3. **Respeta la estructura original** (.sln, .csproj, packages.config, Web.config). Los agentes la usan para clasificar.
4. **Anonimiza datos sensibles** en archivos de configuración o scripts SQL si aplica regulación.
EOF
    info "legacy/README.md creado"
fi

# === Generar NEXT-STEPS.md persistente ===
#
# Este archivo queda en el repo para que el usuario pueda consultar la guía completa
# en cualquier momento, no solo al ejecutar el bootstrap.

step "Generando NEXT-STEPS.md con la guía completa de uso..."

# Extraer los nombres reales de los agentes desde el frontmatter (campo name:),
# no del filename (el filename puede tener prefijo numérico de orden).
AGENT_LIST=$(
    for f in .github/agents/*.agent.md; do
        [[ -f "$f" ]] || continue
        awk '
            /^---[[:space:]]*$/ { n++; if (n==2) exit; next }
            n==1 && /^name:/ {
                sub(/^name:[[:space:]]*/, "")
                gsub(/["'\'']/, "")
                gsub(/[[:space:]]+$/, "")
                print "   - @" $0
                exit
            }
        ' "$f"
    done | sort -u
)

cat > NEXT-STEPS.md <<EOF
# Siguientes pasos para $PROJECT_NAME

Generado por bootstrap.sh el $(date -u +"%Y-%m-%d %H:%M:%S UTC").

> Este archivo persiste en el repo. Consúltalo cuando necesites recordar el flujo.

---

## Configuración aplicada

- **Proyecto:** $PROJECT_NAME
- **Cliente:** $CLIENT_NAME
- **Tecnología legacy:** $LEGACY_TECH${LEGACY_LANG:+ ($LEGACY_LANG)}
- **Stack target:** ${TARGET_STACK:-(no aplica)}
- **Cloud provider:** $CLOUD_PROVIDER

---

## Validación del entorno antes de empezar

Antes de invocar cualquier agente:

1. Abre VS Code en este directorio: \`code .\`
2. Asegúrate de tener la extensión GitHub Copilot Chat instalada y activa
3. En Copilot Chat, escribe \`@\` y verifica que aparezcan los agentes:

\`\`\`
${AGENT_LIST}
\`\`\`

**Si no aparecen**, ejecuta: \`Cmd/Ctrl+Shift+P\` → "Developer: Reload Window"

---

## Flujo completo de modernización (7 fases)

### Fase 0 — Business Case (¿conviene modernizar?)

\`\`\`
@business-case-analyst Construye el caso de negocio para $PROJECT_NAME
\`\`\`

**Entregables:** \`assessment/$PROJECT_NAME/{tco-actual,roi,riesgo,ejecutivo}-DDMMYYYY.{md,html}\`

Y assessment de seguridad whitehat:
\`\`\`
@security-assessor Revisa la seguridad del código en legacy/
\`\`\`

---

### Fase 1 — Assessment (¿qué tiene el legacy?)

Coloca primero el código legacy del cliente:
\`\`\`bash
cp -r /ruta/al/codigo-legacy/* legacy/
\`\`\`

Luego invoca:
EOF

if [[ "$LEGACY_TECH" == "vb" ]]; then
    cat >> NEXT-STEPS.md <<EOF
\`\`\`
@vb-assessment Analiza el sistema en legacy/
\`\`\`
EOF
elif [[ "$LEGACY_TECH" == "dotnet-framework" ]]; then
    cat >> NEXT-STEPS.md <<EOF
\`\`\`
@dotnet-assessment Analiza el sistema en legacy/
\`\`\`
EOF
else
    cat >> NEXT-STEPS.md <<EOF
\`\`\`
# Para $LEGACY_TECH los agentes aún son placeholders.
# Crea los tuyos en .github/agents/$LEGACY_TECH/ usando templates en .github/agents/_templates/
# y re-ejecuta ./bootstrap.sh para que se copien al nivel flat.
\`\`\`
EOF
fi

cat >> NEXT-STEPS.md <<EOF

**Entregables:** \`docs/features/\` con un .md por feature funcional + grafo de dependencias.

---

### Fase 2 — Planning (¿hacia dónde y por qué?)

EOF

if [[ "$LEGACY_TECH" == "vb" ]]; then
    cat >> NEXT-STEPS.md <<EOF
\`\`\`
@vb-planning
\`\`\`
EOF
elif [[ "$LEGACY_TECH" == "dotnet-framework" ]]; then
    cat >> NEXT-STEPS.md <<EOF
\`\`\`
@dotnet-planning
\`\`\`
EOF
fi

cat >> NEXT-STEPS.md <<EOF

**Entregables:** \`docs/ARQUITECTURA-TARGET.md\` + ADRs en \`docs/adr/\`.

---

### Fase 2.5 — Plan Refinement (ajustar scope con el usuario)

**Nuevo agente colaborativo.** Trabaja CONTIGO para refinar el plan: features muertos
que no se migran, código que el cliente abandonó, ambigüedades del plan, scope reducido
vs scope total.

\`\`\`
@plan-refiner Revisa el plan de migración conmigo para ajustar scope
\`\`\`

**Entregable:** \`docs/MIGRATION-SCOPE.md\` con scope final acordado + features descartados con justificación.

---

### Fase 3 — Modernization Strategy (¿qué patrón de modernización?)

Decide entre las 6 R's de Gartner (Rehost / Replatform / Refactor / Rearchitect / Rebuild / Retire)
y, si es app Windows desktop, propone path específico a web/contenedor/k8s.

\`\`\`
@modernization-strategy Recomienda path de modernización para $PROJECT_NAME
\`\`\`

**Entregable:** \`docs/MODERNIZATION-PATH.md\` con la 6R elegida + arquitectura conceptual target.

---

### Fase 4 — Execution (construir)

EOF

if [[ "$LEGACY_TECH" == "vb" ]]; then
    cat >> NEXT-STEPS.md <<EOF
\`\`\`
@vb-migration Migra el sistema según los ADRs aprobados
\`\`\`
EOF
elif [[ "$LEGACY_TECH" == "dotnet-framework" ]]; then
    cat >> NEXT-STEPS.md <<EOF
\`\`\`
@dotnet-migration Migra el sistema según los ADRs aprobados
\`\`\`
EOF
fi

cat >> NEXT-STEPS.md <<EOF

**Entregable:** código modernizado en \`src/\` con paridad funcional vs legacy/.

---

### Fase 5 — Testing & QA (validar que funciona)

**Nuevo agente.** Genera tests de paridad sistemáticos, valida cobertura, corre los tests y reporta gaps.

\`\`\`
@migration-tester Genera y ejecuta tests de paridad para el código en src/
\`\`\`

**Entregables:**
- \`testing/parity-report.md\` con tabla de paridad por feature
- \`testing/coverage-report.md\` con cobertura por capa
- Tests unitarios + integración en \`tests/\` o equivalente del stack elegido

---

### Fase 6 — Cloud Deployment (¿dónde corre?)

\`\`\`
@cloud-architect Diseña la arquitectura cloud target en $CLOUD_PROVIDER
\`\`\`

EOF

if [[ "$CLOUD_PROVIDER" == "azure" ]]; then
    cat >> NEXT-STEPS.md <<EOF
Para Azure específicamente (con precios validados vía Retail Prices API):
\`\`\`
@azure-architect Diseña arquitectura Azure para $PROJECT_NAME
\`\`\`

EOF
fi

cat >> NEXT-STEPS.md <<EOF
**Entregable:** \`cloud-architectures/$CLOUD_PROVIDER/\` con diagramas Mermaid + IaC sugerido.

---

## Re-ejecutar el bootstrap

Si necesitas cambiar la configuración (otro stack target, otro cloud, etc.), puedes re-ejecutar:

\`\`\`bash
./bootstrap.sh
\`\`\`

El script es idempotente para los reemplazos de placeholders (solo aplica si existen).
Para limpiar primero y empezar desde cero, vuelve a clonar el repo.

---

## Troubleshooting

### Los agentes no aparecen en Copilot Chat con \`@\`

1. Verifica que los \`.agent.md\` estén en \`.github/agents/\` (NO en subcarpetas):
   \`\`\`bash
   ls .github/agents/*.agent.md
   \`\`\`
2. Recarga VS Code: \`Cmd/Ctrl+Shift+P\` → "Developer: Reload Window"
3. Verifica que tu plan de Copilot soporta agentes personalizados (Business, Enterprise, o individual con acceso).

### El bootstrap dejó archivos sobrantes en subcarpetas

Es intencional. Los originales en \`.github/agents/<tech>/\` y \`.github/agents/shared/\` se mantienen
como referencia. Copilot solo lee las copias en el nivel flat.

Si quieres limpiar las subcarpetas para reducir ruido visual en el repo:
\`\`\`bash
rm -rf .github/agents/shared .github/agents/$LEGACY_TECH
\`\`\`

### Quiero agregar un agente custom

1. Crea el archivo en \`.github/agents/mi-agente.agent.md\` directamente (no en subcarpeta).
2. Sigue el formato del frontmatter de los agentes existentes.
3. Recarga VS Code.
EOF

info "NEXT-STEPS.md generado"

# === Mensaje final en pantalla ===

echo
echo "======================================================"
info "Bootstrap completado."
echo "======================================================"
echo
echo "Próximos pasos (también guardados en NEXT-STEPS.md):"
echo
step "1. Verifica los agentes Copilot descubribles:"
echo "      ls .github/agents/*.agent.md"
echo
step "2. Coloca el código legacy del cliente:"
echo "      cp -r /ruta/al/codigo-legacy/* legacy/"
echo
step "3. Abre VS Code y verifica los agentes con @ en Copilot Chat:"
echo "      code ."
echo
step "4. Inicia el flujo de modernización en orden (7 fases)."
echo "      Lee NEXT-STEPS.md para el detalle completo de cada fase."
echo
echo "El script bootstrap.sh y bootstrap.ps1 NO se eliminaron."
echo "Puedes re-ejecutarlos si necesitas cambiar la configuración."
echo
