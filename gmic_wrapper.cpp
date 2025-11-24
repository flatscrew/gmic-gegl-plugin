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

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#include <gmic.h>

extern "C" {

    const char* gmic_version_string() {
        return STR(gmic_version);
    }

    const char* gmic_decompress_stdlib() {
        const gmic_image<char>& img = gmic::decompress_stdlib();
        return img._data;
    }
}

