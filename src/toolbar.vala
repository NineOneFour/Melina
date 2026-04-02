namespace Melina {

    delegate void ToolAction ();

    public class Toolbar : Gtk.Box {

        private Editor editor;

        public Toolbar (Editor editor) {
            Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 2);
            this.editor = editor;
            margin_start  = 4;
            margin_end    = 4;
            margin_top    = 4;
            margin_bottom = 4;
            build ();
        }

        private void build () {
            add_btn ("B",    "Bold",            () => editor.insert_around_selection ("**", "**"));
            add_btn ("I",    "Italic",           () => editor.insert_around_selection ("*", "*"));
            add_btn ("~~",   "Strikethrough",    () => editor.insert_around_selection ("~~", "~~"));
            add_sep ();
            add_btn ("H1",   "Heading 1",        () => editor.insert_line_prefix ("# "));
            add_btn ("H2",   "Heading 2",        () => editor.insert_line_prefix ("## "));
            add_btn ("H3",   "Heading 3",        () => editor.insert_line_prefix ("### "));
            add_sep ();
            add_btn ("`·`",  "Inline code",      () => editor.insert_around_selection ("`", "`"));
            add_btn ("```",  "Code block",       () => insert_code_block ());
            add_sep ();
            add_btn ("🔗",   "Link",             () => insert_link ());
            add_btn ("—",    "Horizontal rule",  () => insert_hr ());
            add_btn (">",    "Blockquote",       () => editor.insert_line_prefix ("> "));
            add_sep ();
            add_btn ("•",    "Bullet list",      () => editor.insert_line_prefix ("- "));
            add_btn ("1.",   "Numbered list",    () => editor.insert_line_prefix ("1. "));
        }

        private void add_btn (string label, string tooltip, owned ToolAction action) {
            var btn = new Gtk.Button.with_label (label);
            btn.tooltip_text = tooltip;
            btn.get_style_context ().add_class ("flat");
            btn.clicked.connect (() => action ());
            pack_start (btn, false, false, 0);
        }

        private void add_sep () {
            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            sep.margin_start = 4;
            sep.margin_end   = 4;
            pack_start (sep, false, false, 0);
        }

        private void insert_code_block () {
            Gtk.TextIter start, end;
            if (editor.buffer.get_selection_bounds (out start, out end)) {
                string selected = editor.buffer.get_text (start, end, true);
                editor.buffer.delete (ref start, ref end);
                editor.buffer.insert (ref start, "```\n" + selected + "\n```", -1);
            } else {
                Gtk.TextIter cursor;
                editor.buffer.get_iter_at_mark (out cursor, editor.buffer.get_insert ());
                editor.buffer.insert (ref cursor, "```\n\n```", -1);
                // position cursor on the blank line inside the block
                Gtk.TextIter pos;
                editor.buffer.get_iter_at_mark (out pos, editor.buffer.get_insert ());
                pos.backward_chars (4);
                editor.buffer.place_cursor (pos);
            }
        }

        private void insert_link () {
            Gtk.TextIter start, end;
            if (editor.buffer.get_selection_bounds (out start, out end)) {
                string selected = editor.buffer.get_text (start, end, true);
                editor.buffer.delete (ref start, ref end);
                editor.buffer.insert (ref start, "[" + selected + "](url)", -1);
            } else {
                editor.insert_around_selection ("[", "](url)");
            }
        }

        private void insert_hr () {
            Gtk.TextIter cursor;
            editor.buffer.get_iter_at_mark (out cursor, editor.buffer.get_insert ());
            editor.buffer.insert (ref cursor, "\n\n---\n\n", -1);
        }
    }
}
