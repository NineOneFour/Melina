project('melina', ['vala', 'c'],
  version: '0.1.0',
  meson_version: '>= 0.56.0',
)

cc = meson.get_compiler('c')

deps = [
  dependency('gtk+-3.0'),
  dependency('webkit2gtk-4.1'),
  cc.find_library('cmark', required: true),  # C-only link; no vapi needed
]

sources = files(
  'src/main.vala',
  'src/application.vala',
  'src/window.vala',
  'src/editor.vala',
  'src/renderer.vala',
  'src/toolbar.vala',
)

executable('melina',
  sources,
  dependencies: deps,
  install: true,
)
