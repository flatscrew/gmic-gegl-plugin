project('gmic-test', ['vala', 'cpp'])

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gee-0.8'),
  dependency('gegl-0.4'),
  dependency('template-glib-1.0')
]

gmic_filter = files('gmic_filter.vala')
gmic_wrapper = files('gmic_wrapper.cpp')

main_sources = [
  gmic_wrapper,
  gmic_filter,
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

subdir('operations')
subdir('gmictest')

if get_option('with_generator')
  subdir('generator')
endif