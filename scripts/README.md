# scripts/

Utilidades del repo. **Sin estado**, idempotentes, no tocan código de cliente.

## md2html

Convierte un Markdown a HTML autocontenido (CSS embebido, abre offline en cualquier navegador).

### Linux/macOS

```bash
./scripts/md2html.sh assessment/MiProyecto/seguridad-08052026.md
```

Estrategia (cae al siguiente si el anterior no existe):

1. `pandoc` (si está instalado)
2. `python3` + paquete `markdown`

Instalar pandoc:

```bash
brew install pandoc        # macOS
sudo apt install pandoc    # Debian/Ubuntu
```

O usar Python:

```bash
pip3 install markdown
```

### Windows

```powershell
python scripts\md2html.py assessment\MiProyecto\seguridad-08052026.md
```

Requiere `pip install markdown`.

### Convertir todos los reportes de un proyecto

```bash
for f in assessment/MiProyecto/*.md; do
  ./scripts/md2html.sh "$f"
done
```

## Convención de nombres de los reportes

`assessment/{ProjectName}/{categoria}-{DDMMYYYY}.{md,html}`

Categorías reconocidas:

- `seguridad`
- `tco-actual`
- `roi-modernizacion`
- `riesgo-no-hacer`
- `business-case-ejecutivo`
- _(extensible)_

Cada nuevo run **NO sobreescribe** el anterior: nueva fecha = nuevo archivo.
