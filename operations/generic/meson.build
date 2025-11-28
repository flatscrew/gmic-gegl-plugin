gegl = dependency('gegl-0.4', required : false)
if not gegl.found()
    gegl = dependency('gegl-0.5')
endif

gegl_plugin_dir = gegl.get_pkgconfig_variable('libdir') / gegl.name()

# Build shared library
shared_library('gegl-gmic',
  sources: [
    'gegl_gmic.c',
  ],
  dependencies: [gegl],
  link_args: [
    '-lcgmic',
  ],
  include_directories: include_directories('.'),
  name_prefix: '',
  install: true,
  install_dir: gegl_plugin_dir,
)
