void test_basic_ascii() {
    assert_cmpstr(
        normalize("Hello World"),
        EQ,
        "HelloWorld"
    );
}

void test_spaces_and_dashes() {
    assert_cmpstr(
        normalize("foo-bar baz", true, "_"),
        EQ,
        "foo_bar_baz"
    );
}

void test_diacritics_lowercase() {
    assert_cmpstr(
        normalize("étendue"),
        EQ,
        "etendue"
    );
}

void test_diacritics_uppercase() {
    assert_cmpstr(
        normalize("Étendue"),
        EQ,
        "Etendue"
    );
}

void test_mixed_symbols() {
    assert_cmpstr(
        normalize("À la carte (50%) & φ"),
        EQ,
        "Alacarte50_percent_and"
    );
}

void test_quotes_removed() {
    assert_cmpstr(
        normalize("\"Hello\""),
        EQ,
        "Hello"
    );
}

void test_quotes_kept() {
    assert_cmpstr(
        normalize("\"Hello\"", false),
        EQ,
        "\"Hello\""
    );
}

void test_mixed_symbols_2() {
    assert_cmpstr(
        normalize("Nombre De Côtés / Number of Sides"),
        EQ,
        "NombreDeCotesNumberofSides"
    );
}

void test_diacritics_various() {
    assert_cmpstr(
        normalize("Crème brûlée à la mode"),
        EQ,
        "Cremebruleealamode"
    );
}

void test_diacritics_uppercase_various() {
    assert_cmpstr(
        normalize("ÀÉÎÖÜ"),
        EQ,
        "AEIOU"
    );
}

void test_math_and_separators() {
    assert_cmpstr(
        normalize("A+B-C*D/E^F"),
        EQ,
        "A_plusB_C_DE_F"
    );
}

void test_repeated_noise() {
    assert_cmpstr(
        normalize("Foo   Bar!!! Baz???"),
        EQ,
        "FooBarBaz"
    );
}


int main(string[] args) {
    Test.init(ref args);

    Test.add_func("/normalize/basic_ascii", test_basic_ascii);
    Test.add_func("/normalize/spaces_and_dashes", test_spaces_and_dashes);
    Test.add_func("/normalize/diacritics_lowercase", test_diacritics_lowercase);
    Test.add_func("/normalize/diacritics_uppercase", test_diacritics_uppercase);
    Test.add_func("/normalize/mixed_symbols", test_mixed_symbols);
    Test.add_func("/normalize/mixed_symbols2", test_mixed_symbols_2);
    Test.add_func("/normalize/quotes_removed", test_quotes_removed);
    Test.add_func("/normalize/quotes_kept", test_quotes_kept);
    Test.add_func("/normalize/diacritics_various", test_diacritics_various);
    Test.add_func("/normalize/diacritics_uppercase_various", test_diacritics_uppercase_various);
    Test.add_func("/normalize/math_and_separators", test_math_and_separators);
    Test.add_func("/normalize/repeated_noise", test_repeated_noise);
    
    return Test.run();
}
