# Lab 01: Assessment de un sistema VB6

**Pre-requisitos:** Repositorio con código VB6 + GitHub Copilot Chat habilitado + agentes instalados en `.github/agents/`

---

## Objetivo

Al terminar este lab, vas a tener:

1. Un assessment completo de un sistema VB6 en `docs/features/`
2. Un inventario clasificado de OCX en `docs/cross-cuttings/ocx-inventory.md`
3. Un grafo de dependencias entre features
4. Un `SUMMARY.md` ejecutivo

Y vas a haber experimentado:

- Cómo Copilot lee código VB6 cuando le das contexto explícito
- Por qué la documentación del cliente miente
- Cómo extraer reglas de negocio desde el código fuente
- Cómo clasificar OCX por nivel de riesgo

---

## Setup

### Opción A: Tu propio sistema VB6

Si tienes acceso a un sistema VB6 real (de tu cliente, de un proyecto pasado), úsalo. Es el escenario más realista.

```bash
cd /ruta/al/proyecto-vb6
# Asegúrate de que el código VB6 esté ahí
ls *.vbp *.vbg *.frm *.bas *.cls 2>/dev/null
# Copiar agentes y prompts del workshop
mkdir -p .github
cp -r /ruta/al/workshop/.github/* .github/
# Abrir en VS Code
code .
```

### Opción B: Sistema de ejemplo público

Si no tienes un sistema VB6 a mano, hay repos públicos para practicar. Algunos sugeridos:

