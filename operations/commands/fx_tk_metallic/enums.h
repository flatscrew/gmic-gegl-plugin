#pragma once
#include <glib-object.h>

typedef enum {
    METAL_SILVER,
    METAL_GOLD,
    METAL_COPPER,
    METAL_BRONZE,
    METAL_BLUE_STEEL
} MetalType;

GType metal_type_get_type(void);