generator_sources = [
  normalizator,
  stdlib_loader,
  gmic_filter,
  'operations_meson_build_generator.vala',
  'operation_generator.vala',
  'blacklist.vala',
  'generator.vala'
]

executable(
  'gmic-gegl-generator',
  generator_sources,
  dependencies: dependencies,
  include_directories: include,
  link_args: [
    '-lcgmic',
  ]
)