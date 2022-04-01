#include "/lib/settings.glsl"
#include "/lib/math.glsl"

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

/* DRAWBUFFERS:03 */
void main() {
    gl_FragData[0] = vec4(starData.a == 1 ? starData.rgb : vec3(0), 1.0);
    gl_FragData[1] = vec4((50./255.), vec3(1));
}