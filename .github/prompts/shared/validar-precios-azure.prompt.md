---
description: Valida y refresca los precios de Azure de un assessment existente usando la Retail Prices REST API
mode: agent
---

# Validar precios Azure (Retail Prices API)

Valida o refresca los precios listados en `cloud-architectures/azure/{ProjectName}/05-pricing.md` contra la fuente de verdad: **Azure Retail Prices API**.

## Cuándo usar

- El assessment Azure tiene >30 días (los precios pueden haber cambiado)
- Se cambió de región o de SKU
- El cliente cuestiona el TCO y necesitas auditar línea por línea
- Cambiaste de currency (USD → EUR / MXN / BRL)

## Pasos

1. **Lee** `cloud-architectures/azure/{ProjectName}/05-pricing.md` — extrae lista de componentes, SKUs y región.
2. **Para cada componente**, construye filtro OData y llama:
   ```
   GET https://prices.azure.com/api/retail/prices?$filter=<filtro>&currencyCode='<currency>'
   ```
   Filtros típicos:
   - `serviceName eq 'Azure SQL Database'`
   - `armRegionName eq 'eastus2'`
   - `skuName eq 'GP_Gen5_4'` o `productName eq '...'`
   - `priceType eq 'Consumption'` (o `'Reservation'` para RIs)
3. **Sigue paginación** (`NextPageLink`) hasta agotar.
4. **Persiste** JSON crudo en `cloud-architectures/azure/{ProjectName}/pricing-raw/<componente>-YYYYMMDD.json`.
5. **Compara** con precios anteriores; resalta cambios >5%.
6. **Recalcula** subtotales y total mensual.
7. **Genera** `05-pricing-revision-YYYYMMDD.md` con:
   - Tabla nueva (precios actuales)
   - Diff vs revisión anterior
   - Total nuevo vs anterior
   - Nota sobre cambios de meter/SKU detectados (Microsoft renombra ocasionalmente)
8. **Actualiza** `05-pricing.md` solo si el usuario aprueba; mientras tanto convive como `-revision-YYYYMMDD.md`.

## Sanity checks

- Si un SKU **desapareció** de la API → marca como `❌ DEPRECATED` y sugiere reemplazo.
- Si el `unitOfMeasure` cambió (p.ej. de "1 Hour" a "100 Hours") → recalcula con cuidado.
- Cross-check con [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) para los componentes más caros.
- **Egress / data transfer** suelen olvidarse; valida que estén.
- **Soporte** (Standard 10% / Pro Direct flat) se calcula sobre el subtotal Azure, no se obtiene de la API.

## Output esperado

```markdown
# Revisión de precios — {ProjectName} — YYYYMMDD

**Currency:** USD
**Región primaria:** eastus2
**Fuente:** Azure Retail Prices API (snapshot guardado en pricing-raw/)

| Componente | Precio anterior | Precio actual | Δ% | Estado |
|---|---|---|---|---|
| App Service P1v3 | $0.196/h | $0.196/h | 0% | ✅ |
| Azure SQL GP 4vCore | $0.500/h | $0.520/h | +4% | ⚠️ |
| ... |

**Total mensual anterior:** $4,250
**Total mensual actual:**   $4,378  (+3.0%)

**Cambios destacados:**
- Azure SQL: +4% en precio por vCore
- Front Door: nueva tier "Standard Plus" disponible — evaluar si conviene degradar de Premium

**Recomendación:** <accionable>
```

## No hagas

- No edites `05-pricing.md` directo sin aprobación (debe haber trazabilidad).
- No mezcles currencies en una misma tabla.
- No ignores los meters de **data transfer egress** (suelen mover el total >5%).
- No uses precios de la web de marketing — solo de la API.
