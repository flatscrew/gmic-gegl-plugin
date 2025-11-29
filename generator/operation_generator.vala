public class OperationGenerator {

    private Template.TemplateLocator locator;

    public OperationGenerator(Template.TemplateLocator locator) {
        this.locator = locator;
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
}
