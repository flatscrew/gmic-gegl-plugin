public class OperationsMesonBuildGenerator {

    private Template.TemplateLocator locator;

    public OperationsMesonBuildGenerator(Template.TemplateLocator locator) {
        this.locator = locator;
    }

    public void generate_build_file(List<Gmic.GmicFilter> gmic_operations, File output_file) {
        var template = new Template.Template(locator);
        var scope = new Template.Scope();

        var commands = new string[gmic_operations.length()];
        int i = 0;
        foreach (var op in gmic_operations) {
            if (Blacklist.instance.is_blacklisted(op.command)) {
                continue;
            }
            
            commands[i++] = op.command;
        }

        scope.set_strv("commands", commands);

        try {
            if (template.parse_path("templates/commands_meson.build.meson.tmpl")) {
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
