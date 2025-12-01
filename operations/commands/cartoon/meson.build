shared_library('gmic-cartoon',
  sources: [
    gmic_runner,
    'cartoon.c',
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
