#include "/lib/settings.glsl"
#include "/lib/math.glsl"

out vec3 viewpos;

void main() {
    gl_Position = ftransform();

    viewpos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz;
}