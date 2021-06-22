#version 130

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

out vec2 coord;
out vec3 lightVector;

void main() {
    gl_Position = ftransform();

    coord = gl_MultiTexCoord0.st;
    
    if (worldTime < 13000 || worldTime > 23000) {
        lightVector = normalize(sunPosition);
    } else {
        lightVector = normalize(moonPosition);
    }
}