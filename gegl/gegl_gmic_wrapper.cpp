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
