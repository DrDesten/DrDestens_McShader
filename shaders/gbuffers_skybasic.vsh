#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"

out vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

void main() {
    gl_Position = ftransform();
    starData    = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
}