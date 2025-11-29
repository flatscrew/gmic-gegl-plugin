/**
 * Copyright (C) 2025 Łukasz 'activey' Grabski
 * 
 * This file is part of RasterFlow.
 * 
 * RasterFlow is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * RasterFlow is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "config.h"
#include "gmic_runner.h"
#include <glib/gi18n-lib.h>
#include <gegl.h>
#include <gegl-plugin.h>
#include <math.h>
#include <stdio.h>
#include <gmic_libc.h>

#ifdef GEGL_PROPERTIES

property_string(command, _("G'MIC Command"), "")
    description(_("G'MIC command to run on the input buffer"))

#else

#define GEGL_OP_COMPOSER
#define GEGL_OP_NAME     geglgmic
#define GEGL_OP_C_SOURCE gegl_gmic.c

#include "gegl-op.h"

void gmic_run_rgba_float(float *data, int width, int height, const char *command);

static void prepare (GeglOperation *operation)
{
    const Babl *fmt = babl_format("R'G'B'A float");
    gegl_operation_set_format(operation, "input",  fmt);
    gegl_operation_set_format(operation, "aux",  fmt);
    gegl_operation_set_format(operation, "output", fmt);
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

    if (props->command && props->command[0]) {
        char full_cmd[2048];
        snprintf(full_cmd, sizeof(full_cmd), "%s gui_merge_layers", props->command);
        
        return gmic_process_buffer(input, aux, output, roi, level, full_cmd);
    }
    
    return FALSE;
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
    "name",        "gmic:command",
    "title",       _("Run G'MIC command"),
    "categories",  "generic",
    "reference-hash", "gmicruncommand",
    "description", _("Runs G'MIC command, EXPERIMENTAL!"),
    "gimp:menu-path", "<Image>/Filters/G'MIC GEGL/",
    "gimp:menu-label", _("G'MIC GEGL..."),
    NULL);
}

#endif
