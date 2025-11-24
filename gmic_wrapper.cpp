#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#include <gmic.h>

extern "C" {

    const char* gmic_version_string() {
        return STR(gmic_version);
    }

    const char* gmic_decompress_stdlib() {
        const gmic_image<char>& img = gmic::decompress_stdlib();
        return img._data;
    }
}

