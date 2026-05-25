================================================================================
PATCH: AGREGAR SUB-STACK JAVA A BOOTSTRAP.SH Y BOOTSTRAP.PS1
================================================================================

Este patch agrega soporte para los 3 sub-stacks Java (j2ee, spring-legacy,
oracle-forms) al bootstrap interactivo. NO modifica la lógica existente de
VB6/VBNet/.NET Framework — solo agrega ramas paralelas.

ASUMIENDO que la sesión anterior ya tiene el fix de discovery que copia
agentes a `.github/agents/` flat (no a subcarpetas), este patch agrega:

1. Pregunta de sub-stack Java cuando LEGACY_TECH=java
2. Variable JAVA_SUBSTACK con valores: j2ee | spring-legacy | oracle-forms
3. Reescritura del paso de copia flat para que solo copie los 3 agentes
   del sub-stack Java elegido (no los 9)
4. Mensaje final al usuario con instrucción de invocación correcta
   (`@j2ee-assessment` vs `@spring-legacy-assessment` vs `@oracle-forms-assessment`)


================================================================================
PATCH 1 — bootstrap.sh
================================================================================

INSERTAR DESPUÉS DEL BLOQUE DE SELECCIÓN VB (línea ~90, después del `fi`
que cierra el `if [[ "$LEGACY_TECH" == "vb" ]]`):

```bash
JAVA_SUBSTACK=""
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
        *) error "Opción inválida"; exit 1 ;;
    esac
    # Reusa LEGACY_LANG para mantener compatibilidad con scripts existentes
    LEGACY_LANG="$JAVA_SUBSTACK"
fi
```


MODIFICAR la sección de info para incluir JAVA_SUBSTACK:

Cambiar:
```bash
info "  Legacy:   $LEGACY_TECH${LEGACY_LANG:+/$LEGACY_LANG}"
```

por:
```bash
if [[ "$LEGACY_TECH" == "java" ]]; then
    info "  Legacy:   java/$JAVA_SUBSTACK"
else
    info "  Legacy:   $LEGACY_TECH${LEGACY_LANG:+/$LEGACY_LANG}"
fi
```


AGREGAR EN LA SECCIÓN DE COPIA DE AGENTES A FLAT (la que la sesión anterior
agregó como fix de discovery). Si la sesión anterior tiene una función
`copy_agents_flat()` o un bloque que copia de `.github/agents/<tech>/` a
`.github/agents/`, hay que agregar el caso Java:

```bash
# === Copiar agentes Java del sub-stack elegido (solo si LEGACY_TECH=java) ===

if [[ "$LEGACY_TECH" == "java" ]]; then
    info "Copiando agentes Java del sub-stack $JAVA_SUBSTACK a .github/agents/ flat..."

    # Solo copiar los 3 del sub-stack elegido, no los 9
    for phase in assessment planning migration; do
        src=".github/agents/java/${JAVA_SUBSTACK}-${phase}.agent.md"
        dest=".github/agents/${JAVA_SUBSTACK}-${phase}.agent.md"
        if [[ -f "$src" ]]; then
            cp "$src" "$dest"
            info "  Copiado: $(basename $dest)"
        else
            warn "  No encontrado: $src"
        fi
    done

    # Después de copiar, eliminar la subcarpeta java/ para evitar duplicación
    # (los agentes no elegidos del sub-stack contrario tampoco deben quedar)
    if [[ "$DEL_OTHER_TECH" =~ ^[sSyY]$ ]]; then
        rm -rf ".github/agents/java" 2>/dev/null || true
        info "  Subcarpeta .github/agents/java/ eliminada (agentes ya están en flat)"
    fi
fi
```


MODIFICAR EL MENSAJE FINAL para Java:

En la sección donde se imprime "Pasos siguientes", agregar antes del else final:

```bash
elif [[ "$LEGACY_TECH" == "java" ]]; then
    echo "  6. Iniciar Fase 1 (Assessment):"
    echo "       @${JAVA_SUBSTACK}-assessment Analiza el sistema legacy/"
    case "$JAVA_SUBSTACK" in
        j2ee)
            echo "     Luego: @j2ee-planning  →  @j2ee-migration"
            ;;
        spring-legacy)
            echo "     Luego: @spring-legacy-planning  →  @spring-legacy-migration"
            ;;
        oracle-forms)
            echo "     Luego: @oracle-forms-planning  →  @oracle-forms-migration"
            echo "     Nota: Oracle Forms requiere extraer .fmb a XML antes del assessment."
            echo "     Ver docs/technologies/java/03-trampas-oracle-forms.md"
            ;;
    esac
```


