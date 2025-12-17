public static string normalize(
    string text, 
    bool remove_parenthesis = true, 
    string space_replacemenet = "") 
{
    var normalized = text;
    if (remove_parenthesis) {
        normalized = normalized.replace("\"", "");
    }
    
    try {
        
        normalized = normalized.normalize(-1, NormalizeMode.NFKD);
        normalized = new Regex(@"\\p{Mn}+").replace(normalized, -1, 0, "");
    } catch (Error e) {
        
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
        .replace("*", "")
        .replace("^", "_")
        .replace("%", "_percent_")
        .replace("&", "and")
        .replace("φ", "")
        .replace(".", "")
        .replace(",", "")
        .replace("?", "")
        .replace("#", "")
        .replace(">", "")
        .replace("<", "")
        ;
}