#include "config.h"
#include <glib/gi18n-lib.h>
#include <gegl.h>
#include <gegl-plugin.h>
#include <math.h>
#include <stdio.h>

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
    const Babl *fmt = babl_format("RGBA float");
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
    const Babl *format = babl_format("RGBA float");
    GeglRectangle full = *gegl_buffer_get_extent(input);

    int w = full.width;
    int h = full.height;

    float *fullbuf = g_malloc(w * h * 4 * sizeof(float));

    gegl_buffer_get(
        input,
        &full,
        1.0,
        format,
        fullbuf,
        w * 4 * sizeof(float),
        GEGL_ABYSS_NONE
    );

    GeglProperties *props = GEGL_PROPERTIES(operation);
    if (props->command && props->command[0])
        gmic_run_rgba_float(fullbuf, w, h, props->command);

    int rowbytes = roi->width * 4 * sizeof(float);
    float *line = g_malloc(rowbytes);

    for (int yy = 0; yy < roi->height; yy++) {

        int sy = roi->y + yy;
        const float *src = fullbuf + (sy * w + roi->x) * 4;

        memcpy(line, src, rowbytes);

        GeglRectangle scan = {
            roi->x,
            sy,
            roi->width,
            1
        };

        gegl_buffer_set(
            output,
            &scan,
            0,
            format,
            line,
            rowbytes
        );
    }

    g_free(line);
    g_free(fullbuf);
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
