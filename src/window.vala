namespace Melina {

    public class Window : Gtk.ApplicationWindow {

        private Editor          editor;
        private Renderer        renderer;
        private Gtk.Stack       stack;
        private Gtk.ToggleButton mode_btn;
        private string?         current_file = null;
        private uint            render_timer = 0;

        public Window (Gtk.Application app, string? filepath = null) {
            Object (application: app);
            set_default_size (960, 700);
            setup_header ();
            setup_body ();
            update_title ();
            show_all ();

            if (filepath != null) {
                load_file (filepath);
            }
        }

        // ---------------------------------------------------------------- layout

        private void setup_header () {
            var bar = new Gtk.HeaderBar ();
            bar.show_close_button = true;
            bar.title = "Melina";
            set_titlebar (bar);

            var new_btn = new Gtk.Button.from_icon_name ("document-new-symbolic", Gtk.IconSize.BUTTON);
            new_btn.tooltip_text = "New file";
            new_btn.clicked.connect (on_new);

            var open_btn = new Gtk.Button.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);
            open_btn.tooltip_text = "Open file";
            open_btn.clicked.connect (on_open);

            var save_btn = new Gtk.Button.from_icon_name ("document-save-symbolic", Gtk.IconSize.BUTTON);
            save_btn.tooltip_text = "Save  (Ctrl+S)";
            save_btn.clicked.connect (on_save);

            var saveas_btn = new Gtk.Button.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.BUTTON);
            saveas_btn.tooltip_text = "Save As…";
            saveas_btn.clicked.connect (on_save_as);

            bar.pack_start (new_btn);
            bar.pack_start (open_btn);
            bar.pack_start (save_btn);
            bar.pack_start (saveas_btn);

            // mode toggle: label describes the action (what clicking will do)
            mode_btn = new Gtk.ToggleButton.with_label ("Edit");
            mode_btn.tooltip_text = "Switch to editor";
            mode_btn.toggled.connect (on_mode_toggled);
            mode_btn.active = true;   // start in preview/rendered mode
            bar.pack_end (mode_btn);
        }

        private void setup_body () {
            var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            add (vbox);

            editor   = new Editor ();
            renderer = new Renderer ();

            var toolbar = new Toolbar (editor);
            var sep     = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            stack = new Gtk.Stack ();
            stack.transition_type     = Gtk.StackTransitionType.CROSSFADE;
            stack.transition_duration = 120;
            stack.add_named (renderer, "rendered");
            stack.add_named (editor,   "raw");
            stack.visible_child_name = "rendered";

            vbox.pack_start (toolbar, false, false, 0);
            vbox.pack_start (sep,     false, false, 0);
            vbox.pack_start (stack,   true,  true,  0);

            editor.buffer.changed.connect (on_text_changed);
            key_press_event.connect (on_key_press);
        }

        // --------------------------------------------------------------- signals

        private void on_mode_toggled () {
            if (mode_btn.active) {
                // now in rendered/preview — button offers to switch to editing
                mode_btn.label        = "Edit";
                mode_btn.tooltip_text = "Switch to editor";
                stack.visible_child_name = "rendered";
                trigger_render ();
            } else {
                // now in edit mode — button offers to switch to preview
                mode_btn.label        = "Preview";
                mode_btn.tooltip_text = "Switch to rendered preview";
                stack.visible_child_name = "raw";
                editor.focus ();
            }
        }

        private void on_text_changed () {
            if (render_timer != 0) {
                GLib.Source.remove (render_timer);
            }
            render_timer = GLib.Timeout.add (300, () => {
                render_timer = 0;
                trigger_render ();
                return GLib.Source.REMOVE;
            });
        }

        private void trigger_render () {
            renderer.render (editor.get_text ());
        }

        private bool on_key_press (Gdk.EventKey event) {
            if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                switch (event.keyval) {
                    case Gdk.Key.s: on_save ();   return true;
                    case Gdk.Key.o: on_open ();   return true;
                    case Gdk.Key.n: on_new ();    return true;
                    case Gdk.Key.b:
                        editor.insert_around_selection ("**", "**"); return true;
                    case Gdk.Key.i:
                        editor.insert_around_selection ("*", "*");   return true;
                }
            }
            return false;
        }

        // ------------------------------------------------------------- file ops

        private void on_new () {
            editor.set_text ("");
            current_file = null;
            update_title ();
        }

        private void on_open () {
            var dlg = new Gtk.FileChooserDialog (
                "Open Markdown File", this, Gtk.FileChooserAction.OPEN);
            dlg.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
            dlg.add_button ("_Open",   Gtk.ResponseType.OK);

            var md_filter = new Gtk.FileFilter ();
            md_filter.set_name ("Markdown files");
            md_filter.add_pattern ("*.md");
            md_filter.add_pattern ("*.markdown");
            dlg.add_filter (md_filter);

            var all_filter = new Gtk.FileFilter ();
            all_filter.set_name ("All files");
            all_filter.add_pattern ("*");
            dlg.add_filter (all_filter);

            if (dlg.run () == Gtk.ResponseType.OK) {
                load_file (dlg.get_filename ());
            }
            dlg.destroy ();
        }

        private void on_save () {
            if (current_file != null) {
                write_file (current_file);
            } else {
                on_save_as ();
            }
        }

        private void on_save_as () {
            var dlg = new Gtk.FileChooserDialog (
                "Save As", this, Gtk.FileChooserAction.SAVE);
            dlg.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
            dlg.add_button ("_Save",   Gtk.ResponseType.OK);
            dlg.do_overwrite_confirmation = true;

            if (current_file != null) {
                dlg.set_filename (current_file);
            } else {
                dlg.set_current_name ("untitled.md");
            }

            if (dlg.run () == Gtk.ResponseType.OK) {
                string path = dlg.get_filename ();
                if (!path.has_suffix (".md") && !path.has_suffix (".markdown")) {
                    path += ".md";
                }
                write_file (path);
            }
            dlg.destroy ();
        }

        private void load_file (string path) {
            try {
                string text;
                GLib.FileUtils.get_contents (path, out text);
                editor.set_text (text);
                current_file = path;
                update_title ();
                trigger_render ();
            } catch (GLib.Error e) {
                show_error ("Could not open file:\n" + e.message);
            }
        }

        private void write_file (string path) {
            try {
                GLib.FileUtils.set_contents (path, editor.get_text ());
                current_file = path;
                update_title ();
            } catch (GLib.Error e) {
                show_error ("Could not save file:\n" + e.message);
            }
        }

        private void update_title () {
            if (current_file != null) {
                title = @"Melina — $(GLib.Path.get_basename (current_file))";
            } else {
                title = "Melina — Untitled";
            }
        }

        private void show_error (string message) {
            var dlg = new Gtk.MessageDialog (
                this,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.OK,
                "%s", message);
            dlg.run ();
            dlg.destroy ();
        }
    }
}
