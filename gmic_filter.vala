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

namespace Gmic {
    
    string normalize(
        string text, 
        bool remove_parenthesis = true, 
        string space_replacemenet = "") 
    {
        var normalized = text;
        if (remove_parenthesis) {
            normalized = normalized.replace("\"", "");
        }
        
        return normalized
            .replace(" ", space_replacemenet)
            .replace("-", "_")
            .replace("(", "")
            .replace(")", "")
            .replace("[", "")
            .replace("]", "") 
            .replace("]", "") 
            .replace("+", "_plus")
            .replace("/", "")
            .replace("!", "")
            .replace("°", "")
            .replace("'", "")
            .replace(":", "")
            .replace(";", "")
            .replace("#", "")
            .replace("*", "_")
            .replace("^", "_")
            .replace("%", "percent")
            .replace("&", "and")
            .replace("φ", "")
            .replace(".", "");
    }
    
    string pascalize(string s) {
        var parts = s.split("_");
        for (int i = 0; i < parts.length; i++) {
            if (parts[i].length == 0) continue;
            parts[i] = parts[i].substring(0,1).up() +
                       parts[i].substring(1).down();
        }
        return string.joinv("", parts);
    }
    
    public interface CommandPredicate : Object {
        public abstract bool test(string command_name);
    }
    
    public class GivenCommandsPredicate : Object, CommandPredicate {
        private string[] commands;
    
        public GivenCommandsPredicate(string[] commands) {
            this.commands = commands;
        }
        
        public bool test(string command_name) {
            if (commands.length == 0) return true;
            
            foreach (var cmd in commands) {
                if (cmd == command_name) {
                    return true;
                }
            }
            return false;
        }
    }
    
    public class PrefixPredicate : Object, CommandPredicate {
        private string prefix;
    
        public PrefixPredicate(string prefix) {
            this.prefix = prefix;
        }
    
        public bool test(string command_name) {
            return command_name.has_prefix(prefix);
        }
    }
    
    public class AnyPredicate : Object, CommandPredicate {
        public bool test(string command_name) {
            return true;
        }
    }
    
    public class AndPredicate : Object, CommandPredicate {
        private GmicFilterPredicate predicate1;
        private GmicFilterPredicate predicate2;
        
        public AndPredicate(GmicFilterPredicate predicate1, GmicFilterPredicate predicate2) {
            this.predicate1 = predicate1;
            this.predicate2 = predicate2;
        }
        
        public bool test(string command_name) {
            return predicate1.is_supported(command_name) && predicate2.is_supported(command_name);
        }
    }
    
    public class GmicFilterPredicate {
        private CommandPredicate pred;
    
        public GmicFilterPredicate(CommandPredicate pred) {
            this.pred = pred;
        }
    
        public bool is_supported(string command_name) {
            return pred.test(command_name);
        }
        
        public GmicFilterPredicate and(GmicFilterPredicate predicate) {
            return new GmicFilterPredicate(new AndPredicate(this, predicate));
        }
    
        public static GmicFilterPredicate has_prefix(string prefix) {
            return new GmicFilterPredicate(new PrefixPredicate(prefix));
        }
    
        public static GmicFilterPredicate is_any_of(string[] commands) {
            return new GmicFilterPredicate(new GivenCommandsPredicate(commands));
        }
        
        public static GmicFilterPredicate any() {
            return new GmicFilterPredicate(new AnyPredicate());
        }
    }
    
    public abstract class GmicParameter : Object {
        public string name { get; protected set; }
        private string suffix = "";
        
        public virtual string details() {
            return "";
        }
        
        public virtual string to_gegl_property() {
            return "";
        }
        
        public virtual string format() {
            return "";
        }
        
        public virtual string wrap_property(string property) {
            return "props->%s".printf(property);
        }
        
        protected GmicParameter(string name) {
            this.name = name;
        }
        
        public string safe_name {
            owned get {
                return name
                    .replace("\"", "'")
                    .replace("\\′", "'")
                    .replace("\\″", "'");
            }
        }
        
        public string normalized_name() {
            return "%s%s".printf(normalize(name).down(), suffix);
        }
        
        public string digit_safe_name() {
            var normalized = normalized_name();
            if (normalized.length > 0 && normalized[0].isdigit ()) {
                normalized = "x_%s".printf(normalized);
            }
            return normalized;
        }
        
