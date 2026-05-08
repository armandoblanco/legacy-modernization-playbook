# Criterios para elegir stack target

Una de las decisiones más caras que se toma en Fase 2 de la metodología es el stack target. Una mala elección genera re-trabajo masivo. Esta guía da criterios concretos.

---

## Las opciones realistas

Para una migración de VB6 a .NET moderno, hay tres caminos viables:

1. **WinForms .NET 8** (`net8.0-windows`)
2. **WPF .NET 8 + MVVM** (`net8.0-windows`)
3. **Blazor Server o ASP.NET Core MVC** (`net8.0`)

Hay otras opciones (MAUI, Avalonia, Uno) pero raramente son la respuesta correcta para una migración legacy en LATAM. Si tu caso es excepcional, evalúalas con criterios similares.

---

## Matriz de decisión rápida

Si solo tienes 30 segundos:

| Si el sistema actual… | Y el equipo… | Elige |
| --- | --- | --- |
| Es desktop interno, simple, formularios CRUD | Tiene experiencia .NET pero no MVVM | **WinForms** |
| Es desktop con UI compleja, dashboards, gráficos | Tiene experiencia con MVVM o disponibilidad para aprenderlo | **WPF + MVVM** |
| Tiene >30 pantallas con lógica de presentación rica | Tiene experiencia .NET avanzada | **WPF + MVVM** |
| Debe acceder remotamente o desde móviles | Tiene experiencia web | **Blazor / ASP.NET** |
| Usa hardware específico (impresoras, scanners) | Cualquiera | **WinForms o WPF** (no web) |
| El cliente lo va a operar internamente sin VPN | Cualquiera | **Desktop** (WinForms o WPF) |

---

## Criterios detallados

### WinForms .NET 8

**Cuándo elegir WinForms:**

- El sistema VB6 actual es de formularios planos sin UI exótica
- El equipo no tiene experiencia con MVVM y la organización no acepta curva de aprendizaje
- La migración es conservadora 1:1 a nivel visual
- La aplicación se usa por usuarios internos que no esperan UX moderna
- Necesitas Form Designer (drag and drop visual de controles)
- No hay capacidad de inversión en capacitación específica de WPF

**Cuándo NO elegir WinForms:**

- La aplicación tiene >30 formularios complejos con lógica de presentación rica
- Necesitas testabilidad alta de la capa de UI
- El sistema tiene dashboards, gráficos en tiempo real, animaciones
- El equipo quiere usar binding declarativo y validaciones via atributos

**Trampas conocidas:**

- WinForms en .NET 8 NO es 100% compatible con WinForms .NET Framework 4.8. Algunos controles antiguos (DataGrid, MaskedTextBox antiguos) tienen comportamiento sutil distinto.
- El designer en VS Code es limitado. Para WinForms, Visual Studio (no Code) es mejor experiencia.
- Acceso a hilos UI requiere `Invoke()`/`BeginInvoke()` igual que en .NET Framework. No hay magia automática.

---

### WPF .NET 8 + MVVM

**Cuándo elegir WPF:**

- Aplicación con UI rica (custom controls, animaciones, gráficos)
- Equipo tiene o puede aprender MVVM (CommunityToolkit.Mvvm es la curva más suave)
- Sistema con muchas pantallas donde la testabilidad importa
- La organización acepta el costo de aprendizaje adicional respecto a WinForms
- Hay valor en separar View de ViewModel (testing, reusabilidad de lógica)

**Cuándo NO elegir WPF:**

- Equipo sin experiencia .NET moderno
- Restricciones de cronograma del cliente que no permiten curva de aprendizaje (WPF tiene overhead inicial)
- UI puramente CRUD sin necesidad de lógica de presentación compleja
- El cliente no aprecia diferencias de UX moderna (UX no le pagan)

**Framework MVVM recomendado:**

- **CommunityToolkit.Mvvm 8.x** es la opción default. Source generators reducen 70% del boilerplate, mantenido por Microsoft, sin lock-in de DI container.
- **Prism** solo si necesitas modularidad agresiva (módulos cargados dinámicamente) o navegación regional compleja.
- **MVVM puro** (INotifyPropertyChanged a mano) NO recomendado en proyecto nuevo. Demasiado boilerplate.

**Trampas conocidas:**

- XAML tiene curva de aprendizaje real. Subestimarla genera código de View con lógica donde no debe ir.
- Bindings con typos no fallan en compile-time (silent fail). Usar `x:Bind` cuando sea posible o validar con tooling.
- Performance de DataGrid con miles de filas requiere virtualización explícita.

---

### Blazor Server o ASP.NET Core MVC

**Cuándo elegir Blazor/ASP.NET:**

- Hay valor real en hacer la app web (acceso remoto, multi-dispositivo)
- El cliente tiene infraestructura web (servidor, certificados, dominio)
- Equipo tiene experiencia web o disponibilidad para aprender
- La aplicación NO depende de hardware local (impresoras térmicas, scanners, OCX)
- El cliente acepta re-pensar UX (la migración a web no es 1:1 con desktop)

**Cuándo NO elegir Blazor/ASP.NET:**

