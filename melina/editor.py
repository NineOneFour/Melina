import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Pango


class Editor(Gtk.ScrolledWindow):
    def __init__(self):
        super().__init__()
        self.set_hexpand(True)
        self.set_vexpand(True)

        self.view = Gtk.TextView()
        self.view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.view.set_left_margin(12)
        self.view.set_right_margin(12)
        self.view.set_top_margin(12)
        self.view.set_bottom_margin(12)

        font = Pango.FontDescription("Monospace 11")
        self.view.override_font(font)

        self.buffer = self.view.get_buffer()
        self.add(self.view)

    def get_text(self):
        start, end = self.buffer.get_bounds()
        return self.buffer.get_text(start, end, True)

    def set_text(self, text):
        self.buffer.set_text(text)

    def connect_changed(self, callback):
        self.buffer.connect("changed", callback)

    def insert_around_selection(self, before, after):
        """Wrap selected text (or insert at cursor) with before/after markers."""
        if self.buffer.get_has_selection():
            start, end = self.buffer.get_selection_bounds()
            selected = self.buffer.get_text(start, end, True)
            self.buffer.delete(start, end)
            self.buffer.insert(start, before + selected + after)
        else:
            cursor = self.buffer.get_iter_at_mark(self.buffer.get_insert())
            self.buffer.insert(cursor, before + after)
            # Move cursor between the markers
            new_pos = self.buffer.get_iter_at_mark(self.buffer.get_insert())
            new_pos.backward_chars(len(after))
            self.buffer.place_cursor(new_pos)

    def insert_line_prefix(self, prefix):
        """Prefix the current line (or each selected line) with a string."""
        if self.buffer.get_has_selection():
            start, end = self.buffer.get_selection_bounds()
            start.set_line_offset(0)
            if not end.starts_line():
                end.forward_to_line_end()
            text = self.buffer.get_text(start, end, True)
            lines = text.split("\n")
            new_text = "\n".join(prefix + line for line in lines)
            self.buffer.delete(start, end)
            self.buffer.insert(start, new_text)
        else:
            cursor = self.buffer.get_iter_at_mark(self.buffer.get_insert())
            cursor.set_line_offset(0)
            self.buffer.insert(cursor, prefix)

    def grab(self):
        self.view.grab_focus()
