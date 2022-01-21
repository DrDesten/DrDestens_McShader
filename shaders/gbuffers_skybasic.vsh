#include "/lib/settings.glsl"
#include "/lib/math.glsl"

out vec3 viewpos;

void main() {
    gl_Position = ftransform();

    if(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0) { // No stars for you
        gl_Position.xy = vec2(2 * gl_Position.w);
    }

    viewpos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz;
}