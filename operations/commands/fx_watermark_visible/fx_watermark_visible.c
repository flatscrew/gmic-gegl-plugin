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
enum_start (font_type)
    enum_value (FONT_ACME, "acme", N_("Acme"))
    enum_value (FONT_ARIAL, "arial", N_("Arial"))
    enum_value (FONT_ARIAL_BLACK, "arial-black", N_("Arial Black"))
    enum_value (FONT_BLACK_OPS_ONE, "black-ops-one", N_("Black Ops One"))
    enum_value (FONT_BLACK_CHANCERY, "black-chancery", N_("Black Chancery"))
    enum_value (FONT_CABIN_SKETCH, "cabin-sketch", N_("Cabin Sketch"))
    enum_value (FONT_CAPRASIMO, "caprasimo", N_("Caprasimo"))
    enum_value (FONT_CARNEVALEE_FREAKSHOW, "carnevalee-freakshow", N_("Carnevalee Freakshow"))
    enum_value (FONT_CHEESE_BURGER, "cheese-burger", N_("Cheese Burger"))
    enum_value (FONT_CHEQUE, "cheque", N_("Cheque"))
    enum_value (FONT_CHEQUE_BLACK, "cheque-black", N_("Cheque Black"))
    enum_value (FONT_CHLORINAR, "chlorinar", N_("Chlorinar"))
    enum_value (FONT_COMIC_SANS_MS, "comic-sans-ms", N_("Comic Sans MS"))
    enum_value (FONT_COURIER_NEW, "courier-new", N_("Courier New"))
    enum_value (FONT_CREEPSTER, "creepster", N_("Creepster"))
    enum_value (FONT_GEORGIA, "georgia", N_("Georgia"))
    enum_value (FONT_HIDAYATULLAH, "hidayatullah", N_("Hidayatullah"))
    enum_value (FONT_IMPACT, "impact", N_("Impact"))
    enum_value (FONT_JARO, "jaro", N_("Jaro"))
    enum_value (FONT_LOBSTER, "lobster", N_("Lobster"))
    enum_value (FONT_LUCKIEST_GUY, "luckiest-guy", N_("Luckiest Guy"))
    enum_value (FONT_MACONDO, "macondo", N_("Macondo"))
    enum_value (FONT_MEDIEVAL_SHARP, "medieval-sharp", N_("Medieval Sharp"))
    enum_value (FONT_ODIN_ROUNDED, "odin-rounded", N_("Odin Rounded"))
    enum_value (FONT_OSWALD, "oswald", N_("Oswald"))
    enum_value (FONT_PALATINO_LINOTYPE, "palatino-linotype", N_("Palatino Linotype"))
    enum_value (FONT_PLAYFAIR_DISPLAY, "playfair-display", N_("Playfair Display"))
    enum_value (FONT_ROBOTO, "roboto", N_("Roboto"))
    enum_value (FONT_SATISFY, "satisfy", N_("Satisfy"))
    enum_value (FONT_SOFIA, "sofia", N_("Sofia"))
    enum_value (FONT_SUNDAY_MILK, "sunday-milk", N_("Sunday Milk"))
    enum_value (FONT_TEX_GYRE_ADVENTOR, "tex-gyre-adventor", N_("Tex Gyre Adventor"))
    enum_value (FONT_TIMES_NEW_ROMAN, "times-new-roman", N_("Times New Roman"))
    enum_value (FONT_TITAN_ONE, "titan-one", N_("Titan One"))
    enum_value (FONT_TYPEWRITER, "typewriter", N_("Typewriter"))
    enum_value (FONT_VERDANA, "verdana", N_("Verdana"))
  enum_end (FontType)


enum_start (lightness_type)
    enum_value (LIGHTNESS_DARKER, "darker", N_("Darker"))
    enum_value (LIGHTNESS_BRIGHTER, "brighter", N_("Brighter"))
  enum_end (LightnessType)



property_string (text, _("Text"), "\\251 G'MIC")
            
property_double (opacity, _("Opacity"), 0.40)
    value_range (0.00, 1.00)
            
property_enum (font, _("Font"), FontType, font_type, 27)
            
property_int (size, _("Size"), 50.00)
    value_range (13.00, 512.00)
            
property_boolean (bold_face, _("Bold Face"), 0)
            
property_double (angle, _("Angle"), 25.00)
    value_range (0.00, 360.00)
            
property_enum (lightness, _("Lightness"), LightnessType, lightness_type, 1)
            
property_double (smoothness, _("Smoothness"), 0.50)
    value_range (0.00, 5.00)
            
#else

#define GEGL_OP_COMPOSER
#define GEGL_OP_NAME     gmic_fx_watermark_visible
#define GEGL_OP_C_SOURCE fx_watermark_visible.c

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
    asprintf(&out, "\"%s\",%f,%d,%d,%d,%f,%d,%f", 
            props->text,
            props->opacity,
            props->font,
            props->size,
            props->bold_face,
            props->angle,
            props->lightness,
            props->smoothness
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
    snprintf(full_cmd, sizeof(full_cmd), "%s %s gui_merge_layers", "fx_watermark_visible", properties_string(props));
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
    "name",        "gmic:fx_watermark_visible",
    "title",       _("Visible Watermark"),
    "categories",  "generic",
    "reference-hash", "gmic_fx_watermark_visible",
    "gimp:menu-path", "<Image>/Filters/G'MIC GEGL/",
    "gimp:menu-label", _("Visible Watermark"),
    NULL);
}

#endif
