/* BUFFERSTRUCTURE /
Col0 = Albedo
Col1 = Normals
Col2 = Lightmap
Col3 = ID (+ Masks)

Col4 = PBR: labF0, Emissive, Smoothness, SSS
Col5 = PBR: Height, AO
//////////////////*/

uniform sampler2D colortex0; // Color
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;


vec3 getAlbedo(ivec2 icoord) {
    return texelFetch(colortex0, icoord, 0).rgb;
}
vec3 getAlbedo(vec2 coord) {
    return texture(colortex0, coord).rgb;
}


float getDepth(ivec2 icoord) {
    return texelFetch(depthtex0, icoord, 0).x;
}
float getDepth(vec2 coord) {
    return texture(depthtex0, coord).x;
}


vec3 getNormal(vec2 coord) {
    return texture(colortex1, coord).rgb;
}
vec3 getNormal(ivec2 icoord) {
    return texelFetch(colortex1, icoord, 0).rgb;
}

vec2 getLmCoord(vec2 coord) {
    return texture(colortex2, coord).rg;
}
vec3 getLmCoordAO(vec2 coord) {
    return texture(colortex2, coord).rgb;
}


float getID(ivec2 icoord) {
    return floor(texelFetch(colortex3, icoord, 0).r * 255 + 0.5);
}
float getID(vec2 coord) {
    return floor(texture(colortex3, coord).r * 255 + 0.5);
}


struct material {
    float f0;
    float emission;
    float smoothness;
    float sss;
    float height;
    float ao;
};

material getMaterial(vec2 coord, vec3 lmcAO) {
    vec4 pbrtex0 = texture(colortex4, coord);
    vec4 pbrtex1 = texture(colortex5, coord);
    material materialValues = material(
        pbrtex0.x, // f0
        pbrtex0.y, // emission
        pbrtex0.z, // smoothness
        pbrtex0.w, // sss
        pbrtex1.x, // height
        lmcAO.z    // ao
    );
    return materialValues;
}