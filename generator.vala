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
    private static string? output_dir = null;
    
    private const OptionEntry[] options = {
        {
            "commands",
            0,
            0,
            OptionArg.STRING_ARRAY,
            ref include_commands,
            "Use only given commands",
            "COMMANDS..."
        },
        {
            "output-dir",
            0,
            0,
            OptionArg.STRING,
            ref output_dir,
            "Directory where subdirectories for commands will be generated",
            "DIR"
        },
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
        
        if (output_dir == null) {
            stderr.printf("ERROR: --output-dir is required\n");
            return 1;
        }

        if (DirUtils.create_with_parents(output_dir, 0777) != 0) {
            error("ERROR: Cannot create output directory %s\n", output_dir);
        }
        
        var stdlib = gmic_decompress_stdlib();
        var parser = new Gmic.GmicFilterParser(
            Gmic.GmicFilterPredicate.any().and(Gmic.GmicFilterPredicate.is_any_of(include_commands))
        );
        var gmic_operations = parser.parse_gmic_stdlib(stdlib);
        
        var template_locator = new Template.TemplateLocator();
        template_locator.append_search_path("./templates");
        
        var dest_dir = File.new_for_path(output_dir);
        var meson_generator = new OperationsMesonBuildGenerator(template_locator);
        meson_generator.generate_build_file(gmic_operations, dest_dir.get_child("meson.build"));
        
        var generator = new OperationGenerator(template_locator);
        foreach (var operation in gmic_operations) {
            message("Creating directory for: %s", operation.command);
            
            var op_dir = dest_dir.get_child(operation.command);
            if (DirUtils.create_with_parents(op_dir.get_path(), 0777) != 0) {
                error("ERROR: Cannot create output directory %s\n", output_dir);
            }
            
            generator.generate_c_file(operation, op_dir.get_child("%s.c".printf(operation.command)));
        }
        
        return 0;
    }
}

