"""md2html.py — Fallback puro Python (cross-platform, incluye Windows).

Uso:
    python3 scripts/md2html.py path/al/archivo.md

Requiere:
    pip3 install markdown

Genera path/al/archivo.html autocontenido (CSS embebido).
"""
from __future__ import annotations
import html
import sys
from pathlib import Path

CSS = """
:root { color-scheme: light dark; }
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  max-width: 920px; margin: 2rem auto; padding: 0 1.25rem; line-height: 1.55;
  color: #1f2328; background: #ffffff; }
@media (prefers-color-scheme: dark) {
  body { color: #e6edf3; background: #0d1117; }
  a { color: #58a6ff; }
  table, th, td { border-color: #30363d !important; }
  pre, code { background: #161b22 !important; color: #e6edf3 !important; }
  blockquote { color: #8b949e !important; border-left-color: #30363d !important; }
}
h1,h2,h3,h4 { line-height: 1.25; margin-top: 1.6em; }
h1, h2 { border-bottom: 1px solid #d0d7de; padding-bottom: .25em; }
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
"""


def main() -> int:
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/md2html.py <archivo.md>", file=sys.stderr)
        return 1

    src = Path(sys.argv[1])
    if not src.is_file():
        print(f"Error: no existe {src}", file=sys.stderr)
        return 1

    try:
        import markdown
    except ImportError:
        print("Error: falta el paquete 'markdown'. Instala con:\n  pip3 install markdown", file=sys.stderr)
        return 2

    body = markdown.markdown(
        src.read_text(encoding="utf-8"),
        extensions=["tables", "fenced_code", "toc", "sane_lists"],
    )
    title = src.stem
    out = src.with_suffix(".html")
    out.write_text(
        f"""<!doctype html>
<html lang="es"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>{CSS}</style>
</head><body>
<div class="meta">Generado offline — abre este archivo directamente en cualquier navegador.</div>
{body}
</body></html>
""",
        encoding="utf-8",
    )
    print(f"[ok] {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
