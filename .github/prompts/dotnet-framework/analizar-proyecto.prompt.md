---
description: Analiza un proyecto .csproj legacy específico y produce su perfil de migración
mode: agent
---

# Analizar proyecto .NET Framework

Analiza el proyecto .csproj indicado por el usuario y produce un perfil estructurado.

## Inputs esperados
- Ruta al `.csproj` o nombre del proyecto.

## Salida (estructura fija)

```markdown
# Perfil — <NombreProyecto>

## Identidad
- Path: <ruta>
- TargetFramework actual: net48 | netstandard2.0 | netcoreapp3.1 | ...
- Estilo: Legacy (`<Project ToolsVersion=...>`) | SDK-style
- OutputType: Library | Exe | Web

## Dependencias entrantes (quién me usa)
- <ProyectoA>
- <ProyectoB>

## Dependencias salientes (a qué dependo)
### NuGet
| Paquete | Versión | Categoría | Reemplazo target |
|---|---|---|---|

### Project references
- <ProyectoX>

## Superficie de runtime no portable
- [ ] BinaryFormatter (archivos: ...)
- [ ] System.Web.* (archivos: ...)
- [ ] WCF servidor (`<services>` en Web.config)
- [ ] WebForms (.aspx)
- [ ] EF6
- [ ] AppDomain
- [ ] Remoting
- [ ] CAS / SecurityPermission
- [ ] COM Interop
- [ ] Otros: ...

## Tests existentes
- Framework: xUnit | NUnit | MSTest | ninguno
- Cobertura estimada: alto | medio | bajo | sin cobertura

## Clasificación
- Categoría: Crítico | Corto plazo | Migración directa | Multi-target | Ya moderno
- Razón: ...

## Recomendación de orden
- Posición sugerida en el plan: <N>
- Estrategia: in-place | side-by-side
- Pre-requisitos: <proyectos que deben migrarse antes>

## Bloqueantes para Fase 3
1. ...
2. ...

## Esfuerzo estimado
- Horas-persona: <baja|media|alta>
- Confianza: <alta|media|baja>
```

Lee el `.csproj`, los `using` directives y los `Web.config`/`App.config` cercanos. No tomes decisiones arquitectónicas (eso es Fase 2).
