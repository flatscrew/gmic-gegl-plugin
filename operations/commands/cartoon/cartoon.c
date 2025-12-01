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

property_double (smoothness, _("Smoothness"), 3.00)
    value_range (0.00, 10.00)
            
property_double (sharpening, _("Sharpening"), 200.00)
    value_range (0.00, 400.00)
            
property_double (edge_threshold, _("Edge Threshold"), 20.00)
    value_range (1.00, 30.00)
            
property_double (edge_thickness, _("Edge Thickness"), 0.25)
    value_range (0.00, 1.00)
            
property_double (color_strength, _("Color Strength"), 1.50)
    value_range (0.00, 3.00)
            
property_int (color_quantization, _("Color Quantization"), 8.00)
    value_range (2.00, 256.00)
            
#else

#define GEGL_OP_COMPOSER
#define GEGL_OP_NAME     gmic_cartoon
#define GEGL_OP_C_SOURCE cartoon.c

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
    asprintf(&out, "%f,%f,%f,%f,%f,%d", 
            props->smoothness,
            props->sharpening,
            props->edge_threshold,
            props->edge_thickness,
            props->color_strength,
            props->color_quantization
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
    snprintf(full_cmd, sizeof(full_cmd), "%s %s gui_merge_layers", "cartoon", properties_string(props));
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
    "name",        "gmic:cartoon",
    "title",       _("Cartoon"),
    "categories",  "generic",
    "reference-hash", "gmic_cartoon",
    "gimp:menu-path", "<Image>/Filters/G'MIC GEGL/",
    "gimp:menu-label", _("Cartoon"),
    NULL);
}

#endif
