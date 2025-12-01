gegl = dependency('gegl-0.4', required : false)
if not gegl.found()
    gegl = dependency('gegl-0.5')
endif

gegl_plugin_dir = gegl.get_pkgconfig_variable('libdir') / gegl.name()
gmic_runner = files('gmic_runner.c')
inc = include_directories('.')

subdir('generic')

if get_option('with_generator')
    subdir('commands')
endif