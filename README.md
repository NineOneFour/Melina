# Melina

A lightweight markdown editor for Linux with live preview, built in Vala with GTK3 and WebKit2GTK.

## Features

- Split-pane interface with editor and live HTML preview
- Formatting toolbar (bold, italic, strikethrough, headings, code, links, lists, blockquotes)
- Live preview with 300ms debounce — renders as you type
- Live file monitoring — auto-reloads when the open file is changed by another process
- Keyboard shortcuts for common formatting
- File management: new, open, save, save as
- Dark theme preview (Catppuccin)

## Requirements

- GTK+ 3.0
- WebKit2GTK 4.1
- cmark
- Vala compiler + Meson + Ninja

On Arch/Manjaro:
```
sudo pacman -S vala meson ninja gtk3 webkit2gtk-4.1 cmark
```

On Debian/Ubuntu:
```
sudo apt install valac meson ninja-build libgtk-3-dev libwebkit2gtk-4.1-dev libcmark-dev
```

## Build

```bash
git clone https://github.com/NineOneFour/Melina.git
cd melina
meson setup build
meson compile -C build
```

Run it:
```bash
./build/melina
```

Or open a file directly:
```bash
./build/melina notes.md
```

To install system-wide:
```bash
meson install -C build
```

## Rebuilding after code changes

```bash
meson compile -C build
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+N` | New file |
| `Ctrl+O` | Open file |
| `Ctrl+S` | Save |
| `Ctrl+B` | Bold |
| `Ctrl+I` | Italic |

## Project Structure

```
melina/
├── src/              # Vala sources
│   ├── main.vala
│   ├── application.vala
│   ├── window.vala
│   ├── editor.vala
│   ├── toolbar.vala
│   └── renderer.vala
└── meson.build
```

## License

MIT
