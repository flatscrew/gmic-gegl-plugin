# Build shared library
shared_library('gmic-fx_tk_metallic',
  sources: [
    gmic_runner,
    'enums.c',
    'fx_tk_metallic.c',
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
