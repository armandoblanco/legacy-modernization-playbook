# Filosofía y lecciones aprendidas

Principios que guían el diseño del playbook y lo que sí / no es esta plantilla.

---

## Principios de diseño

### 1. Cinco fases en orden estricto

Cada fase produce el insumo de la siguiente. Saltar fases genera re-trabajo predecible.

```
Business Case → Assessment → Planning → Migration → Cloud Deploy
   (¿conviene?)   (¿qué hay?)  (¿hacia dónde?)  (construir)  (¿dónde corre?)
```

**Anti-patrón frecuente:** saltar de "el cliente firmó la propuesta" directo a "empecemos a migrar" sin hacer assessment formal. Resultado predecible: en mes 3 aparecen los bloqueos que el assessment habría detectado en semana 2.

### 2. Tecnología-agnóstica en el núcleo

El **qué, cuándo y por qué** son iguales para VB, COBOL, Java o Python. Lo que cambia es el **cómo táctico**: qué APIs deprecadas buscar, qué frameworks reemplazar, qué trampas específicas tiene cada stack.

Por eso los agentes están organizados por tecnología (`@vb-*`, `@dotnet-*`, `@j2ee-*`, etc.) pero comparten la estructura de las 5 fases.

### 3. Cada decisión es un ADR

Sin Architecture Decision Record, la decisión no existe a los 6 meses. El equipo cambia, las razones se olvidan, y alguien revierte el cambio sin entender por qué se tomó.

El playbook fuerza ADRs para:

- Stack target
- Replacement de componentes bloqueantes (OCX, EJB CMP, librerías sin port)
- Patrón arquitectónico
- Estrategia ORM / persistencia
- Strategy de cutover

### 4. El código legacy es la fuente de verdad

Documentación del cliente, comentarios en el código, memoria del equipo: **todas son aproximaciones**. Lo que importa es lo que el código hace realmente cuando se ejecuta.

Los agentes están diseñados para leer el código, citar `archivo:línea`, y extraer reglas implícitas. Cuando hay duda, validan contra el código, no contra el cliente.

### 5. Copilot acelera, no reemplaza

El agente propone, el humano decide. Especialmente en:

- Decisiones arquitectónicas (los ADRs requieren validación humana)
- Replacement de componentes bloqueantes (a veces hay contexto de negocio que el agente no ve)
- Cutover y estrategia de despliegue (depende de operaciones del cliente)

**El playbook no es magia.** Es estructura + agentes + lecciones aprendidas. Sigue funcionando porque mantiene al humano en el loop.

---

## Lecciones aprendidas

### 1. El business case (Fase 0) salva proyectos

El primer recorte presupuestal del cliente típicamente llega al mes 4-6. Un business case sólido con TCO y ROI ayuda a defender la inversión cuando llega ese recorte.

Sin business case, la conversación es "¿podemos pausar la modernización?". Con business case, es "si pausamos, dejamos en el aire X horas de soporte que cuestan Y al año".

### 2. El assessment es 30% del trabajo total

La mayoría de migraciones asume que el assessment es 5% y "el 95% real es codificar". Esto es falso para sistemas con 15+ años en producción.

El assessment encuentra:

- Componentes que el cliente no recordaba que existían
- Reglas de negocio implícitas no documentadas
- Dependencias bloqueantes (OCX sin reemplazo, EJB CMP con relaciones complejas, triggers PL/SQL críticos)
- Integraciones con sistemas terceros que no migran simultáneamente

Cada uno de estos hallazgos cambia el plan. Hacerlos al final, cuesta más.

### 3. Componentes legacy bloqueados no se migran: se reemplazan con ADR

OCX propietario sin reemplazo, EJB 2.x con relaciones imposibles de mapear, IDMS, mainframe CICS: estos NO se migran. Se reemplazan con arquitectura alternativa documentada en ADR, con consciencia del trade-off.

