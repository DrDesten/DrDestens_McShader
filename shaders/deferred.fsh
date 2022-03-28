#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/sky.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

//////////////////////////////////////////////////////////////////////////////
//                     SKY RENDERING
//////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:0 */
void main() {
    #ifndef SCREEN_SPACE_AMBIENT_OCCLUSION
    discard;
    #endif

    float depth = getDepth(coord);
    vec3  screenPos = vec3(coord, depth);
    vec3  color;
    
    if (depth >= 1) { // SKY

        color = getSky(toPlayerEye(toView(screenPos * 2 - 1)));

    } else { // NO SKY

        color = getAlbedo(coord);

    }
    
    gl_FragData[0] = vec4(color, 1.0);
}