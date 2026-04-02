namespace Melina {

    public class Application : Gtk.Application {

        public Application () {
            Object (
                application_id: "io.github.melina",
                flags: GLib.ApplicationFlags.HANDLES_OPEN
            );
        }

        protected override void activate () {
            new Window (this).present ();
        }

        protected override void open (GLib.File[] files, string hint) {
            new Window (this, files[0].get_path ()).present ();
        }
    }
}