MODIFICAR EL ARCHIVO .copilot-project.yml GENERADO para incluir JAVA_SUBSTACK:

En el heredoc `cat > .copilot-project.yml`, agregar después de `legacy_lang`:

```yaml
  java_substack: $JAVA_SUBSTACK
```

(Solo aplica si LEGACY_TECH=java, queda vacío para otros tech.)


================================================================================
PATCH 2 — bootstrap.ps1
================================================================================

EQUIVALENTE PowerShell. Insertar después del bloque VB:

```powershell
$JavaSubstack = ""
if ($LegacyTech -eq "java") {
    Write-Host ""
    Write-Host "Sub-stack Java legacy:"
    Write-Host "  1) j2ee           EJB 2.x/3.x, JSP, Servlets, WebLogic/WebSphere"
    Write-Host "  2) spring-legacy  Spring 3.x/4.x con Struts, Java 6/7/8"
    Write-Host "  3) oracle-forms   Oracle Forms (.fmb), PL/SQL embebido + en BD"
    $JavaOpt = Read-Host "Elige [1-3]"
    switch ($JavaOpt) {
        "1" { $JavaSubstack = "j2ee" }
        "2" { $JavaSubstack = "spring-legacy" }
        "3" { $JavaSubstack = "oracle-forms" }
        default { Write-Error "Opción inválida"; exit 1 }
    }
    $LegacyLang = $JavaSubstack
}
```

Sección de copia flat:

```powershell
if ($LegacyTech -eq "java") {
    Write-Host "Copiando agentes Java del sub-stack $JavaSubstack a .github/agents/ flat..."

    foreach ($phase in @("assessment", "planning", "migration")) {
        $src = ".github/agents/java/${JavaSubstack}-${phase}.agent.md"
        $dest = ".github/agents/${JavaSubstack}-${phase}.agent.md"
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dest
            Write-Host "  Copiado: $(Split-Path $dest -Leaf)"
        } else {
            Write-Warning "  No encontrado: $src"
        }
    }

    if ($DelOtherTech -match "^[sSyY]$") {
        Remove-Item -Path ".github/agents/java" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Subcarpeta .github/agents/java/ eliminada"
    }
}
```

Mensaje final:

```powershell
} elseif ($LegacyTech -eq "java") {
    Write-Host "  6. Iniciar Fase 1 (Assessment):"
    Write-Host "       @${JavaSubstack}-assessment Analiza el sistema legacy/"
    switch ($JavaSubstack) {
        "j2ee" {
            Write-Host "     Luego: @j2ee-planning  ->  @j2ee-migration"
        }
        "spring-legacy" {
            Write-Host "     Luego: @spring-legacy-planning  ->  @spring-legacy-migration"
        }
        "oracle-forms" {
            Write-Host "     Luego: @oracle-forms-planning  ->  @oracle-forms-migration"
            Write-Host "     Nota: Oracle Forms requiere extraer .fmb a XML antes del assessment."
            Write-Host "     Ver docs/technologies/java/03-trampas-oracle-forms.md"
        }
    }
```


================================================================================
NOTAS IMPORTANTES PARA APLICAR EL PATCH
================================================================================

1. **Si la sesión anterior NO modificó bootstrap.sh con el fix de discovery flat:**
   - Primero aplicar el fix anterior (copia de agentes a `.github/agents/` plano)
   - Después aplicar este patch
   - Sin el fix anterior, los agentes Java en `.github/agents/java/` NO serán
     descubiertos por Copilot

2. **Los 9 agentes Java viven bajo `.github/agents/java/`** con nombres:
   - j2ee-{assessment,planning,migration}.agent.md
   - spring-legacy-{assessment,planning,migration}.agent.md
   - oracle-forms-{assessment,planning,migration}.agent.md

3. **El bootstrap copia SOLO 3 agentes** del sub-stack elegido + los shared
   (`plan-refiner`, `modernization-strategy`, `migration-tester`) que ya copia
   por default. Total: 6 agentes en el dropdown de Copilot.

4. **Los 3 sub-stacks Java son mutuamente excluyentes** en un proyecto dado.
   Si el cliente tiene sistemas mixtos, hacer 2 instancias del bootstrap
   en directorios separados.
