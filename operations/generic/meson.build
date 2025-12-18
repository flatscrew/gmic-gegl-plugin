# Build shared library

shared_library('gegl-gmic',
  sources: [
    gmic_runner, 'gegl_gmic.c',
  ],
  dependencies: [gegl],
  link_args: [
    '-lcgmic',
  ],
  include_directories: inc,
  name_prefix: '',
  install: true,
  install_dir: gegl_plugin_dir,
)
