// Copyright (C) 2025 Łukasz 'activey' Grabski
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

#include "config.h"
#include "gmic_runner.h"
#include <glib/gi18n-lib.h>
#include <gegl.h>
#include <gegl-plugin.h>
#include <math.h>
#include <stdio.h>
#include <gmic_libc.h>

#ifdef GEGL_PROPERTIES
enum_start (shapes_type)
    enum_value (SHAPES_PROCEDURAL, "procedural", N_("Procedural"))
    enum_value (SHAPES_OPAQUE_REGIONS_ON_TOP_LAYER, "opaque-regions-on-top-layer", N_("Opaque Regions on Top Layer"))
  enum_end (ShapesType)



property_enum (shapes, _("Shapes"), ShapesType, shapes_type, 0)
            
property_double (density, _("Density"), 20.00)
    value_range (0.00, 100.00)
            
property_double (radius, _("Radius"), 2.00)
    value_range (0.00, 5.00)
            
property_double (variability, _("Variability"), 80.00)
    value_range (0.00, 100.00)
            
property_int (random_seed, _("Random Seed"), 0.00)
    value_range (0.00, 16384.00)
            
property_double (refraction, _("Refraction"), 3.00)
    value_range (0.00, 20.00)
            
property_double (light_angle, _("Light Angle"), 35.00)
    value_range (0.00, 360.00)
            
property_double (specular_size, _("Specular Size"), 10.00)
    value_range (0.00, 100.00)
            
property_double (specular_intensity, _("Specular Intensity"), 1.00)
    value_range (0.00, 1.00)
            
property_double (specular_centering, _("Specular Centering"), 0.50)
    value_range (0.00, 1.00)
            
property_double (shadow_size, _("Shadow Size"), 0.25)
    value_range (0.00, 3.00)
            
property_double (shadow_intensity, _("Shadow Intensity"), 0.50)
    value_range (0.00, 1.00)
            
property_double (shadow_smoothness, _("Shadow Smoothness"), 0.75)
    value_range (0.00, 3.00)
            
property_double (diffuse_shadow, _("Diffuse Shadow"), 0.05)
    value_range (0.00, 3.00)
            
property_double (smoothness, _("Smoothness"), 0.15)
    value_range (0.00, 3.00)
            
property_boolean (output_as_separate_layers, _("Output as Separate Layers"), 1)
            
#else

#define GEGL_OP_COMPOSER
#define GEGL_OP_NAME     gmic_fx_drop_water
#define GEGL_OP_C_SOURCE fx_drop_water.c

#include "gegl-op.h"

void gmic_run_rgba_float(float *data, int width, int height, const char *command);

static void prepare (GeglOperation *operation)
{
    const Babl *fmt = babl_format("R'G'B'A float");
    gegl_operation_set_format(operation, "input",  fmt);
    gegl_operation_set_format(operation, "aux",  fmt);
    gegl_operation_set_format(operation, "output", fmt);
}

static char* properties_string(GeglProperties *props) {
    char *out = NULL;
    asprintf(&out, "%d,%f,%f,%f,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d", 
            props->shapes,
            props->density,
            props->radius,
            props->variability,
            props->random_seed,
            props->refraction,
            props->light_angle,
            props->specular_size,
            props->specular_intensity,
            props->specular_centering,
            props->shadow_size,
            props->shadow_intensity,
            props->shadow_smoothness,
            props->diffuse_shadow,
            props->smoothness,
            props->output_as_separate_layers
          );
    return out;
}

static gboolean
process (GeglOperation *operation,
         GeglBuffer    *input,
         GeglBuffer    *aux,
         GeglBuffer    *output,
         const GeglRectangle *roi,
         gint level)
{
    
    GeglProperties *props = GEGL_PROPERTIES(operation);

    char full_cmd[2048];
    snprintf(full_cmd, sizeof(full_cmd), "%s %s gui_merge_layers", "fx_drop_water", properties_string(props));
    return gmic_process_buffer(input, aux, output, roi, level, full_cmd);
}

static GeglRectangle
get_cached_region (GeglOperation *operation,
                   const GeglRectangle *roi)
{
    GeglRectangle full =
        *gegl_operation_source_get_bounding_box (operation, "input");
    return full;
}

static GeglRectangle
get_required_for_output (GeglOperation       *operation,
                         const gchar         *input_pad,
                         const GeglRectangle *roi)
{
  GeglRectangle result = *gegl_operation_source_get_bounding_box (operation, "input");
  if (gegl_rectangle_is_infinite_plane (&result))
    return *roi;

  return result;
}

static void
gegl_op_class_init (GeglOpClass *klass)
{
  GeglOperationClass       *operation_class;
  GeglOperationComposerClass *filter_class;

  operation_class = GEGL_OPERATION_CLASS (klass);
  filter_class    = GEGL_OPERATION_COMPOSER_CLASS (klass);

  filter_class->process = process;
  operation_class->prepare = prepare;
  operation_class->threaded = FALSE;
  operation_class->get_cached_region = get_cached_region;
  operation_class->get_required_for_output = get_required_for_output;
  
  gegl_operation_class_set_keys (operation_class,
    "name",        "gmic:fx_drop_water",
    "title",       _("Drop Water"),
    "categories",  "generic",
    "reference-hash", "gmic_fx_drop_water",
    "gimp:menu-path", "<Image>/Filters/G'MIC GEGL/",
    "gimp:menu-label", _("Drop Water"),
    NULL);
}

#endif
