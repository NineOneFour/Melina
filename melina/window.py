import os
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

from .editor import Editor
from .renderer import Renderer
from .toolbar import Toolbar

RENDER_DELAY_MS = 300


class AppWindow(Gtk.ApplicationWindow):
    def __init__(self, app, filepath=None):
        super().__init__(application=app)
        self.current_file = None
        self._render_timer = None

        self.set_default_size(960, 700)
        self._setup_header()
        self._setup_body()
        self._update_title()

        if filepath:
            self._load_file(filepath)

        self.show_all()

    # ------------------------------------------------------------------ layout

    def _setup_header(self):
        bar = Gtk.HeaderBar()
        bar.set_show_close_button(True)
        bar.set_title("Melina")
        self.set_titlebar(bar)

        # Left: New / Open / Save
        new_btn = Gtk.Button.new_from_icon_name("document-new-symbolic", Gtk.IconSize.BUTTON)
        new_btn.set_tooltip_text("New file")
        new_btn.connect("clicked", self._on_new)

        open_btn = Gtk.Button.new_from_icon_name("document-open-symbolic", Gtk.IconSize.BUTTON)
        open_btn.set_tooltip_text("Open file")
        open_btn.connect("clicked", self._on_open)

        save_btn = Gtk.Button.new_from_icon_name("document-save-symbolic", Gtk.IconSize.BUTTON)
        save_btn.set_tooltip_text("Save (Ctrl+S)")
        save_btn.connect("clicked", self._on_save)

        saveas_btn = Gtk.Button.new_from_icon_name("document-save-as-symbolic", Gtk.IconSize.BUTTON)
        saveas_btn.set_tooltip_text("Save As…")
        saveas_btn.connect("clicked", self._on_save_as)

        bar.pack_start(new_btn)
        bar.pack_start(open_btn)
        bar.pack_start(save_btn)
        bar.pack_start(saveas_btn)

        # Right: mode toggle
        self.mode_btn = Gtk.ToggleButton(label="Edit")
        self.mode_btn.set_active(True)
        self.mode_btn.set_tooltip_text("Switch to editor")
        self.mode_btn.connect("toggled", self._on_mode_toggle)
        bar.pack_end(self.mode_btn)

    def _setup_body(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(vbox)

        self.editor = Editor()
        self.renderer = Renderer()

        self.toolbar = Toolbar(self.editor)
        sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(120)
        self.stack.add_named(self.renderer, "rendered")
        self.stack.add_named(self.editor, "raw")
        self.stack.set_visible_child_name("rendered")

        vbox.pack_start(self.toolbar, False, False, 0)
        vbox.pack_start(sep, False, False, 0)
        vbox.pack_start(self.stack, True, True, 0)

        self.editor.connect_changed(self._on_text_changed)

        # Keyboard shortcuts
        self.connect("key-press-event", self._on_key_press)

    # ---------------------------------------------------------------- signals

    def _on_mode_toggle(self, btn):
        if btn.get_active():
            # Now in rendered/preview mode — button offers to switch to editing
            btn.set_label("Edit")
            btn.set_tooltip_text("Switch to editor")
            self.stack.set_visible_child_name("rendered")
            self._trigger_render()
        else:
            # Now in edit mode — button offers to switch to preview
            btn.set_label("Preview")
            btn.set_tooltip_text("Switch to rendered preview")
            self.stack.set_visible_child_name("raw")
            self.editor.grab()

    def _on_text_changed(self, *_):
        if self._render_timer:
            GLib.source_remove(self._render_timer)
        self._render_timer = GLib.timeout_add(RENDER_DELAY_MS, self._trigger_render)

    def _trigger_render(self):
        self._render_timer = None
        self.renderer.render(self.editor.get_text())
        return False  # don't repeat

    def _on_key_press(self, widget, event):
        from gi.repository import Gdk
        ctrl = event.state & Gdk.ModifierType.CONTROL_MASK
        if ctrl:
            if event.keyval == Gdk.KEY_s:
                self._on_save()
                return True
            if event.keyval == Gdk.KEY_o:
                self._on_open()
                return True
            if event.keyval == Gdk.KEY_n:
                self._on_new()
                return True
            if event.keyval == Gdk.KEY_b:
                self.editor.insert_around_selection("**", "**")
                return True
            if event.keyval == Gdk.KEY_i:
                self.editor.insert_around_selection("*", "*")
                return True
        return False

    # -------------------------------------------------------------- file ops

    def _on_new(self, *_):
        if self._confirm_discard():
            self.editor.set_text("")
            self.current_file = None
            self._update_title()

    def _on_open(self, *_):
        if not self._confirm_discard():
            return
        dlg = Gtk.FileChooserDialog(
            title="Open Markdown File",
            parent=self,
            action=Gtk.FileChooserAction.OPEN,
        )
        dlg.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OPEN, Gtk.ResponseType.OK,
        )
        filt = Gtk.FileFilter()
        filt.set_name("Markdown files")
        filt.add_pattern("*.md")
        filt.add_pattern("*.markdown")
        dlg.add_filter(filt)

        all_filt = Gtk.FileFilter()
        all_filt.set_name("All files")
        all_filt.add_pattern("*")
        dlg.add_filter(all_filt)

        if dlg.run() == Gtk.ResponseType.OK:
            self._load_file(dlg.get_filename())
        dlg.destroy()

    def _on_save(self, *_):
        if self.current_file:
            self._write_file(self.current_file)
        else:
            self._on_save_as()

    def _on_save_as(self, *_):
        dlg = Gtk.FileChooserDialog(
            title="Save As",
            parent=self,
            action=Gtk.FileChooserAction.SAVE,
        )
        dlg.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_SAVE, Gtk.ResponseType.OK,
        )
        dlg.set_do_overwrite_confirmation(True)
        if self.current_file:
            dlg.set_filename(self.current_file)
        else:
            dlg.set_current_name("untitled.md")

        if dlg.run() == Gtk.ResponseType.OK:
            path = dlg.get_filename()
            if not path.endswith((".md", ".markdown")):
                path += ".md"
            self._write_file(path)
        dlg.destroy()

    def _load_file(self, path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                text = f.read()
            self.editor.set_text(text)
            self.current_file = path
            self._update_title()
            self._trigger_render()
        except OSError as e:
            self._error_dialog(f"Could not open file:\n{e}")

    def _write_file(self, path):
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write(self.editor.get_text())
            self.current_file = path
            self._update_title()
        except OSError as e:
            self._error_dialog(f"Could not save file:\n{e}")

    def _confirm_discard(self):
        # For now, always allow (could add dirty tracking later)
        return True

    def _update_title(self):
        if self.current_file:
            name = os.path.basename(self.current_file)
            self.set_title(f"Melina — {name}")
        else:
            self.set_title("Melina — Untitled")

    def _error_dialog(self, msg):
        dlg = Gtk.MessageDialog(
            parent=self,
            flags=Gtk.DialogFlags.MODAL,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=msg,
        )
        dlg.run()
        dlg.destroy()
