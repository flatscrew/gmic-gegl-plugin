project('gmic-test', ['vala', 'cpp'])

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gegl-0.4')
]

gmic_wrapper = 'gmic_wrapper.cpp'

sources = [
  gmic_wrapper,
  'gmic_filter.vala',
  'main.vala'
]

inc = include_directories('.')

executable(
  'gmic-parser',
  sources,
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