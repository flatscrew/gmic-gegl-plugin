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