#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "gmic_libc.h"

int main(int argc, char **argv) {
  gmic_interface_image images[1];
  memset(&images,0,sizeof(gmic_interface_image));

  unsigned int nofImages = 1;
  strcpy(images[0].name,"test_input");

  images[0].width = 500;
  images[0].height = 500;
  images[0].spectrum = 4;
  images[0].depth = 1;
  images[0].is_interleaved = false;
  images[0].format = E_FORMAT_FLOAT;

  float* inp = (float*)malloc(images[0].width*images[0].height*images[0].spectrum*images[0].depth*sizeof(float));
  images[0].data = inp;

  float* ptr = inp;
  for (unsigned int c = 0; c<images[0].spectrum; ++c)
    for (unsigned int y = 0; y<images[0].height; ++y)
      for (unsigned int x = 0; x<images[0].width; ++x) {
        if (c==3) *(ptr++) = 255;
        else if (x<=images[0].width/3) *(ptr++) = c==0?255:0;
        else if (x<=2*images[0].width/3) *(ptr++) = c==1?255:0;
        else *(ptr++) = c==2?255:0;
      }

  gmic_interface_options options;
  memset(&options,0,sizeof(gmic_interface_options));

  options.ignore_stdlib = false;

  bool abort = false;
  float progress;
  options.p_is_abort = &abort;
  options.p_progress = &progress;

  options.interleave_output = false;
  options.no_inplace_processing = true;
  options.output_format = E_FORMAT_FLOAT;

  gmic_call("polaroid 5,30 fx_bokeh 3,8,0,30,8,4,0.3,0.2,210,210,80,160,0.7,30,20,20,1,2,170,130,20,110,0.15  display",
            &nofImages, &images[0], &options);

  for (int i = 0; i<nofImages; ++i) {
    if (images[i].data!=inp) {
      gmic_delete_external((float*)images[i].data);
    }
  }

  free(inp);
  return 0;
}
