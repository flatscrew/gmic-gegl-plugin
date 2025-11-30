public class OperationGenerator {

    private Template.TemplateLocator locator;

    public OperationGenerator(Template.TemplateLocator locator) {
        this.locator = locator;
    }

    public void generate_enums_h_file(Gmic.GmicFilter gmic_filter, File output_file) {
        var template = new Template.Template(locator);
        
        StringBuilder output = new StringBuilder();
        foreach (var param in gmic_filter.parameters) {
            var choice_param = param as Gmic.GmicChoiceParam;
            if (choice_param == null) continue;
            
            var scope = new Template.Scope();
            scope["choice"].assign_object(choice_param);
            
            try {
                message("Generating file: %s", output_file.get_path());
                
                if (template.parse_path("templates/op.enum.h.tmpl")) {
                    string result = template.expand_string(scope);
                    output.append(result).append("\n");
                } else {
                    warning("Could not generate %s :(", output_file.get_path());
                }
            } catch (Error e) {
                warning("Template error: %s", e.message);
            }
        }
        
        try {
            FileUtils.set_contents(output_file.get_path(), output.str);
        } catch (Error e) {
            warning("Template error: %s", e.message);
        }
    }
    
    public void generate_enums_c_file(Gmic.GmicFilter gmic_filter, File output_file) {
        var template = new Template.Template(locator);
        
        foreach (var param in gmic_filter.parameters) {
            var choice_param = param as Gmic.GmicChoiceParam;
            if (choice_param == null) continue;
            
            
            var scope = new Template.Scope();
            scope["filter"].assign_object(gmic_filter);

            try {
                message("Generating file: %s", output_file.get_path());
                
                if (template.parse_path("templates/op.enum.c.tmpl")) {
                    string result = template.expand_string(scope);
                    FileUtils.set_contents(output_file.get_path(), result);
                } else {
                    warning("Could not generate %s :(", output_file.get_path());
                }
            } catch (Error e) {
                warning("Template error: %s", e.message);
            }
            
        }
        
    }
    
    public void generate_c_file(Gmic.GmicFilter gmic_filter, File output_file) {
        var template = new Template.Template(locator);
        var scope = new Template.Scope();

        scope["filter"].assign_object(gmic_filter);

        try {
            message("Generating file: %s", output_file.get_path());
            
            if (template.parse_path("templates/op.c.tmpl")) {
                string result = template.expand_string(scope);
                FileUtils.set_contents(output_file.get_path(), result);
            } else {
                warning("Could not generate %s :(", output_file.get_path());
            }
        } catch (Error e) {
            warning("Template error: %s", e.message);
        }
    }
    
    public void generate_build_file(Gmic.GmicFilter gmic_filter, File output_file) {
        var template = new Template.Template(locator);
        var scope = new Template.Scope();

        scope["filter"].assign_object(gmic_filter);

        try {
            if (template.parse_path("templates/op.meson.build.tmpl")) {
                string result = template.expand_string(scope);
                FileUtils.set_contents(output_file.get_path(), result);
            } else {
                warning("Could not generate meson.build :(");
            }
        } catch (Error e) {
            warning("Template error: %s", e.message);
        }
    }
}
