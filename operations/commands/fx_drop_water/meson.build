shared_library('gmic-fx_drop_water',
  sources: [
    gmic_runner,
    'fx_drop_water.c',
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
