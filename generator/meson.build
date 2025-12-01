generator_sources = [
  gmic_wrapper,
  'operations_meson_build_generator.vala',
  'operation_generator.vala',
  'generator.vala',
  gmic_filter
]

executable(
  'gmic-gegl-generator',
  generator_sources,
  dependencies: dependencies,
  include_directories: include_directories('/usr/include'),
  link_args: [
    '-L/usr/lib/x86_64-linux-gnu',
    '-lgmic',
    '-lm',
    '-lpthread',
    '-lX11',
  ]
)