public class Blacklist {
    
    private static Blacklist? _instance;
    
    public static Blacklist instance {
        get {
            if (_instance == null)
                _instance = new Blacklist();
            return _instance;
        }
    }
    
    private Gee.List<string> blacklisted = new Gee.ArrayList<string>();
    
    public bool is_blacklisted(string gmic_command) {
        return this.blacklisted.index_of(gmic_command) > -1;
    }
    
    public void add(string first, ...) {
        blacklisted.add(first);
        
        var list = va_list();
        while (true) {
            string? val = list.arg();
            if (val == null) {
                break; 
            }
            blacklisted.add(val);
        }
    }
}