- [Northwind Visual Basic 6 Sample](https://github.com/microsoft/Northwind-Visual-Basic-6) (Microsoft, propósito educativo)
- Tu propio repo personal con código VB6 antiguo

Clona, agrega los agentes, abre en VS Code.

### Opción C: Crear un mini sistema sintético

Si no consigues nada, este es un Plan B. Crear un mini sistema VB6 pequeño:

```
mini-sistema-vb6/
├── MiniSistema.vbp
├── modAuth.bas              (10 procedimientos de auth)
├── modDB.bas                (acceso a BD)
├── frmLogin.frm             (form de login)
├── frmMain.frm              (form principal MDI)
└── clsCliente.cls           (clase de dominio)
```

Es menos didáctico (ningún sistema real es así de limpio) pero sirve para entender el flujo.

---

## Paso 1: Verificar instalación de agentes

Abre VS Code, abre Copilot Chat, escribe `@`. Deberías ver:

- `@vb6-assessment` (o el nombre que VS Code asignó al agente `01-vb6-assessment.agent.md`)
- `@vb6-planning`
- `@vb6-migration`

Si no aparecen:

1. Verifica que los archivos estén en `.github/agents/` del workspace abierto
2. Recarga la ventana: `Cmd+Shift+P` → "Developer: Reload Window"
3. Verifica permisos de Copilot (algunos planes no soportan agentes custom)

**Checkpoint del lab:** confirma con tu equipo que ven los 3 agentes antes de seguir.

---

## Paso 2: Inventario inicial

Antes de invocar el agente, conoce manualmente lo que vas a darle:

```bash
# Cuenta archivos VB6
find . -name "*.frm" | wc -l
find . -name "*.bas" | wc -l
find . -name "*.cls" | wc -l

# Cuenta líneas (aproximado)
find . -name "*.frm" -o -name "*.bas" -o -name "*.cls" | xargs wc -l
```

**Anota estos números.** Vas a verificar que el agente los reproduzca correctamente. Si dice que hay 50 archivos y tú contaste 47, algo se le escapó.

---

## Paso 3: Invocar el agente de assessment

En Copilot Chat:

```
@vb6-assessment Analiza el sistema VB6 en este repositorio. 
Genera el assessment completo en docs/.
```

El agente debe:

1. Listar archivos y reportar el inventario inicial
2. Proponer un clustering en features
3. **Pausar para que valides el clustering** antes de profundizar

**Si el agente NO pausa** y empieza a generar todos los `.md` de features de inmediato:
- Es señal de que el agente está mal configurado
- O el modelo está siendo demasiado proactivo
- Detenlo manualmente con `/stop` y di: "Primero muéstrame el inventario y el clustering propuesto, sin generar features todavía"

---

## Paso 4: Validar el clustering propuesto

Cuando el agente proponga clustering tipo:

```
## Features candidatos
1. autenticacion (frmLogin.frm, modAuth.bas, modSession.bas)
2. clientes (frmCliente.frm, clsCliente.cls, modClientes.bas)
3. ventas (frmVenta.frm, modVentas.bas, ...)
...

## Cross-cuttings
- modDB.bas (todos lo usan)
- modLog.bas (todos lo usan)
```

**Tu trabajo:**

1. ¿El clustering tiene sentido para alguien que conoce el sistema?
2. ¿Falta algún feature obvio?
3. ¿Hay archivos huérfanos no asignados?
4. ¿Los cross-cuttings son realmente cross-cutting o son features aparte?

Si algo no cuadra, di:

```
El feature "ventas" está mezclando dos cosas: registro de ventas 
y reportería. Sepáralos: 
- ventas-registro: frmVenta.frm, modVentas.bas
- ventas-reportes: frmReportes.frm, modReportes.bas
Regenera el clustering.
```

**Lección práctica:** El agente no entiende dominio. Tu job de SE/arquitecto es validar el clustering. Esta es la parte que la IA NO va a hacer bien sola.

---

## Paso 5: Generar features uno a uno

Una vez validado el clustering, pídele al agente:

```
@vb6-assessment Genera docs/features/01-autenticacion.md siguiendo el template.
```

Revisa el output. Cosas a validar:

### 5.1 Reglas de negocio explícitas

Cada regla debe citar archivo y líneas:

```markdown
1. **Bloqueo por intentos fallidos**: 3 intentos en 5 min bloquean por 15 min.
   Origen: modAuth.bas L142-L168.
```

**Tu validación:** abre `modAuth.bas`, ve a las líneas 142-168, verifica que la regla extraída sea correcta.

### 5.2 Reglas implícitas

Estas son las más interesantes:

```markdown
1. **Password se almacena en hash MD5**: detectado en modAuth.bas L78,
   función `HashPassword` que llama a librería externa.
   Riesgo: MD5 está deprecado para hashing de passwords.
```

**Si el agente NO detectó algo así** y tú al ojear el código sí lo viste, el agente fue superficial. Pídele profundidad:

```
El password se está hasheando con MD5 (modAuth.bas L78). 
Eso no aparece en el assessment. Revisa el archivo a fondo y 
agrega esa regla y los riesgos asociados.
```

### 5.3 Dependencias

```markdown
**Otros features:** sesiones (clases compartidas)
**Base de datos:** Usuarios, IntentosLogin, Sesiones
**OCX/COM:** ninguno
**Sistemas externos:** ninguno
```

**Validación:** abre el código, busca `INSERT INTO`, `SELECT FROM` para verificar tablas. Busca `Set obj = CreateObject(...)` para detectar COM tardío que el agente puede haber omitido.

---

## Paso 6: Inventario de OCX

```
@vb6-assessment Genera docs/cross-cuttings/ocx-inventory.md con 
todos los OCX referenciados, clasificados por riesgo.
```

El agente busca en archivos `.vbp` y en código real. Output esperado:

```markdown
| OCX | Riesgo | Archivos que lo usan | Notas |
| --- | --- | --- | --- |
| MSFLXGRD.OCX | Bajo | frmVentas.frm, frmClientes.frm | Reemplazo: DataGrid |
| CRYSTL32.OCX | Alto | frmReportes.frm | Requiere ADR |
```

**Validación crítica:**

1. Abrir el `.vbp` y verificar que TODOS los OCX listados ahí aparecen en el inventario
2. Buscar en código `CreateObject("...")` para detectar OCX cargados dinámicamente (que NO aparecen en `.vbp`)
3. Validar que la clasificación es razonable según `docs/02-lecciones.md` Lección 2

Si encuentras un OCX no listado, agregarlo manualmente o pedirle al agente:

```
PISPEC.OCX se carga dinámicamente en modIntegracion.bas L340 con 
CreateObject. No está en el .vbp pero es Crítico. Agrégalo al inventario.
```

---

## Paso 7: Grafo de dependencias

```
@vb6-assessment Genera docs/dependency-graph.md con el grafo 
de dependencias entre features y propón orden de migración.
```

Output esperado en formato Mermaid o ASCII:

```
[autenticacion]  ← raíz, sin dependencias
        ↓
[clientes]
        ↓        ↓
[ventas-registro]  [ventas-reportes (BLOQUEADO: Crystal Reports)]
```

**Validación:**

1. ¿Las flechas tienen sentido?
2. ¿Hay ciclos? (mal: indica acoplamiento problemático)
3. ¿El orden propuesto deja los bloqueados al final?

---

## Paso 8: Resumen ejecutivo

```
@vb6-assessment Genera docs/SUMMARY.md con resumen ejecutivo.
```

Este es el documento que vas a presentar al cliente o al stakeholder técnico. Debe responder:

- ¿Qué tan grande es el sistema?
- ¿Cuántos features hay?
- ¿Cuáles son los bloqueos críticos?
- ¿Qué stack se recomienda preliminarmente?
- ¿Cuánto va a tomar la migración?

**Validación final:** ¿podrías llevar este SUMMARY a una reunión y defenderlo? Si no, falta detalle. Pídele al agente que profundice donde sientes inseguridad.

---

## Entregables del lab

Al final deberías tener:

```
docs/
├── README.md                    Índice maestro
├── SUMMARY.md                   Resumen ejecutivo
├── features/
│   ├── 01-<feature>.md
│   ├── 02-<feature>.md
│   └── ...
├── cross-cuttings/
│   ├── ocx-inventory.md
│   ├── logging.md
│   └── error-handling.md
└── dependency-graph.md
```

**Definition of Done:**

- ✅ Cada `.frm`, `.bas`, `.cls` está mapeado a un feature o cross-cutting
- ✅ Cada feature tiene su `.md` con reglas de negocio extraídas del código
- ✅ Todos los OCX están clasificados por riesgo
- ✅ El grafo de dependencias es coherente
- ✅ El SUMMARY es presentable a un stakeholder técnico

Solo cuando esto está listo, pasas al Lab 02 (Planning).

---

## Reflexiones para discusión

Después del lab, discute con tu equipo:

1. **¿Cuántas reglas de negocio del código original NO estaban documentadas?** En proyectos reales suele ser 30-50%.
2. **¿Qué OCX te sorprendió encontrar?** Casi siempre hay al menos uno que el cliente "olvidó mencionar".
3. **¿En qué punto el agente se equivocó o fue superficial?** Identificarlo es crítico para saber dónde poner atención humana.
4. **¿Cómo cambiaría el assessment si el sistema fuera 10x más grande?** Pista: el agente no escala linealmente, hay que dividir en sub-sistemas.

---

## Anti-patrones que probablemente cometiste

Honestidad: si es tu primera vez, probablemente:

1. **Aceptaste el clustering inicial sin validar.** El agente clusteriza por nombre de archivo, no por dominio.
2. **No verificaste líneas citadas en reglas.** Algunas pueden estar mal.
3. **Pasaste de largo OCX que parecían menores.** MSCAL70 parece inofensivo hasta que descubres que tiene un comportamiento de fechas que tu reemplazo no replica.
4. **Confiaste en la documentación del cliente** que decía "el sistema solo usa SQL Server" cuando en realidad también escribe a archivos .DBF dBASE.

Si cometiste alguno, es normal. La metodología existe precisamente para que aprendas a detectarlos.

---

## Siguiente lab

[Lab 02: Planning con ADRs](lab-02-planning.md) — toma este assessment y genera las decisiones arquitectónicas formales.
