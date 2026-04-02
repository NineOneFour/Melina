# Melina

A lightweight markdown editor for Linux with live preview, built with GTK3 and WebKit2GTK.

## Features

- Split-pane interface with editor and live HTML preview
- Formatting toolbar (bold, italic, strikethrough, headings, code, links, lists, blockquotes)
- Live preview with 300ms debounce — renders as you type
- Keyboard shortcuts for common formatting
- File management: new, open, save, save as
- Dark theme preview (Catppuccin)

## Requirements

- Python 3.10+
- GTK+ 3.0
- WebKit2GTK 4.1
- PyGObject (system package — not installable via pip)

On Arch/Manjaro:
```
sudo pacman -S python-gobject webkit2gtk-4.1
```

On Debian/Ubuntu:
```
sudo apt install python3-gi gir1.2-webkit2-4.1
```

## Installation

Clone the repo and install in a virtual environment with system site packages (required for PyGObject):

```bash
git clone https://github.com/NineOneFour/Melina.git
cd melina
python -m venv --system-site-packages venv
source venv/bin/activate
pip install -e .
```

Then run:
```bash
melina
```

Or open a file directly:
```bash
melina notes.md
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+N` | New file |
| `Ctrl+O` | Open file |
| `Ctrl+S` | Save |
| `Ctrl+Shift+S` | Save as |
| `Ctrl+B` | Bold |
| `Ctrl+I` | Italic |

## Project Structure

```
melina/
├── melina/         # Python/GTK3 implementation
│   ├── app.py      # Application entry point
│   ├── window.py   # Main window
│   ├── editor.py   # Text editor component
│   ├── toolbar.py  # Formatting toolbar
│   └── renderer.py # Markdown-to-HTML renderer (WebKit2)
└── src/            # Vala implementation (in development)
```

## License

MIT
