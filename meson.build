project('gmic-test', ['vala', 'c', 'cpp'])

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gee-0.8'),
  dependency('template-glib-1.0')
]

normalizator = files('normalizator.vala')
gmic_filter = files('gmic_filter.vala')
gmic_wrapper = files('gmic_wrapper.cpp')

main_sources = [
  gmic_wrapper,
  gmic_filter,
  normalizator,
  'main.vala'
]

inc = include_directories('.')

if get_option('with_aux')
  add_project_arguments(['-DWITH_AUX'], language: 'c')
endif

executable(
  'gmic-parser',
  main_sources,
  dependencies: dependencies,
  include_directories: include_directories('/usr/include'),
  link_args: [
    '-lgmic'
  ]
)

test_sources = [
  normalizator,
  'test_normalizator.vala'
]

test_executable = executable(
  'test-normalize',
  test_sources,
  dependencies: dependencies,
)

test(
  'normalize',
  test_executable
)

subdir('operations')
subdir('gmictest')

if get_option('with_generator')
  subdir('generator')
endif