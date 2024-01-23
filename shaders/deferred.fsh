#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
#include "/lib/sky.glsl"

//////////////////////////////////////////////////////////////////////////////
//                     SKY RENDERING
//////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
    float depth     = getDepth(coord);
    vec3  screenPos = vec3(coord, depth);
    vec3  color     = getAlbedo(coord);
    
    if (depth == 1) { // SKY

#ifdef OVERWORLD
        color += getSky(toPlayerEye(toView(screenPos * 2 - 1)));
#else
        color = getSky(toPlayerEye(toView(screenPos * 2 - 1)));
#endif

    } else { // NO SKY

    }
    
    FragOut0 = vec4(color, 1.0);
}