        public GmicParameter append_value_suffix(int current_value) {
            this.suffix = "%d".printf(current_value);
            return this;
        }
    }
    
    public class GmicTextParam : GmicParameter {
        
        public string def;
        
        public GmicTextParam.from(string name, string param_definition) {
            var contents = "";
            
            if (param_definition.has_prefix("\"")) {
                contents = param_definition.replace("\"", "");
            } else {
                var parts = param_definition.split("\"");
                if (parts.length > 1) {
                    contents = "\"%s\"".printf(parts[1].strip());
                } else {
                    contents = param_definition;
                }
                
            }
            this(name, contents);
        }
        
        public GmicTextParam(string name, string def) {
            base(name);
            this.def = def;
        }
        
        public override string details() {
            return "text (%s)".printf(def);
        }
        
        public override string to_gegl_property() {
            return """property_string ({{name_normalized}}, _("{{name}}"), {{default_value}})
            """
            .replace("{{name_normalized}}", digit_safe_name())
            .replace("{{name}}", name)
            .replace("{{default_value}}", "%s".printf(def));
        }
        
        public override string format() {
            return "\\\"%s\\\"";
        }
    }
    
    public class GmicFloatParam : GmicParameter {
        public double def;
        public double min;
        public double max;
    
        public GmicFloatParam.from(string name, string param_definition) {
            var p = param_definition.split(",");
            
            this(name, double.parse(p[0]), double.parse(p[1]), double.parse(p[2]));
        }
        
        public GmicFloatParam(string name, double def, double min, double max) {
            base(name);
            this.def = def;
            this.min = min;
            this.max = max;
        }
        
        public override string details() {
            return "float (%f, %f, %f)".printf(def, min, max);
        }
        
        public override string to_gegl_property() {
            return """property_double ({{name_normalized}}, _("{{name}}"), {{default_value}})
    value_range ({{min_value}}, {{max_value}})
            """
            .replace("{{name_normalized}}", digit_safe_name())
            .replace("{{name}}", safe_name)
            .replace("{{default_value}}", "%.2f".printf(def))
            .replace("{{min_value}}", "%.2f".printf(min))
            .replace("{{max_value}}", "%.2f".printf(max));
        }
        
        public override string format() {
            return "%f";
        }
    }
    
    public class GmicIntParam : GmicParameter {
        public int def;
        public int min;
        public int max;
    
