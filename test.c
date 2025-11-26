#include <stdio.h>
#include <string.h>
#include <gmic_libc.h>

int main(int argc, char **argv)
{
    float img[4 * 4 * 4];

    for (int i = 0; i < 16; i++) {
        img[4*i+0] = 0.2f;
        img[4*i+1] = 0.4f;
        img[4*i+2] = 0.6f;
        img[4*i+3] = 1.0f;
    }

    gmic_interface_image im;
    memset(&im, 0, sizeof(im));
    im.data = img;
    im.width = 4;
    im.height = 4;
    im.depth = 1;
    im.spectrum = 4;
    im.is_interleaved = true;
    im.format = E_FORMAT_FLOAT;

    unsigned int count = 1;

    gmic_interface_options opt;
    memset(&opt, 0, sizeof(opt));
    opt.interleave_output = true;
    opt.output_format = E_FORMAT_FLOAT;

    const char *cmd = (argc > 1) ? argv[1] : "negate";

    gmic_call(cmd, &count, &im, &opt);

    printf("done\n");
    return 0;
}
