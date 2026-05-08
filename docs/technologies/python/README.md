# Python 2 (y Python 3 antiguo) → Python 3.12+

> **Estado:** Placeholder. Pendiente poblar con casos reales.

## Alcance previsto

| Origen | Target |
| --- | --- |
| Python 2.7 (EOL desde 2020) | Python 3.12 / 3.13 |
| Python 3.6 / 3.7 / 3.8 (todas EOL) | Python 3.12+ |
| Django 1.x / 2.x | Django 5.x |
| Flask 0.x / 1.x | Flask 3.x o FastAPI |
| Web2py / Pylons / TurboGears antiguos | FastAPI o Django |
| Scripts batch sin estructura | CLI con `click` / `typer`, packageables |

## Particularidades a documentar

- `print` statement → función, `unicode` vs `str`, `dict.iteritems()`, `xrange`
- Conversión asistida con `2to3`, `pyupgrade`, `ruff --fix`
- Type hints retroactivos con `mypy` strict
- Asyncio: dónde tiene sentido y dónde no
- Empaquetado moderno: `pyproject.toml` + `uv` / `poetry` / `hatch`, abandonar `setup.py` legacy
- Dependencias: `pip-tools` / `uv pip compile` / lockfiles
- Testing: `unittest` legacy → `pytest`
- ORM: SQLAlchemy 1.x → 2.x (gran cambio de API)
- Web: WSGI → ASGI (FastAPI, Starlette)
- Contenedores: imágenes slim, multi-stage, non-root user

## Pendiente

- [ ] `trampas-python.md`
- [ ] `decision-stack-python.md` (Django vs FastAPI vs Flask, sync vs async)
- [ ] `.github/agents/python/01-assessment.agent.md`
- [ ] `.github/agents/python/02-planning.agent.md`
- [ ] `.github/agents/python/03-migration.agent.md`
- [ ] Workshop / lab

## Herramientas externas

- **`pyupgrade`**, **`ruff`**, **`black`**, **`mypy`**, **`pyright`**
- **App Modernization for Python** (extensión, herramientas `appmod-python-*`)
- **`uv`** para gestión de dependencias y entornos virtuales (rápido)