        public GmicIntParam.from(string name, string param_definition) {
            var p = param_definition.split(",");
            
            this(name, int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
        
        public GmicIntParam(string name, int def, int min, int max) {
            base(name);
            this.def = def;
            this.min = min;
            this.max = max;
        }
        
        public override string details() {
            return "int (%d, %d, %d)".printf(def, min, max);
        }
        
        public override string to_gegl_property() {
            return """property_int ({{name_normalized}}, _("{{name}}"), {{default_value}})
    value_range ({{min_value}}, {{max_value}})
            """
            .replace("{{name_normalized}}", digit_safe_name())
            .replace("{{name}}", name)
            .replace("{{default_value}}", "%.2f".printf(def))
            .replace("{{min_value}}", "%.2f".printf(min))
            .replace("{{max_value}}", "%.2f".printf(max));
        }
        
        public override string format() {
            return "%d";
        }
    }
    
    public class GmicBoolParam : GmicParameter {
        public bool def;
    
        public GmicBoolParam.from(string name, string param_definition) {
            this(name, param_definition == "1");   
        }
        
        public GmicBoolParam(string name, bool def) {
            base(name);
            this.def = def;
        }
        
        public override string to_gegl_property() {
            return """property_boolean ({{name_normalized}}, _("{{name}}"), {{default_value}})
            """
            .replace("{{name_normalized}}", digit_safe_name())
            .replace("{{name}}", name)
            .replace("{{default_value}}", "%d".printf(def ? 1 : 0));
        }
        
        public override string details() {
            return "boolean (%s)".printf(def ? "true" : "false");
        }
        
        public override string format() {
            return "%d";
        }
    }
    
    public class GmicChoiceParam : GmicParameter {
        public int def_index;
        public string[] options;
        private string related_command;
    
        public string enum_type_name  {
            owned get {
                return pascalize(related_command) + normalize(name) + "Type";
            }
        }
        
        public string enum_type  {
            owned get {
                return normalize(name).down() + "_type";
            }
        }
        
        public string[] enum_options {
            owned get {
                var result = new string[options.length];
                int i = 0;
                foreach (var option in options) {
                    result[i++] = "(%s, \"%s\", N_(%s))".printf(
                        enum_value(i).up(),
                        enum_value(i).down(),
                        option
                    );
                }
                return result;
            }
        }
        
        public string[] enum_values {
            owned get {
                var result = new string[options.length];
                int i = 0;
                foreach (var option in options) {
                        result[i++] = "%s%s".printf(enum_value(i), (i == options.length - 1) ? "" : ",");
                }
                return result;
            }
        }
        
        private string enum_value(int option_index) {
            return digit_safe_name() + "_%d".printf(option_index);
                
        }
        
        public GmicChoiceParam(string related_command, string name, int def_index, string[] options) {
            base(name);
            this.def_index = def_index;
            this.options = normalize_options(options);
            this.related_command = related_command;
        }
        
        private string[] normalize_options(string[] options) {
            var normalized = new string[options.length];
            for (int i = 0; i < options.length; i++) {
                var o = options[i];
                if (!o.has_prefix("\"")) {
                    o = "\"" + o;
                }
                if (!o.has_suffix("\"")) {
                    o = o + "\"";
                }
                normalized[i] = o;
            }
            return normalized;
        }
        
        public override string details() {
            return "choice (%d, %s)".printf(def_index, string.joinv(",", options));
        }
        
        public override string to_gegl_property() {
            return """property_enum ({{name_normalized}}, _("{{name}}"), {{enum_type_name}}, {{enum_type}}, {{def_index}})
            """
            .replace("{{name_normalized}}", digit_safe_name())
            .replace("{{name}}", name)
            .replace("{{enum_type_name}}", enum_type_name)
            .replace("{{enum_type}}", "%s_%s".printf(related_command, enum_type))
            .replace("{{def_index}}", "%d".printf(def_index));
        }
        
        public override string format() {
            return "%d";
        }
    }
    
    public class GmicColorParam : GmicParameter {
        public string hex;
    
        public GmicColorParam.from(string name, string param_definition) {
            this(name, param_definition);
        }
        
        public GmicColorParam(string name, string hex) {
            base(name);
            this.hex = hex;
        }
        
        public override string details() {
            return "color (%s)".printf(hex);
        }
        
        public override string to_gegl_property() {
            return """property_color ({{name_normalized}}, _("{{name}}"), "{{default_value}}")
            """
            .replace("{{name_normalized}}", digit_safe_name())
            .replace("{{name}}", name)
            .replace("{{default_value}}", hex);
        }
        
        public override string format() {
            return "%s";
        }
        
        public override string wrap_property(string normalized_name) {
            bool has_alpha = hex.length == 9;
            return "gegl_color_to_rgba(props->%s, %s)".printf(normalized_name, has_alpha ? "true" : "false");
        }
    }
    
    public class GmicPointParam : GmicParameter {
        public int x;
        public int y;
        public int min;
        public int max;
    
        public GmicPointParam.from(string name, string param_definition) {
            var parts = param_definition.split(",");
            var px = parts.length > 0 ? int.parse(parts[0]) : 0;
            var py = parts.length > 1 ? int.parse(parts[1]) : 0;
            var pmin = parts.length > 2 ? double.parse(parts[2]) : 0.0;
            var pmax = parts.length > 3 ? double.parse(parts[3]) : 1.0;
            
            this(name, px, py, (int) (pmin * 100), (int) (pmax * 100));
        }
        
        public GmicPointParam(string name, int x, int y, int min, int max) {
            base(name);
            this.x = x;
            this.y = y;
            this.min = min;
            this.max = max;
        }
        
        public override string details() {
            return "point (%d,%d,%d,%d)".printf(x, y, min, max);
        }
        
        
        public override string to_gegl_property() {
            return """property_double ({{name_normalized}}_x, _("{{name}} X"), {{default_value_x}})
value_range ({{min_value}}, {{max_value}})

property_double ({{name_normalized}}_y, _("{{name}} Y"), {{default_value_y}})
    value_range ({{min_value}}, {{max_value}})
            """
            .replace("{{name_normalized}}", digit_safe_name())
            .replace("{{name}}", safe_name)
            .replace("{{default_value_x}}", "%.2f".printf(x))
            .replace("{{default_value_y}}", "%.2f".printf(y))
            .replace("{{min_value}}", "%.2f".printf(min))
            .replace("{{max_value}}", "%.2f".printf(max));
        }
        
        public override string wrap_property(string normalized_name) {
            return "props->%s_x,\nprops->%s_y".printf(normalized_name, normalized_name);
        }
        
        public override string format() {
            return "%f,%f";
        }
    }
    
    public class GmicCategory : Object {
        
        private List<GmicFilter> filters = new List<GmicFilter>();
        public string name { private set; public get;}
        
        public GmicCategory(string name) {
            this.name = name;
        }
        
        public void add_filter(GmicFilter filter) {
            filters.append(filter);
        }
    }
    
    public class GmicFilter : Object {
        public string name { private set; public get; }
        public string command { private set; public get; }
        public string command_pascalized {
            owned get {
                return pascalize(command);
            }
        }
        public string? _description;
        public GmicCategory? category;
        
        public List<GmicParameter> parameters = new List<GmicParameter>();
        private Gee.Map<string, int> parameter_name_accumulation = new Gee.HashMap<string, int>();
        
        public bool has_description {
            get {
                return _description != null;
            }
        }
        
        public string description {
            owned get {
                return _description;
            }
        }
        
        public string normalized_category_name {
            owned get {
                return category?.name
                    .replace(" ", "_")
                    .replace(" & ", "_and_")
                    .down();
            }
        }
        
        public string[] gegl_enums {
            owned get {
                var unique_enums = new Gee.ArrayList<string>();
                var result = new string[parameters.length()];
                
                var template = new Template.Template(new Template.TemplateLocator());
                try {
                    template.parse_path("templates/op.enum.tmpl");
                } catch (Error e) {
                    warning(e.message);
                    return result;
                }
                
                var scope = new Template.Scope();
                
                int index = 0;
                foreach (var param in parameters) {
                    var choice_param = param as GmicChoiceParam;
                    if (choice_param == null) {
                        continue;
                    }
                    
                    if (unique_enums.contains(choice_param.enum_type)) {
                        continue;
                    }
                    
                    scope["command"].assign_string(command);
                    scope["choice"].assign_object(choice_param);
                    try {
                        result[index++] = template.expand_string(scope);
                        unique_enums.add(choice_param.enum_type);
                    } catch (Error e) {
                        warning(e.message);
                    }
                }
                
                return result;
            }
        }
        
        public string[] gegl_parameters {
            owned get {
                var result = new string[parameters.length()];
                int i = 0;
                foreach (var p in parameters) {
                    result[i++] = p.to_gegl_property();
                }
                return result;
            }
        }
        
        public string[] gegl_parameters_names {
            owned get {
                var result = new string[parameters.length()];
                int i = 0;
                foreach (var p in parameters) {
                    var wrapped_property = p.wrap_property(p.digit_safe_name());
                    result[i++] = "%s%s".printf(wrapped_property, (i == parameters.length() -1) ? "" : ",");
                }
                return result;
            }
        }
        
        public bool has_parameters {
            get {
                return parameters.length() > 0;
            }
        }
        
        public string gegl_parameters_format {
            owned get {
                string[] formats = new string[parameters.length()];
                int i = 0;
                foreach (var p in parameters) {
                    formats[i++] = p.format();
                }
                return string.joinv(",", formats);
            }
        }
        
        private bool collecting_choice = false;
        private string choice_name = "";
        private int choice_default_index = 0;
        private string[] choice_items = {};
        
        public GmicFilter(string name, string command) {
            this.name = name;
            this.command = command;
            this.parameters = new GLib.List<GmicParameter>();
        }
        
        public bool try_begin_choice(string body) {
            if (collecting_choice)
                return false;
        
            int eq = body.index_of("=");
            if (eq < 0)
                return false;
        
            string name = body.substring(0, eq).strip();
            if (name == "Preview Type") {
                return false;
            }
            
            string rhs = body.substring(eq + 1).strip();
            if (rhs.has_prefix("~") || rhs.has_prefix("_")) {
                rhs = rhs.substring(1).strip();
            }
        
            if (!rhs.has_prefix("choice(") && !rhs.has_prefix("choice{"))
                return false;
        
            bool brace = rhs.has_prefix("choice{");
            string open = brace ? "choice{" : "choice(";
            string close = brace ? "}" : ")";
        
            rhs = rhs.substring(open.length);
        
            int close_pos = rhs.index_of(close);
        
            if (close_pos >= 0) {
                string inside = rhs.slice(0, close_pos);
                string[] parts = inside.split(",");
        
                int def_index = 0;
                int parsed;
                bool ok = int.try_parse(parts[0].strip(), out parsed);
        
                if (ok) {
                    def_index = parsed;
                    parts = parts[1:parts.length];
                }
        
                var opts = new string[]{};
                foreach (var p in parts) {
                    var t = p.strip();
                    if (t.length > 0)
                        opts += t;
                }
        
                add_parameter(new GmicChoiceParam(this.command, name, def_index, opts));
                return true;
            }
        
            collecting_choice = true;
            choice_name = name;
            choice_items = {};
        
            string[] first = rhs.split(",");
        
            int idx_val;
            bool has_default = int.try_parse(first[0].strip(), out idx_val);
        
            if (has_default) {
                choice_default_index = idx_val;
                for (int i = 1; i < first.length; i++) {
                    var t = first[i].strip();
                    if (t.length > 0)
                        choice_items += t;
                }
            } else {
                choice_default_index = 0;
                foreach (var t0 in first) {
                    var t = t0.strip();
                    if (t.length > 0)
                        choice_items += t;
                }
            }
        
            return true;
        }
        
        public bool try_feed_choice(string body) {
            if (!collecting_choice)
                return false;
        
            if (body.contains("}")) {
                var cleaned = body.replace("}", "").replace(",", "").strip();
                
                if (cleaned.length > 0)
                    choice_items += cleaned;
        
                var p = new GmicChoiceParam(
                    this.command, 
                    choice_name,
                    choice_default_index,
                    choice_items
                );
                add_parameter(p);
        
                collecting_choice = false;
                choice_items = {};
                choice_name = "";
                choice_default_index = 0;
        
                return true;
            }
        
            var opt = body.replace(",", "").strip();
            if (opt.length > 0)
                choice_items += opt;
        
            return true;
        }
        
        public bool try_end_choice(string body) {
            if (!collecting_choice)
                return false;
        
            if (body.contains("}")) {
                var p = new GmicChoiceParam(
                    this.command, 
                    choice_name,
                    choice_default_index,
                    choice_items
                );
                add_parameter(p);
        
                collecting_choice = false;
                choice_items = {};
                choice_name = "";
                choice_default_index = 0;
        
                return true;
            }
        
            return false;
        }
        
        public void add_parameter(GmicParameter parameter) {
            var normalized_name = normalize(parameter.name).down();
            
            if (parameter_name_accumulation.has_key(normalized_name)) {
                int current_value = parameter_name_accumulation.get(normalized_name);
                parameter.append_value_suffix(++current_value);
                parameter_name_accumulation.set(normalized_name, current_value);
                parameters.append(parameter);
                
                return;
            }
            
            parameter_name_accumulation.set(normalized_name, 1);
            parameters.append(parameter);
        }
        
        public void print_parameters() {
            foreach (var param in parameters) {
                stdout.printf("- %s | %s\n", param.name, param.details());
            }
        }
    }

    public class GmicFilterParser {
        private GmicCategory? current_category;
        private GmicFilter? current_filter;
        private GmicFilterPredicate filter_predicate;
        
        public GmicFilterParser(GmicFilterPredicate filter_predicate = GmicFilterPredicate.any()) {
            this.filter_predicate = filter_predicate;
        }
        
        public List<GmicFilter> parse_gmic_stdlib(string stdlib) {
            var unique = new Gee.ArrayList<string>();
            var filters = new List<GmicFilter>();
            var lines = stdlib.split("\n");

            foreach (var line in lines) {
                var trimmed = line.strip();
                if (!trimmed.has_prefix("#@gui ")) continue;
                if (trimmed.has_prefix("#@gui _")) {
                    var category = parse_category_line(trimmed);
                    if (category != null) {
                        current_category = category;
                    }
                    
                    // stop before parsing Testing
                    //  if (category?.name == "Testing") {
                    //      return filters;
                    //  }
                    
                    continue;
                }
                
                if (trimmed.has_prefix("#@gui :")) {
                    parse_param_line(trimmed);
                    continue;
                }

                var filter = parse_header_line(trimmed);
                if (filter != null) {
                    if (unique.contains(filter.command)) {
                        continue;
                    }
                    
                    if (current_filter != null) {
                        current_filter = null;
                    }
                    
                    if (!is_command_supported(filter.command)) {
                        continue;
                    }
                    
                    current_filter = filter;
                    filters.append(filter);
                    unique.add(filter.command);
                }
            }
            
            return filters;
        }
        
        private GmicFilter? parse_header_line(string line) {
            var parts = line.split(":");
            if (parts.length < 2) return null;

            var header = parts[0];
            var name = header.substring("#@gui".length).strip();
            var func_part = parts[1].strip();
            var func_parts = func_part.split(",");
            var command = func_parts[0].strip();

            if (command == "_none_") return null;

            var filter = new GmicFilter(name, command);
            if (current_category != null) {
                filter.category = current_category;
            }
            return filter;
            
        }

        private bool is_command_supported(string command_name) {
            if (this.filter_predicate == null) return true;
            
            return filter_predicate.is_supported(command_name);
        }
        
        private string? extract_category(string line) throws Error {
            var m = Regex.match_simple(@"^#@gui _<(\\w+)>", line);
            if (!m) {
                return null;
            }
        
            var re = new Regex(@"^#@gui _<(\\w+)>(.*?)</\\1>");
            MatchInfo info;
            if (!re.match(line, 0, out info)) {
                return null;
            }
        
            var tag = info.fetch(1);
            if (tag == "i") {
                return null;
            }
        
            var category = info.fetch(2).strip();
            return category == "" ? null : category;
        }
        
        
        private GmicCategory? parse_category_line(string line) {
            string category = "Uncategorized";
            try {
                category = extract_category(line);
            } catch (Error e) {
                return null;
            }
            
            if (category == null) {
                return null;
            }
            return new GmicCategory(category);
        }
        
        private void parse_param_line(string line) {
            if (current_filter == null) return;
        
            var body = line.substring("#@gui :".length).strip();
        
            if (current_filter.try_begin_choice(body)) return;
            if (current_filter.try_feed_choice(body)) return;
            if (current_filter.try_end_choice(body)) return;
            
            var eq = body.index_of("=");
            if (eq < 0) return;
        
            var name = body.substring(0, eq).strip();
            var contents = body.substring(eq + 1).strip();
            
            if ("_" == name) {
                parse_meta_param(contents);
                return;
            }
            
            var param = parse_singleline_param(name, contents);
            if (param != null)
                current_filter.add_parameter(param);
        }
        
        private void parse_meta_param(string contents) {
            var param_contents = contents;
            param_contents.replace("\\n", "");
            
            if (param_contents.has_prefix("note(")) {
                if (param_contents.contains("Description")) {
                    var needle = "<span color=\"#EE5500\"><b>Description:</b></span>";
                    
                    var first = param_contents.index_of(needle, 0);
                    if (first < 0) {
                        return;
                    }   
                    var last = param_contents.last_index_of(".", first + needle.length);
                    
                    this.current_filter._description =
                        param_contents
                            .substring(first + needle.length, last - (first + needle.length))
                            .replace("\"", "'")
                            .strip();
                }
            }
        }
        
        private GmicParameter? parse_singleline_param(string name, string contents) {
            var rhs = contents;
        
            if (rhs.has_prefix("~") || rhs.has_prefix("_"))
                rhs = rhs.substring(1).strip();
        
            try {
                var regex = new GLib.Regex(
                    "^(float|int|bool|color|text|point)\\s*[\\(\\{](.*)[\\)\\}]$",
                    GLib.RegexCompileFlags.CASELESS,
                    0
                );
        
                GLib.MatchInfo match;
                if (!regex.match(rhs, 0, out match))
                    return null;
        
                var type_name = match.fetch(1).down();
                var body = match.fetch(2).strip();
        
                switch (type_name) {
                case "float":
                    return new GmicFloatParam.from(name, body);
                case "int":
                    return new GmicIntParam.from(name, body);
                case "bool":
                    return new GmicBoolParam.from(name, body);
                case "color":
                    return new GmicColorParam.from(name, body);
                case "text":
                    return new GmicTextParam.from(name, body);
                case "point":
                    return new GmicPointParam.from(name, body);
                }
            } catch (Error e) {
                warning("Regex error: %s", e.message);
            }
        
            return null;
        }
        
    }
}
