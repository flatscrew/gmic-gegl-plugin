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

#define GEGL_OP_FILTER
#define GEGL_OP_NAME     geglgmic
#define GEGL_OP_C_SOURCE gegl_gmic.c

#include "gegl-op.h"

void gmic_run_rgba_float(float *data, int width, int height, const char *command);

static void prepare (GeglOperation *operation)
{
    const Babl *fmt = babl_format("RGB float");
    gegl_operation_set_format(operation, "input",  fmt);
    gegl_operation_set_format(operation, "output", fmt);
}

static gboolean
process (GeglOperation *operation,
         GeglBuffer    *input,
         GeglBuffer    *output,
         const GeglRectangle *roi,
         gint level)
{
    const Babl *fmt = babl_format("RGB float");

    GeglRectangle full = *gegl_buffer_get_extent(input);
    int w = full.width;
    int h = full.height;
    int npix = w * h;

    float *rgb = g_malloc(npix * 3 * sizeof(float));
    gegl_buffer_get(input, &full, 1.0, fmt, rgb, w * 3 * sizeof(float), GEGL_ABYSS_NONE);

    float *rgba_in = g_malloc(npix * 4 * sizeof(float));
    for (int i = 0; i < npix; i++) {
        rgba_in[4*i+0] = rgb[3*i+0];
        rgba_in[4*i+1] = rgb[3*i+1];
        rgba_in[4*i+2] = rgb[3*i+2];
        rgba_in[4*i+3] = 1.0f;
    }

    float *rgba_out = rgba_in;
    int out_w = w;
    int out_h = h;
    int out_spectrum = 4;

    GeglProperties *p = GEGL_PROPERTIES(operation);
    if (p->command && p->command[0]) {
        gmic_interface_image im = {0};
        strcpy(im.name, "input");
        im.data = rgba_in;
        im.width = w;
        im.height = h;
        im.depth = 1;
        im.spectrum = 4;
        im.is_interleaved = true;
        im.format = E_FORMAT_FLOAT;

        unsigned int count = 1;

        gmic_interface_options opt = {0};
        opt.interleave_output = true;
        opt.output_format = E_FORMAT_FLOAT;
        opt.ignore_stdlib = false;
        opt.no_inplace_processing = true;

        gmic_call(p->command, &count, &im, &opt);

        rgba_out = (float *)im.data;
        out_w = im.width;
        out_h = im.height;
        out_spectrum = im.spectrum;
    }

    float *line = g_malloc(roi->width * 3 * sizeof(float));

    for (int yy = 0; yy < roi->height; yy++) {
        int sy = roi->y + yy;
        if (sy < 0 || sy >= out_h)
            continue;

        const float *row = rgba_out + (sy * out_w + roi->x) * out_spectrum;

        for (int x = 0; x < roi->width; x++) {
            int ix = roi->x + x;
            if (ix < 0 || ix >= out_w)
                continue;

            const float *p0 = row + x * out_spectrum;
            line[3*x+0] = p0[0];
            line[3*x+1] = p0[1];
            line[3*x+2] = p0[2];
        }

        GeglRectangle scan = { roi->x, sy, roi->width, 1 };
        gegl_buffer_set(output, &scan, 0, fmt, line, roi->width * 3 * sizeof(float));
    }

    g_free(line);
    g_free(rgb);

    if (rgba_out != rgba_in)
        gmic_delete_external(rgba_out);
    g_free(rgba_in);

    return TRUE;
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
  GeglOperationFilterClass *filter_class;

  operation_class = GEGL_OPERATION_CLASS (klass);
  filter_class    = GEGL_OPERATION_FILTER_CLASS (klass);

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
    "flags", "no-tiling",
    NULL);
}

#endif
