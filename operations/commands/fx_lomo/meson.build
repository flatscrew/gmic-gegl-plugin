shared_library('gmic-fx_lomo',
  sources: [
    gmic_runner,
    'fx_lomo.c',
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
