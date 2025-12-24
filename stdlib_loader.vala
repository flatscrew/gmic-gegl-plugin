namespace Gmic {

    static string? load_stdlib () {
        string base_dir;
        if (Environment.get_variable("APPDATA") != null) {
            base_dir = Environment.get_variable("APPDATA");
        } else {
            base_dir = Environment.get_user_config_dir();
        }

        var gmic_dir = Path.build_filename (base_dir, "gmic");
        try {
            var dir = File.new_for_path (gmic_dir);
            var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo info;
            while ((info = enumerator.next_file ()) != null) {
                var name = info.get_name();

                if (name.has_prefix("update") && name.has_suffix(".gmic")) {
                    message("using stdlib from: %s", name);
                    
                    var path = Path.build_filename (gmic_dir, name);
                    string contents;
                    FileUtils.get_contents (path, out contents);
                    return contents;
                }
            }
        } catch (Error e) {
            warning("Unable to load update file, %s", e.message);
        }

        return null;
    }

}
