import sys
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gio

from .window import AppWindow


class MelinaApp(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id="io.github.melina",
            flags=Gio.ApplicationFlags.HANDLES_OPEN,
        )
        self._filepath = None

    def do_activate(self):
        win = AppWindow(self, filepath=self._filepath)
        win.present()

    def do_open(self, files, n_files, hint):
        self._filepath = files[0].get_path() if n_files > 0 else None
        self.activate()


def main():
    app = MelinaApp()
    # Pass a file argument if given on the command line
    if len(sys.argv) > 1 and not sys.argv[1].startswith("-"):
        sys.exit(app.run(["Melina", sys.argv[1]]))
    else:
        sys.exit(app.run([]))
