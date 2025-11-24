gegl = dependency('gegl-0.4', required : false)
if not gegl.found()
    gegl = dependency('gegl-0.5')
endif

gegl_plugin_dir = gegl.get_pkgconfig_variable('libdir') / gegl.name()

# Build shared library
shared_library('gegl-gmic',
  sources: [
    'gegl_gmic.c',
    'gegl_gmic_wrapper.cpp'
  ],
  dependencies: [gegl],
  link_args: [
    '-L/usr/lib/x86_64-linux-gnu',
    '-lgmic',
    '-lm',
    '-lpthread',
    '-lX11',
  ],
  include_directories: include_directories('.'),
  name_prefix: '',
  install: true,
  install_dir: gegl_plugin_dir,
)
