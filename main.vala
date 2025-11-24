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

extern unowned string gmic_version_string();
extern unowned string gmic_decompress_stdlib();

void main() {
    print("G'MIC version: %s\n", gmic_version_string());
    
    var stdlib = gmic_decompress_stdlib();
    var parser = new Gmic.GmicFilterParser(Gmic.GmicFilterPredicate.has_prefix("fx_"));
    var gmic_operations = parser.parse_gmic_stdlib(stdlib);
    foreach (var operation in gmic_operations) {
        stdout.printf("\n\n%s -> %s\n", operation.name, operation.command);
        operation.print_parameters();
    }
}