- La aplicación usa periféricos hardware (cajas registradoras, lectoras de tarjetas, balanzas)
- El sistema VB6 actual es desktop puro y los usuarios no quieren cambiar
- No hay infraestructura web disponible
- El cliente no quiere lidiar con autenticación web, certificados, hosting
- Necesitas comportamiento offline o conectividad inestable

**Trampas conocidas:**

- Blazor Server requiere conexión persistente WebSocket. Conectividad mala = experiencia mala.
- Blazor WebAssembly es alternativa pero tiene tamaño de descarga inicial considerable.
- Migrar de desktop a web NO es migración 1:1. Es re-arquitectura con todas las implicaciones.

---

## Criterios que la gente subestima

### 1. Familiaridad del equipo con el stack

Migrar a un stack que el equipo no domina garantiza que la migración sea de calidad inferior al VB6 original. Elegir WPF cuando el equipo no sabe MVVM, o Blazor cuando el equipo no sabe web, añade una curva de aprendizaje significativa que muchas veces no se contempla en la planificación inicial. Esa curva no desaparece por elegir Copilot como acelerador: el equipo necesita entender lo que está aceptando del agente.

### 2. Mantenimiento a largo plazo

¿Quién va a mantener el sistema en 5 años? Si la respuesta es "el mismo equipo que lo migró", elegir un stack que entiendan importa más que elegir el stack "más moderno".

### 3. Soporte del stack target

- WinForms y WPF en .NET 8: soporte LTS hasta noviembre 2026
- Blazor Server: parte de ASP.NET Core, soporte LTS .NET 8
- Después de 2026, hay que actualizar a .NET 10 (LTS siguiente)

Si el cliente tiene política de "no cambiar versión LTS hasta que se acabe", planificar la siguiente migración de .NET ahora.

### 4. Hardware del cliente

Sistemas VB6 antiguos a veces corren en máquinas viejas. .NET 8 requiere Windows 10+ (Windows 7 no soportado). Si el cliente tiene Windows 7 o XP en producción, se necesita actualizar HW antes que SW.

### 5. Integración con sistemas externos

Si el sistema VB6 habla con:
- **Mainframe via COM/OCX propietario**: cualquier stack desktop funciona; web requiere Gateway adicional
- **Hardware (impresoras térmicas, lectoras de cheques, scanners)**: solo desktop (WinForms/WPF) sin complicaciones
- **Servicios web SOAP/REST**: cualquier stack
- **Otras apps de escritorio via DDE**: solo desktop

---

## Decisiones híbridas

A veces la respuesta es combinar:

### Caso 1: Backend .NET + UI WinForms inicial → migración futura a Blazor

Migrar primero a desktop conservadoramente (WinForms), pero arquitectar el backend (Domain + Application) de forma que pueda ser consumido por Blazor en el futuro. Esto requiere:

- Clean Architecture estricta
- DTOs serializables
- Casos de uso async-friendly desde el inicio
- Sin acoplamiento de lógica a controles WinForms

Si se hace bien, la "migración futura a web" es solo cambiar la capa de Presentation. Si se hace mal, hay que reescribir mucho.

### Caso 2: WPF para módulo principal + WinForms para utilidades

Aplicación principal en WPF (donde la UX importa) y utilidades de admin en WinForms (más rápido de hacer). Funciona si los proyectos están claramente separados.

### Caso 3: Strangler pattern con web nueva alrededor del legacy

Mantener VB6 corriendo, crear una app Blazor nueva que toma features uno por uno. Útil cuando el VB6 tiene OCX bloqueados que requieren mucho ADR work.

---

## Anti-patrón clásico

"Vamos a migrar a Blazor porque está de moda." Razones malas para elegir un stack:

- Está de moda
- El arquitecto del cliente lo prefiere por gusto personal
- Suena moderno en el deck de ventas
- Microsoft lo está promocionando

Razones buenas:

- Los criterios objetivos arriba lo justifican
- Hay restricciones técnicas claras que lo descartan o requieren

---

## Cómo documentar la decisión

La decisión de stack DEBE ir en un ADR. Template sugerido:

```markdown
# ADR-001: Stack target para migración

**Fecha:** YYYY-MM-DD
**Estado:** Aceptado

## Contexto

Sistema VB6 [nombre] de [N] KLOC con [resumen].

## Decisión

**Stack elegido:** [WinForms | WPF | Blazor] .NET 8

## Alternativas evaluadas

### Alternativa A: WinForms .NET 8
- Pros: ...
- Contras: ...
- Rechazada porque: ...

### Alternativa B: WPF + MVVM
- Pros: ...
- Contras: ...
- Rechazada porque: ...

### Alternativa elegida: Blazor Server
- Por qué: [criterios objetivos del cliente y proyecto]

## Consecuencias

**Positivas:**
- ...

**Negativas / deuda técnica asumida:**
- ...

**Riesgos:**
- ...

## Implementación

- Stack secundario: [DI, ORM, logging]
- Frameworks elegidos dentro del stack: [CommunityToolkit.Mvvm, etc.]
- Versión target: .NET 8 LTS
```

Este ADR es la primera pieza de Fase 2. Sin él, no se debe pasar a Fase 3.
