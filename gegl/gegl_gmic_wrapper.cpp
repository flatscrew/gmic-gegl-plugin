#include <gmic.h>
#include <cstdio>
#include <exception>

extern "C" {

void gmic_run_rgba_float(float *rgba, int width, int height, const char *command)
{
    try {
        const int channels = 4;
        const int npixels  = width * height;
        const int total    = npixels * channels;

        // RGBA interleaved -> planar: RRR.. GGG.. BBB.. AAA..
        float *planar = new float[total];

        for (int i = 0; i < npixels; ++i) {
            planar[0 * npixels + i] = rgba[i * 4 + 0];
            planar[1 * npixels + i] = rgba[i * 4 + 1];
            planar[2 * npixels + i] = rgba[i * 4 + 2];
            planar[3 * npixels + i] = rgba[i * 4 + 3];
        }

        gmic_list<float> images;
        images.assign(1);
        gmic_image<float> &img = images(0);

        img._data      = planar;
        img._width     = width;
        img._height    = height;
        img._depth     = 1;
        img._spectrum  = channels;
        img._is_shared = true;

        gmic_list<char> names;
        names.assign(1);

        gmic(command, images, names);

        // planar -> RGBA interleaved
        float *out = images(0)._data;
        for (int i = 0; i < npixels; ++i) {
            rgba[i * 4 + 0] = out[0 * npixels + i];
            rgba[i * 4 + 1] = out[1 * npixels + i];
            rgba[i * 4 + 2] = out[2 * npixels + i];
            rgba[i * 4 + 3] = out[3 * npixels + i];
        }

        delete[] planar;
    }
    catch (const gmic_exception &e) {
        std::fprintf(stderr, "GMIC ERROR: %s\n", e.what());
    }
    catch (const std::exception &e) {
        std::fprintf(stderr, "STD EXCEPTION: %s\n", e.what());
    }
    catch (...) {
        std::fprintf(stderr, "UNKNOWN GMIC ERROR\n");
    }
}

}
