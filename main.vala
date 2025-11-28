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

class Main : Object {
    
    [CCode (array_length = false, array_null_terminated = true)]
	private static string[]? include_commands = null;
    
    private static bool show_parameters = false;
    
    private const OptionEntry[] options = {
        {
            "commands",
            0,
            0,
            OptionArg.STRING_ARRAY,
            ref include_commands,
            "Display only given commands",
            "COMMANDS..."
        },
        { 
            "parameters", 
            '\0', 
            OptionFlags.NONE, 
            OptionArg.NONE, 
            ref show_parameters, 
            "Show command parameters", null },
        {
            "help",
            'h',
            0,
            OptionArg.NONE,
            null,
            "Show help",
            null
        },
        { null }
    };
    
    public static int main(string[] args) {
        var context = new OptionContext("- G'MIC stdlib parser");
        context.set_help_enabled(true);
        context.add_main_entries(options, null);
    
        try {
            context.parse(ref args);
        } catch (OptionError e) {
            stderr.printf("%s\n", e.message);
            return 1;
        }
        
        info("G'MIC version: %s\n", gmic_version_string());
        
        var stdlib = gmic_decompress_stdlib();
        var parser = new Gmic.GmicFilterParser(
            Gmic.GmicFilterPredicate.has_prefix("fx_").and(Gmic.GmicFilterPredicate.is_any_of(include_commands))
        );
        var gmic_operations = parser.parse_gmic_stdlib(stdlib);
        foreach (var operation in gmic_operations) {
            stdout.printf("%s -> %s\n", operation.name, operation.command);
            
            if (show_parameters) {
                operation.print_parameters();
                stdout.printf("\n\n");
            }
        }
        
        return 0;
    }
}

