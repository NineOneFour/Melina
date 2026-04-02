/* Inline binding — cmark has no .vapi so we declare just what we need. */
[CCode (cname = "cmark_markdown_to_html", cheader_filename = "cmark.h")]
extern string _cmark_to_html (string text, size_t len, int options);

namespace Melina {

    public class Renderer : Gtk.ScrolledWindow {

        private WebKit.WebView webview;

        private const string CSS = """<style>
body {
  font-family: -apple-system, "Segoe UI", Cantarell, sans-serif;
  font-size: 15px;
  line-height: 1.7;
  color: #e8e8e8;
  background: #1e1e2e;
  max-width: 820px;
  margin: 0 auto;
  padding: 24px 32px;
}
h1, h2, h3, h4, h5, h6 {
  color: #cdd6f4;
  margin-top: 1.4em;
  margin-bottom: 0.4em;
  font-weight: 600;
}
h1 { font-size: 2em; border-bottom: 1px solid #45475a; padding-bottom: 0.3em; }
h2 { font-size: 1.5em; border-bottom: 1px solid #313244; padding-bottom: 0.2em; }
a { color: #89b4fa; text-decoration: none; }
a:hover { text-decoration: underline; }
code {
  background: #313244;
  color: #a6e3a1;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: "JetBrains Mono", "Fira Code", Monospace;
  font-size: 0.9em;
}
pre {
  background: #181825;
  border: 1px solid #313244;
  border-radius: 6px;
  padding: 16px;
  overflow-x: auto;
}
pre code { background: none; padding: 0; color: #cdd6f4; }
blockquote {
  border-left: 4px solid #89b4fa;
  margin: 0;
  padding: 4px 16px;
  color: #a6adc8;
  background: #181825;
  border-radius: 0 4px 4px 0;
}
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid #45475a; padding: 8px 12px; text-align: left; }
th { background: #313244; color: #cdd6f4; }
tr:nth-child(even) { background: #181825; }
hr { border: none; border-top: 1px solid #45475a; margin: 1.5em 0; }
ul, ol { padding-left: 1.5em; }
li { margin: 0.2em 0; }
img { max-width: 100%; border-radius: 4px; }
del { color: #6c7086; }
</style>""";

        public Renderer () {
            hexpand = true;
            vexpand = true;

            webview = new WebKit.WebView ();
            webview.hexpand = true;
            webview.vexpand = true;

            // suppress right-click context menu
            webview.context_menu.connect ((menu, event, hit) => {
                return true;
            });

            // block link navigation — keep WebView as a renderer only
            webview.decide_policy.connect ((decision, type) => {
                if (type == WebKit.PolicyDecisionType.NAVIGATION_ACTION) {
                    var nav = (WebKit.NavigationPolicyDecision) decision;
                    if (nav.get_navigation_action ().get_navigation_type () == WebKit.NavigationType.LINK_CLICKED) {
                        decision.ignore ();
                        return true;
                    }
                }
                return false;
            });

            add (webview);
            render ("");
        }

        public void render (string text) {
            string body = _cmark_to_html (text, (size_t) text.length, 0);
            string html = "<!DOCTYPE html><html><head><meta charset='utf-8'>"
                        + CSS
                        + "</head><body>"
                        + body
                        + "</body></html>";
            webview.load_html (html, "file:///");
        }
    }
}
