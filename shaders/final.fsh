
#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/core/kernels.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

#ifdef TAA
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#endif

#ifdef DEBUG

#include "/lib/pbr/pbr.glsl"
#include "/lib/pbr/read.glsl"
#include "/lib/pbr/ambient.glsl"

vec3 debugViewNormals(vec2 coord) {
    return getNormal(coord) * .5 + .5;
}

vec3 debugViewLightmap(vec2 coord) {
    return vec3(0);
}

vec3 debugViewPBR(vec2 coord) {
    MaterialTexture material = getPBR(ivec2(coord * screenSize));

#if DEBUG_VIEW_PBR == 0 // Roughness
    return vec3(material.roughness);
#elif DEBUG_VIEW_PBR == 1 // Reflectance
    return vec3(material.reflectance);
#elif DEBUG_VIEW_PBR == 2 // Height
    return vec3(material.height);
#elif DEBUG_VIEW_PBR == 3 // Emission
    return vec3(material.emission);
#elif DEBUG_VIEW_PBR == 4 // AO
    return vec3(material.ao);
#endif
}

vec3 debugView(vec2 coord) {
#if DEBUG_VIEW == 0 // Normals
    return debugViewNormals(coord);
#elif DEBUG_VIEW == 1 // Lightmap
    return debugViewLightmap(coord);
#elif DEBUG_VIEW == 2 // PBR
    return debugViewPBR(coord);
#endif
}

#endif

vec3 gaussian_3x3(vec2 coord) {
    vec2 e = vec2(-.5, .5) / MC_RENDER_QUALITY;
    vec3 color  = texture(colortex0, screenSizeInverse * e.yy + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.yx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xy + coord).rgb;
    return color * 0.25;
}
struct sharpenData { vec3 average; vec3 minimum; vec3 maximum; };
sharpenData getSharpenData(vec2 coord) {
    vec2 e  = vec2(-.5, .5) / MC_RENDER_QUALITY;
    vec3 c1 = texture(colortex0, screenSizeInverse * e.yy + coord).rgb;
    vec3 c2 = texture(colortex0, screenSizeInverse * e.xx + coord).rgb;
    vec3 c3 = texture(colortex0, screenSizeInverse * e.yx + coord).rgb;
    vec3 c4 = texture(colortex0, screenSizeInverse * e.xy + coord).rgb;
    return sharpenData(
        (c1 + c2 + c3 + c4) * 0.25,
        min(min(min(c1, c2), c3), c4),
        max(max(max(c1, c2), c3), c4)
    );
}
vec3 sharpen(vec2 coord, float amount, float maximum) {
    vec3 blurred  = gaussian_3x3(coord);
    vec3 color    = getAlbedo(coord);

    return clamp((color - blurred) * amount, -maximum, maximum * .33333) + color;
    //return clamp((color - blurred) * amount, -maximum, maximum) + color;
}
vec3 sharpen(sharpenData data, vec3 color, float amount) {
    return clamp(amount * (color - data.average) + color, data.minimum * 0.5, data.maximum * 1.5);
}

vec3 sharpen2(vec2 coord, float amount) {
    vec2 e = vec2(1, 0);
    vec3 c = texture(colortex0, coord).rgb;
    vec3 n = texture(colortex0, screenSizeInverse *  e.yx + coord).rgb;
    vec3 o = texture(colortex0, screenSizeInverse *  e.xy + coord).rgb;
    vec3 s = texture(colortex0, screenSizeInverse * -e.yx + coord).rgb;
    vec3 w = texture(colortex0, screenSizeInverse * -e.xy + coord).rgb;

    float nl = luminance(n);
    float ol = luminance(o);
    float sl = luminance(s);
    float wl = luminance(w);

    float maxl = max(max(nl, ol), max(sl, wl));
    float minl = min(min(nl, ol), min(sl, wl));

    float contrast = max(abs(c.g - maxl), abs(c.g - minl));
    contrast       = max(contrast, 1e-3);

    float blur = (nl+ol+sl+wl) * 0.25;
    float diff = luminance(c) - blur;

    diff = clamp( diff * inversesqrt(contrast), -c.g, 1 - c.g) * amount;
    
    return c + diff;
}

float lanczosWeight(float x, float r) {
    return x == 0.0 ? 1. : (r * sin(PI * x) * sin(PI * (x / r) )) / ( (PI*PI) * sq(x));
}
float lanczosWeight(vec2 x, float r) {
    return lanczosWeight(x.x, r) * lanczosWeight(x.y, r);
}

vec3 lanczos(vec2 coord, int r) {
    vec2 res    = screenSize;
    vec2 ccoord = floor(coord * res) / res;
    vec2 icoord = floor(coord * res);

    vec3  total  = vec3(0);    
    for (int x = -r; x <= r; x++) {
        for (int y = -r; y <= r; y++) {
            vec2  offs = vec2(x,y);
            
            vec2  sampleCoords = icoord + offs;
            vec3  val          = texelFetch(colortex0, ivec2(sampleCoords), 0).rgb;
            
            vec2  d            = sampleCoords - (coord * res);
            float weight = lanczosWeight(d, float(r));
            
            total     += val * weight;
        }
    }

    return total;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
    #if SUPER_SECRET_SETTING == 1
    coord += sin(coord.x * TWO_PI) * 0.1;
    #endif

#ifdef TAA
    float sharpen_amount = clamp(length(cameraPosition - previousCameraPosition) * 1e2, 0.25 * TAA_SHARPENING_AMOUNT, 1.0) * TAA_SHARPENING_AMOUNT;
    //vec3  color = sharpen2(coord, sharpen_amount);
    vec3  color = sharpen(getSharpenData(coord), getAlbedo(coord), sharpen_amount);
#else
    vec3  color = getAlbedo(coord);
    //color = smartUpscale(colortex0, coord).rgb;
#endif

    
#ifdef DEBUG 
    color = debugView(coord);
#endif

    // Remove Banding (yay)
    const float displayPrecision = 1./255.;
    color += (Bayer4(coord * screenSize) - .5) * displayPrecision;

    FragOut0 = vec4(color, 1.0);
}

