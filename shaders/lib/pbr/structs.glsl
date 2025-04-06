#if ! defined PBR_STRUCTS_GLSL
#define PBR_STRUCTS_GLSL

struct RawMaterial {
    vec3  normal;
    float roughness;
    float reflectance;
    float emission;
    float height;
    float ao;
    float subsurface;
    float porosity;
};

struct MaterialTexture {
    float roughness;
    float reflectance;
    float height;
    float emission;
};

struct Material {
    vec3  albedo;
    float roughness;
    vec3  f0;
    float emission;
    float height;
    float ao;
    vec2  lightmap;
    float subsurface;
    float porosity;
};

#endif