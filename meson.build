project('gmic-test', ['vala', 'cpp'])

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gee-0.8'),
  dependency('gegl-0.4'),
  dependency('template-glib-1.0')
]

gmic_wrapper = 'gmic_wrapper.cpp'

main_sources = [
  gmic_wrapper,
  'gmic_filter.vala',
  'main.vala'
]

inc = include_directories('.')

executable(
  'gmic-parser',
  main_sources,
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

generator_sources = [
  gmic_wrapper,
  'generator/operations_meson_build_generator.vala',
  'generator/operation_generator.vala',
  'gmic_filter.vala',
  'generator.vala'
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

subdir('operations')
subdir('gmictest')