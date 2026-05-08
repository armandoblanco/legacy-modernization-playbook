#!/usr/bin/env bash
# md2html.sh — Convierte un .md a .html autocontenido (CSS embebido, sin dependencias externas).
# Uso: ./scripts/md2html.sh path/al/archivo.md
#
# Estrategia (orden de preferencia):
#   1. pandoc (mejor calidad, soporta tablas, código, etc.)
#   2. python3 + paquete `markdown`
#   3. error: instala una de las dos
#
# El HTML resultante:
#   - Es un único archivo
#   - Abre offline en cualquier navegador moderno
#   - Tiene tipografía legible y estilo neutro (no requiere internet)

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <archivo.md>" >&2
    exit 1
fi

INPUT="$1"
if [[ ! -f "$INPUT" ]]; then
    echo "Error: no existe $INPUT" >&2
    exit 1
fi

OUTPUT="${INPUT%.md}.html"
TITLE="$(basename "${INPUT%.md}")"

# CSS embebido reusable
read -r -d '' CSS <<'EOF' || true
:root { color-scheme: light dark; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  max-width: 920px; margin: 2rem auto; padding: 0 1.25rem;
  line-height: 1.55; color: #1f2328; background: #ffffff;
}
@media (prefers-color-scheme: dark) {
  body { color: #e6edf3; background: #0d1117; }
  a { color: #58a6ff; }
  table, th, td { border-color: #30363d !important; }
  pre, code { background: #161b22 !important; color: #e6edf3 !important; }
  blockquote { color: #8b949e !important; border-left-color: #30363d !important; }
}
h1, h2, h3, h4 { line-height: 1.25; margin-top: 1.6em; }
h1 { border-bottom: 1px solid #d0d7de; padding-bottom: .3em; }
h2 { border-bottom: 1px solid #d0d7de; padding-bottom: .2em; }
code { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
       background: #f6f8fa; padding: .15em .35em; border-radius: 4px; font-size: 90%; }
pre { background: #f6f8fa; padding: 1em; overflow: auto; border-radius: 6px; }
pre code { background: transparent; padding: 0; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid #d0d7de; padding: .45em .7em; text-align: left; vertical-align: top; }
th { background: #f6f8fa; }
@media (prefers-color-scheme: dark) { th { background: #161b22; } }
blockquote { color: #57606a; border-left: .25em solid #d0d7de; padding: 0 1em; margin: 0 0 1em; }
img { max-width: 100%; }
.meta { font-size: .85em; color: #57606a; margin-bottom: 1.5em; }
EOF

if command -v pandoc >/dev/null 2>&1; then
    pandoc "$INPUT" \
        --from gfm \
        --to html5 \
        --standalone \
        --metadata title="$TITLE" \
        --css /dev/stdin <<<"$CSS" \
        --self-contained \
        -o "$OUTPUT" 2>/dev/null || \
    pandoc "$INPUT" --from gfm --to html5 --standalone \
        --metadata title="$TITLE" -H <(printf '<style>%s</style>' "$CSS") \
        -o "$OUTPUT"
    echo "[ok] pandoc → $OUTPUT"
    exit 0
fi

if command -v python3 >/dev/null 2>&1 && python3 -c "import markdown" 2>/dev/null; then
    python3 - "$INPUT" "$OUTPUT" "$TITLE" "$CSS" <<'PY'
import sys, html, markdown
inp, out, title, css = sys.argv[1:5]
with open(inp, 'r', encoding='utf-8') as f:
    md = f.read()
body = markdown.markdown(md, extensions=['tables', 'fenced_code', 'toc', 'sane_lists'])
doc = f"""<!doctype html>
<html lang="es"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>{css}</style>
</head><body>
<div class="meta">Generado offline — abre este archivo directamente en cualquier navegador.</div>
{body}
</body></html>
"""
with open(out, 'w', encoding='utf-8') as f:
    f.write(doc)
print(f"[ok] python-markdown → {out}")
PY
    exit 0
fi

cat >&2 <<'EOF'
[error] No se encontró ni pandoc ni python3+markdown.
Instala una de las dos opciones:

  # macOS
  brew install pandoc
  # Debian/Ubuntu
  sudo apt-get install pandoc
  # o
  pip3 install markdown
EOF
exit 1
