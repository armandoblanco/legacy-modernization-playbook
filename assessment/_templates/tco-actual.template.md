# TCO Actual — {{ProjectName}}

> **Cliente:** {{ClientName}}
> **Sistema legacy:** {{LegacySystemName}} ({{LegacyTech}})
> **Fecha de análisis:** YYYY-MM-DD
> **Analista:** {{AnalystName}}
> **Validado por finanzas del cliente:** [ ] Sí / [ ] No

## Alcance del análisis

- **Aplicaciones incluidas:** {{ListaApps}}
- **Periodo base:** últimos 12 meses calendario
- **Moneda:** {{Currency}} (tasa referencia si aplica: {{FxRate}})
- **Excluye:** {{Exclusiones}}

---

## 1. Costos de licenciamiento

| Concepto | Proveedor | Tipo | Cantidad | Costo unitario anual | Costo anual total | Notas |
| --- | --- | --- | --- | --- | --- | --- |
| Sistema operativo servidor | {{OS}} | {{Lic}} | {{N}} | {{$}} | {{$}} | |
| Base de datos | {{DB}} | {{Lic}} | {{N}} | {{$}} | {{$}} | |
| Runtime / framework | {{RT}} | {{Lic}} | {{N}} | {{$}} | {{$}} | |
| Componentes / OCX / librerías | {{Componente}} | {{Lic}} | {{N}} | {{$}} | {{$}} | |
| Herramientas de monitoreo | {{Tool}} | {{Lic}} | {{N}} | {{$}} | {{$}} | |
| Otros | | | | | | |
| **Subtotal licencias** | | | | | **{{$}}** | |

## 2. Infraestructura

| Concepto | Cantidad | Costo anual unitario | Costo anual total | Notas |
| --- | --- | --- | --- | --- |
| Servidores físicos / VMs | {{N}} | {{$}} | {{$}} | |
| Almacenamiento (SAN/NAS) | {{TB}} | {{$}} | {{$}} | |
| Backup / DR | | {{$}} | {{$}} | |
| Datacenter / colocation | | {{$}} | {{$}} | |
| Red / conectividad | | {{$}} | {{$}} | |
| **Subtotal infraestructura** | | | **{{$}}** | |

## 3. Personal

| Rol | FTEs dedicados | Costo anual cargado por FTE | Costo anual total | Notas |
| --- | --- | --- | --- | --- |
| Desarrollo (mantto evolutivo) | {{N}} | {{$}} | {{$}} | |
| Soporte L1/L2/L3 | {{N}} | {{$}} | {{$}} | |
| DBA | {{N}} | {{$}} | {{$}} | |
| Operaciones / SRE | {{N}} | {{$}} | {{$}} | |
| Especialista legacy ({{LegacyTech}}) | {{N}} | {{$}} | {{$}} | Cada vez más caro y escaso |
| **Subtotal personal** | | | **{{$}}** | |

## 4. Mantenimiento correctivo

| Concepto | Frecuencia | Costo unitario | Costo anual | Notas |
| --- | --- | --- | --- | --- |
| Hotfixes urgentes | {{N}}/año | {{$}} | {{$}} | |
| Workarounds documentados | | | {{$}} | Capitalizar deuda |
| Tickets de soporte vendor | {{N}} | {{$}} | {{$}} | |
| **Subtotal correctivo** | | | **{{$}}** | |

## 5. Mantenimiento evolutivo

| Concepto | Esfuerzo anual | Costo | Notas |
| --- | --- | --- | --- |
| Features nuevos (backlog real) | {{horas}} | {{$}} | |
| Integraciones | {{horas}} | {{$}} | |
| **Subtotal evolutivo** | | **{{$}}** | |

## 6. Costos ocultos / soft

| Concepto | Estimación | Notas |
| --- | --- | --- |
| Capacitación a personal nuevo en {{LegacyTech}} | {{$}} | Curva ~6 meses |
| Contractors externos especializados | {{$}} | Tarifa premium por escasez |
| Tiempo perdido por lentitud / caídas (productividad usuarios) | {{$}} | Usar histórico de tickets |
| Auditoría / compliance manual (lo que el sistema no automatiza) | {{$}} | |
| Riesgo de pérdida de datos no respaldados | {{$}} | Probabilidad x impacto |
| **Subtotal costos ocultos** | | **{{$}}** |

---

## TCO total anual

| Categoría | {{$}} |
| --- | --- |
| Licencias | {{$}} |
| Infraestructura | {{$}} |
| Personal | {{$}} |
| Mantenimiento correctivo | {{$}} |
| Mantenimiento evolutivo | {{$}} |
| Costos ocultos | {{$}} |
| **TOTAL ANUAL** | **{{$}}** |
| **TCO 5 años (sin inflación)** | **{{$}}** |
| **TCO 5 años (con inflación {{rate}}%)** | **{{$}}** |

---

## Supuestos y limitaciones

- {{Supuesto1}}
- {{Supuesto2}}
- Datos validados con: {{FuenteValidación}}
- Margen de error estimado: ±{{X}}%

## Insumos pendientes

- [ ] {{Pendiente}}

## Aprobaciones

- [ ] Validado por: ______________ ({{RoleFinanzasCliente}})
- [ ] Fecha: ______________
