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

#pragma once
#include <gegl.h>
#include <stdbool.h>

gboolean gmic_process_buffer(GeglBuffer    *input,
                             GeglBuffer    *aux,
                             GeglBuffer    *output,
                             const GeglRectangle *roi,
                             bool use_input_roi,
                             bool merge_layers,
                             gint level,
                             char *command);
