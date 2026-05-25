---
description: Analizar un módulo o feature específico del sistema Java legacy y generar resumen técnico
---

# Analizar módulo / feature

Analiza el módulo `${input:moduleName}` del sistema en `legacy/`. Produce:

1. **Componentes técnicos involucrados**:
   - Clases Java (EJBs, services, controllers, entities según el stack legacy)
   - Configuración asociada (XML, anotaciones)
   - JSPs / templates frontend
   - Tablas BD usadas
   - Llamadas a otros módulos / sistemas externos

2. **Reglas de negocio identificadas**, con cita a archivo:línea de origen

3. **Bloqueos para migración** específicos de este módulo

4. **Estimación de complejidad** (S / M / L / XL) con justificación

5. **Recomendación de orden** dentro del plan de migración (dependencias hacia/desde otros módulos)

NO modifiques código. NO propongas arquitectura target. Solo analiza y reporta.

Si necesitas más contexto del módulo, pregunta al usuario antes de continuar.

Genera el resultado como un archivo en `docs/features/${input:moduleName}.md` siguiendo el formato del agente de assessment correspondiente al stack:

- Si el stack es J2EE: ver `@j2ee-assessment` Paso 8
- Si el stack es Spring legacy: ver `@spring-legacy-assessment` Paso 9
- Si el stack es Oracle Forms: ver `@oracle-forms-assessment` Paso 10
