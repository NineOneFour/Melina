import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


def _btn(label, tooltip, callback):
    b = Gtk.Button(label=label)
    b.set_tooltip_text(tooltip)
    b.connect("clicked", callback)
    # Style: flat, compact
    ctx = b.get_style_context()
    ctx.add_class("flat")
    return b


def _sep():
    s = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
    s.set_margin_start(4)
    s.set_margin_end(4)
    return s


class Toolbar(Gtk.Box):
    def __init__(self, editor):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=2)
        self.editor = editor
        self.set_margin_start(4)
        self.set_margin_end(4)
        self.set_margin_top(4)
        self.set_margin_bottom(4)

        actions = [
            ("B",   "Bold (Ctrl+B)",          self._bold),
            ("I",   "Italic (Ctrl+I)",         self._italic),
            ("S̶",   "Strikethrough",           self._strike),
            None,
            ("H1",  "Heading 1",               self._h1),
            ("H2",  "Heading 2",               self._h2),
            ("H3",  "Heading 3",               self._h3),
            None,
            ("`·`",  "Inline code",            self._code_inline),
            ("```", "Fenced code block",       self._code_block),
            None,
            ("🔗",  "Link",                    self._link),
            ("—",   "Horizontal rule",         self._hr),
            (">",   "Blockquote",              self._blockquote),
            None,
            ("•",   "Bullet list item",        self._ul),
            ("1.",  "Numbered list item",      self._ol),
        ]

        for item in actions:
            if item is None:
                self.pack_start(_sep(), False, False, 0)
            else:
                label, tip, cb = item
                self.pack_start(_btn(label, tip, cb), False, False, 0)

    # --- inline wrappers ---
    def _bold(self, *_):        self.editor.insert_around_selection("**", "**")
    def _italic(self, *_):      self.editor.insert_around_selection("*", "*")
    def _strike(self, *_):      self.editor.insert_around_selection("~~", "~~")
    def _code_inline(self, *_): self.editor.insert_around_selection("`", "`")

    def _link(self, *_):
        if self.editor.buffer.get_has_selection():
            start, end = self.editor.buffer.get_selection_bounds()
            text = self.editor.buffer.get_text(start, end, True)
            self.editor.buffer.delete(start, end)
            self.editor.buffer.insert(start, f"[{text}](url)")
        else:
            self.editor.insert_around_selection("[", "](url)")

    def _code_block(self, *_):
        if self.editor.buffer.get_has_selection():
            start, end = self.editor.buffer.get_selection_bounds()
            text = self.editor.buffer.get_text(start, end, True)
            self.editor.buffer.delete(start, end)
            self.editor.buffer.insert(start, f"```\n{text}\n```")
        else:
            cursor = self.editor.buffer.get_iter_at_mark(self.editor.buffer.get_insert())
            self.editor.buffer.insert(cursor, "```\n\n```")
            pos = self.editor.buffer.get_iter_at_mark(self.editor.buffer.get_insert())
            pos.backward_chars(4)
            self.editor.buffer.place_cursor(pos)

    # --- line prefixes ---
    def _h1(self, *_):         self.editor.insert_line_prefix("# ")
    def _h2(self, *_):         self.editor.insert_line_prefix("## ")
    def _h3(self, *_):         self.editor.insert_line_prefix("### ")
    def _blockquote(self, *_): self.editor.insert_line_prefix("> ")
    def _ul(self, *_):         self.editor.insert_line_prefix("- ")
    def _ol(self, *_):         self.editor.insert_line_prefix("1. ")

    def _hr(self, *_):
        cursor = self.editor.buffer.get_iter_at_mark(self.editor.buffer.get_insert())
        self.editor.buffer.insert(cursor, "\n\n---\n\n")
