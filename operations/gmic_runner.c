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

 #include "gmic_runner.h"
 #include <gmic_libc.h>
 #include <glib.h>
 #include <babl/babl.h>
 #include <stdio.h>
 #include <stdbool.h>
 
 void gmic_render_error(GeglBuffer    *input,
                        GeglBuffer    *output,
                        char          *error)
 {
    const GeglRectangle *ext = gegl_buffer_get_extent(input);
    const Babl *error_fmt = babl_format("R'G'B'A float");

    GeglNode *graph = gegl_node_new();

    GeglNode *src = gegl_node_new_child(
        graph,
        "operation", "gegl:buffer-source",
        "buffer", input,
        NULL);

    GeglNode *txt = gegl_node_new_child(
        graph,
        "operation", "gegl:text",
        "string", error,
        "color", gegl_color_new("red"),
        "size", 16.0,
        NULL);

    GeglNode *over = gegl_node_new_child(
        graph,
        "operation", "gegl:over",
        NULL);

    gegl_node_link(src, over);
    gegl_node_connect(txt, "output", over, "aux");

    float *pixels = g_malloc(ext->width * ext->height * 4 * sizeof(float));

    gegl_node_blit(
        over,
        1.0,
        ext,
        error_fmt,
        pixels,
        GEGL_AUTO_ROWSTRIDE,
        GEGL_BLIT_DEFAULT);

    gegl_buffer_set(
        output,
        ext,
        0,
        error_fmt,
        pixels,
        GEGL_AUTO_ROWSTRIDE);

    g_free(pixels);
    g_object_unref(graph);
 }
 
 gboolean gmic_process_buffer(GeglBuffer    *input,
                              GeglBuffer    *aux,
                              GeglBuffer    *output,
                              const GeglRectangle *roi,
                              bool fit_gmic_output,
                              bool merge_layers,
                              gint level,
                              char *command)
 {
    if (!input) {
        g_warning("GEGL-GMIC: No input buffer provided.");
        return FALSE;
    }
    
    const Babl *input_fmt = babl_format("R'G'B' float");
    const Babl *output_fmt = babl_format("R'G'B'A float");
    
    int channels = babl_format_get_n_components(gegl_buffer_get_format(input));
    if (channels == 1) {
        input_fmt = babl_format("Y' float");
    } else if (channels == 2) {
        input_fmt = babl_format("Y'A float");
    } else if (channels == 4) {
        input_fmt = babl_format("R'G'B'A float");
    }
    
    GeglRectangle full = *gegl_buffer_get_extent(input);
    const int w = full.width;
    const int h = full.height;
    const int npix = w * h;

    float *rgba_in = g_malloc(npix * channels * sizeof(float));
    gegl_buffer_get(input, &full, 1.0f, input_fmt,
                    rgba_in, w * channels * sizeof(float),
                    GEGL_ABYSS_NONE);

    for (int i = 0; i < npix * channels; i++)
        rgba_in[i] *= 255.0f;

    float *rgba_out = rgba_in;
    int out_w = w, out_h = h, out_spectrum = channels;

    if (command && command[0]) {
        gmic_interface_image imgs[2];
        unsigned int count = 1;

        memset(imgs, 0, sizeof(imgs));

        strcpy(imgs[0].name, "input");
        imgs[0].data           = rgba_in;
        imgs[0].width          = w;
        imgs[0].height         = h;
        imgs[0].depth          = 1;
        imgs[0].spectrum       = channels;
        imgs[0].is_interleaved = true;
        imgs[0].format         = E_FORMAT_FLOAT;

        float *aux_buf = NULL;

        if (aux) {
            printf("using aux input...\n");
            
            GeglRectangle aux_ext = *gegl_buffer_get_extent(aux);
            int aw = aux_ext.width;
            int ah = aux_ext.height;
            int ach = babl_format_get_n_components(gegl_buffer_get_format(aux));

            const Babl *aux_fmt;
            if (ach == 1) aux_fmt = babl_format("Y' float");
            else if (ach == 2) aux_fmt = babl_format("Y'A float");
            else if (ach == 3) aux_fmt = babl_format("R'G'B' float");
            else aux_fmt = babl_format("R'G'B'A float");

            aux_buf = g_malloc(aw * ah * ach * sizeof(float));

            gegl_buffer_get(aux, &aux_ext, 1.0f, aux_fmt,
                            aux_buf, aw * ach * sizeof(float),
                            GEGL_ABYSS_NONE);

            for (int i = 0; i < aw * ah * ach; i++)
                aux_buf[i] *= 255.0f;

            strcpy(imgs[1].name, "aux");
            imgs[1].data           = aux_buf;
            imgs[1].width          = aw;
            imgs[1].height         = ah;
            imgs[1].depth          = 1;
            imgs[1].spectrum       = ach;
            imgs[1].is_interleaved = true;
            imgs[1].format         = E_FORMAT_FLOAT;

            count = 2;
        }

        char error_buffer[4096];
        error_buffer[0] = '\0';

        gmic_interface_options opt;
        memset(&opt, 0, sizeof(opt));
        opt.interleave_output     = true;
        opt.output_format         = E_FORMAT_FLOAT;
        opt.ignore_stdlib         = false;
        opt.no_inplace_processing = true;
        opt.error_message_buffer  = error_buffer;

        char full_cmd[2048];
        const char *merge = merge_layers ? " gui_merge_layers" : "";
        if (fit_gmic_output) {
            snprintf(full_cmd, sizeof(full_cmd),
                    "WH:=w,h %s%s r $WH,1,100%%,2",
                    command,
                    merge);
        } else {
            snprintf(full_cmd, sizeof(full_cmd),
                    "%s%s",
                    command,
                    merge);
        }


        printf("running g'mic command: %s\n", full_cmd);
        gmic_call(full_cmd, &count, imgs, &opt);

        if (error_buffer[0] != '\0') {
            gmic_render_error(input, output, error_buffer);
            if (aux_buf) g_free(aux_buf);
            g_free(rgba_in);
            return TRUE;
        }

        rgba_out     = imgs[0].data;
        out_w        = imgs[0].width;
        out_h        = imgs[0].height;
        out_spectrum = imgs[0].spectrum;
        
        GeglRectangle out_ext = {0, 0, out_w, out_h};
        gegl_buffer_set_extent(output, &out_ext);

        if (aux_buf) g_free(aux_buf);
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
 