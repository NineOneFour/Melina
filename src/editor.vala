namespace Melina {

    public class Editor : Gtk.ScrolledWindow {

        public Gtk.TextView  view   { get; private set; }
        public Gtk.TextBuffer buffer { get; private set; }

        public Editor () {
            hexpand = true;
            vexpand = true;

            view = new Gtk.TextView ();
            view.wrap_mode    = Gtk.WrapMode.WORD_CHAR;
            view.left_margin  = 12;
            view.right_margin = 12;
            view.top_margin   = 12;
            view.bottom_margin = 12;

            var font = Pango.FontDescription.from_string ("Monospace 11");
            view.override_font (font);

            buffer = view.get_buffer ();
            add (view);
        }

        public string get_text () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            return buffer.get_text (start, end, true);
        }

        public void set_text (string text) {
            buffer.set_text (text, -1);
        }

        public new void focus () {
            view.grab_focus ();
        }

        /* Wrap selected text (or insert at cursor) with before/after markers. */
        public void insert_around_selection (string before, string after) {
            Gtk.TextIter start, end;
            if (buffer.get_selection_bounds (out start, out end)) {
                string selected = buffer.get_text (start, end, true);
                buffer.delete (ref start, ref end);
                buffer.insert (ref start, before + selected + after, -1);
            } else {
                Gtk.TextIter cursor;
                buffer.get_iter_at_mark (out cursor, buffer.get_insert ());
                buffer.insert (ref cursor, before + after, -1);
                // position cursor between the markers
                Gtk.TextIter pos;
                buffer.get_iter_at_mark (out pos, buffer.get_insert ());
                pos.backward_chars (after.char_count ());
                buffer.place_cursor (pos);
            }
        }

        /* Prefix the current line (or each selected line) with a string. */
        public void insert_line_prefix (string prefix) {
            Gtk.TextIter start, end;
            if (buffer.get_selection_bounds (out start, out end)) {
                start.set_line_offset (0);
                if (!end.starts_line ()) {
                    end.forward_to_line_end ();
                }
                string text  = buffer.get_text (start, end, true);
                string[] lines = text.split ("\n");
                var sb = new GLib.StringBuilder ();
                for (int i = 0; i < lines.length; i++) {
                    if (i > 0) sb.append_c ('\n');
                    sb.append (prefix);
                    sb.append (lines[i]);
                }
                buffer.delete (ref start, ref end);
                buffer.insert (ref start, sb.str, -1);
            } else {
                Gtk.TextIter cursor;
                buffer.get_iter_at_mark (out cursor, buffer.get_insert ());
                cursor.set_line_offset (0);
                buffer.insert (ref cursor, prefix, -1);
            }
        }
    }
}
