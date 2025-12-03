# GEGL G’MIC Operation — Experimental Integration

This project provides a **custom GEGL operation** that runs arbitrary  
**G’MIC commands** directly on GEGL buffers — with **full-image processing**,  
no tiling artifacts, and full **RGBA float** support.

Originally implemented for **RasterFlow**, but it works in **any GEGL-based pipeline**,  
including standalone `gegl` CLI or other applications embedding GEGL.

## 📸 Example — G’MIC + GEGL in action in RasterFlow

![kapibara](kapibara-gmic.png)

## 📦 Dependencies

This solution depends on the following libraries:

- glib-2.0
- gobject-2.0
- gee-0.8
- gegl-0.4
- template-glib-1.0

## 🔧 Installing

Compile and install using Meson/Ninja (default mode):

```bash
meson setup build
ninja -C build
ninja -C build install
```
This builds only the main operation `gmic:command`.

### Experimental: build with operation generator
Enable the generator with:

```bash
meson setup -Dwith_generator=true build
```

This adds the **G’MIC → GEGL** operation generator to the build and uses
**operations/commands/** as the source directory for generated operations.

After building:

```bash
ninja -C build
```

you can generate per-command GEGL operations (all at once!):

```bash
./build/generator/gmic-gegl-generator --output-dir=operations/commands
```

Instead of generating all G’MIC operations, you can generate only selected ones:

```bash
./build/generator/gmic-gegl-generator \
  --output-dir=operations/commands \
  --commands fx_loose_photos \
  --commands fx_drop_water
```
Multiple --commands parameters may be provided.

Finally, rebuild to compile all generated plugins:

```bash
ninja -C build
```

### Optional: disable the `aux` input pad for GEGL operations

By default, the build enables an additional **aux** input pad on all generated
GEGL operations. Some hosts (notably GIMP 3.0.4) require the aux pad to be disabled for
non-destructive editing to work correctly (big thanks to @LinuxBeaver for extensive
plugin testing and reporting this issue!).

You can turn it off by configuring Meson with:

```bash
meson setup -Dwith_aux=false build
```

With `with_aux=false`, all generated operations are built without the aux
input pad and integrate properly in GIMP 3.0.4’s non-destructive pipeline.

> [!WARNING]
> This generator mode is in vearly early stage of development, please report any unexpected behavior.

## 🧪 Running the plugin from terminal (GEGL CLI)

```bash
gegl \
  -i input.png \
  -o output.png \
  -- gmic:command command="raindrops"
```

## 🛠 How it works (technical overview)

GEGL processes images in **tiles**, but **G’MIC requires full-image context**,  
especially for operations involving:

- geometry  
- FFT / spectral domain  
- global statistics  
- synthetic image creation  

This plugin solves the mismatch by:

1. Fetching the **entire input buffer** (`gegl_buffer_get()`).
2. Running the **G’MIC interpreter once** on the full image.
3. Reconstructing the output **tile-by-tile** to satisfy GEGL’s ROI requests.
4. Enforcing **non-threaded evaluation** (`operation->threaded = FALSE`).
5. Providing `get_cached_region()` and `get_required_for_output()`  
   so GEGL **always requests the full image** instead of tiles.
