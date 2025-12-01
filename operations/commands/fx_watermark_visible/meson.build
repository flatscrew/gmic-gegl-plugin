shared_library('gmic-fx_watermark_visible',
  sources: [
    gmic_runner,
    'fx_watermark_visible.c',
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
