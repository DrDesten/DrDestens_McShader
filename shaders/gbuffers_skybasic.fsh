#include "/lib/settings.glsl"
#include "/core/math.glsl"

in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

/* DRAWBUFFERS:02 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;

void main() {
    FragOut0 = vec4(starData.a == 1 ? starData.rgb : vec3(0), 1.0);
    FragOut1 = vec4((50./255.), vec3(1));
    ALPHA_DISCARD(FragOut0);
}