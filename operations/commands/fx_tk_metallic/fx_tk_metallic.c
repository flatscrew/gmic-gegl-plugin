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

property_double (strength, "Strength", 1.0)
  value_range (0.0, 1.0)

property_double (smoothness, "Smoothness", 0.0)
  value_range (0.0, 20.0)
  
property_enum(metal, "Metal", MetalType, metal_type, METAL_SILVER)
  
#else

#define GEGL_OP_COMPOSER
#define GEGL_OP_NAME     gmicfxtkmetallic
#define GEGL_OP_C_SOURCE fx_tk_metallic.c
#include "enums.h"

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
    asprintf(&out, "%f,%f,%d", props->strength, props->smoothness, props->metal);
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
    if (!input) {
        g_warning("GEGL-GMIC: No input buffer provided.");
        return FALSE;
    }
    
    if (!aux) {
        printf("AUX NULL!\n");    
    }
    
    int channels = babl_format_get_n_components(gegl_buffer_get_format(input));
    const Babl *fmt = babl_format("R'G'B' float");
    if (channels == 4) {
        fmt = babl_format("R'G'B'A float");
    }
    const Babl *output_fmt = babl_format("R'G'B'A float");
    
    GeglRectangle full = *gegl_buffer_get_extent(input);
    const int w = full.width;
    const int h = full.height;
    const int npix = w * h;

    float *rgba_in = g_malloc(npix * channels * sizeof(float));
    gegl_buffer_get(input, &full, 1.0f, fmt,
                    rgba_in, w * channels * sizeof(float),
                    GEGL_ABYSS_NONE);

    for (int i = 0; i < npix * channels; i++)
        rgba_in[i] *= 255.0f;

    float *rgba_out = rgba_in;
    int out_w = w, out_h = h, out_spectrum = channels;

    gmic_interface_image img;
    memset(&img, 0, sizeof(img));

    strcpy(img.name, "input");

    img.data          = rgba_in;
    img.width         = w;
    img.height        = h;
    img.depth         = 1;
    img.spectrum      = channels;
    img.is_interleaved = true;
    img.format        = E_FORMAT_FLOAT;

    unsigned int count = 1;

    char error_buffer[4096];
    error_buffer[0] = '\0';
    
    gmic_interface_options opt;
    memset(&opt, 0, sizeof(opt));
    opt.interleave_output     = true;
    opt.output_format         = E_FORMAT_FLOAT;
    opt.ignore_stdlib         = false;
    opt.no_inplace_processing = true;
    opt.error_message_buffer = error_buffer;

    GeglProperties *props = GEGL_PROPERTIES(operation);
    char full_cmd[2048];
    snprintf(full_cmd, sizeof(full_cmd), "%s %s gui_merge_layers", "fx_tk_metallic", properties_string(props));
    gmic_call(full_cmd, &count, &img, &opt);
    
    if (error_buffer[0] != '\0') {
        g_warning("GEGL-GMIC error: %s", error_buffer);
    
        rgba_out = rgba_in;
        out_w = w;
        out_h = h;
        out_spectrum = channels;
        
        if (rgba_out != rgba_in)
            gmic_delete_external(rgba_out);
    } else {
        rgba_out     = (float*)img.data;
        out_w        = img.width;
        out_h        = img.height;
        out_spectrum = img.spectrum;
    }

    float *line = g_malloc(roi->width * 4 * sizeof(float));
    const float inv255 = 1.0f / 255.0f;

    for (int yy = 0; yy < roi->height; yy++) {

        int sy = roi->y + yy;
        if (sy < 0 || sy >= out_h)
            continue;

        for (int x = 0; x < roi->width; x++) {

            int ix = roi->x + x;
            if (ix < 0 || ix >= out_w) {
                line[4*x+0] = 0.0f;
                line[4*x+1] = 0.0f;
                line[4*x+2] = 0.0f;
                line[4*x+3] = 1.0f;
                continue;
            }

            int idx = (sy*out_w + ix) * out_spectrum;
            const float *p = rgba_out + idx;

            float r = (out_spectrum > 0) ? p[0] : 0;
            float g = (out_spectrum > 1) ? p[1] : r;
            float b = (out_spectrum > 2) ? p[2] : r;
            float a = (out_spectrum > 3) ? p[3] : 255.0f;

            line[4*x+0] = r * inv255;
            line[4*x+1] = g * inv255;
            line[4*x+2] = b * inv255;
            line[4*x+3] = a * inv255;
        }

        GeglRectangle scan = { roi->x, sy, roi->width, 1 };
        gegl_buffer_set(output, &scan, 0, output_fmt,
                        line, roi->width * 4 * sizeof(float));
    }

    g_free(line);
    g_free(rgba_in);

    if (rgba_out != rgba_in)
        gmic_delete_external(rgba_out);

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
  GeglOperationComposerClass *filter_class;

  operation_class = GEGL_OPERATION_CLASS (klass);
  filter_class    = GEGL_OPERATION_COMPOSER_CLASS (klass);

  filter_class->process = process;
  operation_class->prepare = prepare;
  operation_class->threaded = FALSE;
  operation_class->get_cached_region = get_cached_region;
  operation_class->get_required_for_output = get_required_for_output;
  
  gegl_operation_class_set_keys (operation_class,
    "name",        "gmic:fx_tk_metallic",
    "title",       _("Metallic Look"),
    "categories",  "generic",
    "reference-hash", "gmicfxtkmetallic",
    "gimp:menu-path", "<Image>/Filters/G'MIC GEGL/",
    "gimp:menu-label", _("Metallic Look"),
    NULL);
}

#endif