Forzar la migración 1:1 de algo que no es migrable produce código frágil que falla en producción meses después.

### 4. Copilot inventa comportamiento cuando el `.md` del feature está incompleto

Si el archivo de un feature dice "calcula el descuento del cliente" sin detallar la regla, el agente va a inventar una regla razonable. La regla inventada puede ser distinta de la real.

**Solución del playbook:** los agentes de Fase 1 están instruidos para extraer reglas con cita a `archivo:línea`. Los agentes de Fase 3 están instruidos para leer el código legacy fuente, no solo el `.md` del feature.

### 5. Una solución target separada (`src/`) evita corromper el legacy

El playbook fuerza la separación: `legacy/` es read-only, `src/` es donde nace el nuevo código. Esto permite:

- Mantener el legacy compilable durante toda la transición
- Ejecutar ambos sistemas en paralelo para validar paridad
- Hacer rollback si el nuevo sistema falla en producción

Mezclar los dos en un mismo directorio (in-place upgrade total) es viable solo para casos muy específicos (Spring 4 → Spring Boot 3 con upgrade in-place y buena cobertura de tests).

### 6. Compile-and-test entre capas detecta errores temprano

Los agentes de Fase 3 están instruidos para correr `compile + test` después de cada componente migrado, no después de cada feature completo. Esto cambia el modo de falla:

- **Sin compile-and-test:** acumular cambios → al final no compila → debugger con 50 errores entrelazados
- **Con compile-and-test:** cada cambio se valida → si rompe, sabes exactamente cuál fue

### 7. La arquitectura cloud (Fase 4) requiere disciplina propia

App moderna en hosting legacy ≠ modernización. Si el sistema migrado se despliega en el mismo IIS/WebLogic/Tomcat manual del legacy, se pierden los beneficios:

- Sin CI/CD automatizado
- Sin scaling
- Sin observability moderna
- Sin secret management

Por eso Fase 4 es una fase aparte, no un apéndice de Fase 3.

---

## Lo que NO es esta plantilla

### No es una promesa de migración automática

Sistemas con OCX propietarios, dependencias de mainframe, Oracle Forms con lógica PL/SQL crítica en BD: requieren decisiones humanas documentadas en ADR. Los agentes no toman estas decisiones, las **estructuran**.

### No es un convertidor de sintaxis

Para conversión 1:1 línea por línea (VB6 → VB.NET, Java 8 → Java 11) hay herramientas comerciales más baratas y específicas. El playbook es para **modernización**, no transliteración.

La diferencia: una transliteración produce código C# que se ve y se comporta exactamente como el VB6. Una modernización produce código C# que usa los patrones modernos (DI, async, Clean Architecture, tests automatizados), aprovechando que ya estás reescribiendo.

### No incluye samples de código legacy

Tú aportas el código del cliente en `legacy/`. El playbook es la metodología + agentes, no un banco de samples.

### No estima duración del proyecto

La estimación de duración se hace en la propuesta comercial, considerando tamaño del equipo, complejidad del legacy específico, y restricciones del cliente. Está fuera del alcance de la metodología.

Lo que el playbook sí estima: tamaño relativo de cada feature (S / M / L / XL) basado en código analizado, y orden topológico de migración.

---

## Cuándo NO usar este playbook

- **Sistema legacy de menos de 5,000 líneas de código:** probablemente más rápido reescribir directo sin metodología formal
- **Sistema legacy con tests existentes de buena cobertura y solo necesita upgrade de framework:** un upgrade in-place con `.NET Upgrade Assistant` o equivalente puede ser suficiente
- **Sistema que se va a apagar en menos de 1 año:** no vale la pena modernizar, vale la pena migrar datos al sucesor
- **Cliente sin presupuesto para hacer el assessment formal:** sin Fase 1, el resto del playbook no funciona bien

En esos casos, herramientas más livianas o decisiones más pragmáticas son mejor inversión.
