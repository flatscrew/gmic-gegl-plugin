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
        
        public virtual string details() {
            return "";
        }
    }
    
    public class GmicFloatParam : GmicParameter {
        public double def;
        public double min;
        public double max;
    
        public GmicFloatParam(string name, double def, double min, double max) {
            this.name = name;
            this.def = def;
            this.min = min;
            this.max = max;
        }
        
        public override string details() {
            return "float (%f, %f, %f)".printf(def, min, max);
        }
    }
    
    public class GmicIntParam : GmicParameter {
        public int def;
        public int min;
        public int max;
    
        public GmicIntParam(string name, int def, int min, int max) {
            this.name = name;
            this.def = def;
            this.min = min;
            this.max = max;
        }
        
        public override string details() {
            return "int (%d, %d, %d)".printf(def, min, max);
        }
    }
    
    public class GmicBoolParam : GmicParameter {
        public bool def;
    
        public GmicBoolParam(string name, bool def) {
            this.name = name;
            this.def = def;
        }
        
        public override string details() {
            return "bool (%s)".printf(def ? "true" : "false");
        }
    }
    
    public class GmicChoiceParam : GmicParameter {
        public int def_index;
        public string[] options;
    
        public GmicChoiceParam(string name, int def_index, string[] options) {
            this.name = name;
            this.def_index = def_index;
            this.options = options;
        }
        
        public override string details() {
            return "choice (%d, %s)".printf(def_index, string.joinv(",", options));
        }
    }
    
    public class GmicColorParam : GmicParameter {
        public string hex;
    
        public GmicColorParam(string name, string hex) {
            this.name = name;
            this.hex = hex;
        }
        
        public override string details() {
            return "color (%s)".printf(hex);
        }
    }
    
    public class GmicFilter {
        public string name { private set; public get; }
        public string command { private set; public get; }
        
        private List<GmicParameter> parameters = new List<GmicParameter>();

        private bool collecting_choice = false;
        private string choice_name = "";
        private int choice_default_index = 0;
        private string[] choice_items = {};
        
        public GmicFilter(string name, string command) {
            this.name = name;
            this.command = command;
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
            if (rhs.has_prefix("~")) {
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
        
                add_parameter(new GmicChoiceParam(name, def_index, opts));
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
            parameters.append(parameter);
        }
        
        public void print_parameters() {
            foreach (var param in parameters) {
                stdout.printf("- %s | %s\n", param.name, param.details());
            }
        }
    }

    public class GmicFilterParser {
        private GmicFilter? current_filter;
        private GmicFilterPredicate filter_predicate;
        
        public GmicFilterParser(GmicFilterPredicate filter_predicate = GmicFilterPredicate.any()) {
            this.filter_predicate = filter_predicate;
        }
        
        public List<GmicFilter> parse_gmic_stdlib(string stdlib) {
            var filters = new List<GmicFilter>();
            var lines = stdlib.split("\n");

            foreach (var line in lines) {
                var trimmed = line.strip();
                if (!trimmed.has_prefix("#@gui ")) continue;
                
                if (trimmed.has_prefix("#@gui :")) {
                    parse_param_line(trimmed);
                    continue;
                }

                var filter = parse_header_line(trimmed);
                if (filter != null) {
                    if (current_filter != null) {
                        current_filter = null;
                    }
                    
                    if (!is_command_supported(filter.command)) {
                        continue;
                    }
                    
                    current_filter = filter;
                    filters.append(filter);
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

            return new GmicFilter(name, command);
        }

        private bool is_command_supported(string command_name) {
            if (this.filter_predicate == null) return true;
            
            return filter_predicate.is_supported(command_name);
        }
        
        private void parse_param_line(string line) {
            if (current_filter == null) return;
        
            var body = line.substring("#@gui :".length).strip();
        
            if (current_filter.try_begin_choice(body)) return;
            if (current_filter.try_feed_choice(body)) return;
            if (current_filter.try_end_choice(body)) return;
        
            var param = parse_singleline_param(body);
            if (param != null)
                current_filter.add_parameter(param);
        }
        
        private GmicParameter? parse_singleline_param(string body) {
            var eq = body.index_of("=");
            if (eq < 0) return null;
        
            var name = body.substring(0, eq).strip();
            var rhs  = body.substring(eq + 1).strip();
        
            if (rhs.has_prefix("~")) {
                rhs = rhs.substring(1).strip();
            }
            
            if (rhs.has_prefix("float(")) {
                var inside = remove_prefix(rhs, "float(");
                inside = remove_suffix(inside, ")");
                var p = inside.split(",");
                return new GmicFloatParam(
                    name,
                    double.parse(p[0]),
                    double.parse(p[1]),
                    double.parse(p[2])
                );
            }
        
            if (rhs.has_prefix("int(")) {
                var inside = remove_prefix(rhs, "int(");
                inside = remove_suffix(inside, ")");
                var p = inside.split(",");
                return new GmicIntParam(
                    name,
                    int.parse(p[0]),
                    int.parse(p[1]),
                    int.parse(p[2])
                );
            }
        
            if (rhs.has_prefix("bool(")) {
                var inside = remove_prefix(rhs, "bool(");
                inside = remove_suffix(inside, ")");
                return new GmicBoolParam(name, inside == "1");
            }
        
            if (rhs.has_prefix("color(")) {
                var inside = remove_prefix(rhs, "color(");
                inside = remove_suffix(inside, ")");
                return new GmicColorParam(name, inside);
            }
        
            return null;
        }
    }
    
    private static string remove_prefix(string s, string prefix) {
        if (s.has_prefix(prefix))
            return s.substring(prefix.length);
        return s;
    }
    
    private static string remove_suffix(string s, string suffix) {
        if (s.has_suffix(suffix))
            return s.slice(0, s.length - suffix.length);
        return s;
    }
}
