# COBOL legacy → Java / .NET

> **Estado:** Placeholder. Pendiente poblar con casos reales.

## Alcance previsto

| Origen | Target candidato |
| --- | --- |
| COBOL on z/OS (mainframe) con CICS, JCL, VSAM, DB2 | Java 21 + Spring Boot, o .NET 8 |
| COBOL Micro Focus / GnuCOBOL en distributed | Java o .NET, contenerizado |
| COBOL + IMS / IDMS | Caso por caso, frecuentemente requiere replatform parcial |

## Particularidades a documentar

- Estrategias: **rehost** (emulador), **refactor** (transpilación asistida), **rewrite** (reescritura idiomática)
- Conversión de `PIC`, `COMP-3`, `OCCURS`, `REDEFINES` a tipos Java/C#
- COPYBOOKs → DTOs / records
- Procesos batch (JCL) → Spring Batch / Hangfire / Azure Batch
- CICS transactions → REST APIs / mensajería
- Datos: VSAM/IMS → SQL relacional o NoSQL, con migración ETL
- EBCDIC ↔ ASCII / UTF-8
- Pruebas de paridad numérica (precisión decimal estricta)

## Pendiente

- [ ] `trampas-cobol.md`
- [ ] `decision-stack-cobol.md` (Java vs .NET, monolito vs microservicios)
- [ ] `.github/agents/cobol/01-assessment.agent.md`
- [ ] `.github/agents/cobol/02-planning.agent.md`
- [ ] `.github/agents/cobol/03-migration.agent.md`
- [ ] Workshop / lab

## Herramientas externas

- **AWS Mainframe Modernization** (Micro Focus / Blu Age)
- **Azure Mainframe transformation partners** (TmaxSoft, Astadia, Asysco)
- **Heirloom Computing**, **Modern Systems**, **TSRI**

## Notas

COBOL es la tecnología legacy con mayor variabilidad de costo y riesgo. El business case (Fase 0) es **especialmente crítico**: sin sponsor de negocio sólido y plan de coexistencia, el proyecto fracasa.
