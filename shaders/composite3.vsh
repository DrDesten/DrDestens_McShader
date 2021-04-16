#version 130

uniform float viewWidth;
uniform float viewHeight;

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

out vec2 coord;
out vec2 pixelSize;
out vec3 lightVector;

void main() {
    gl_Position = ftransform();

    coord = gl_MultiTexCoord0.st;
    
    float pixelWidth = 1.0 / viewWidth;
    float pixelHeight = 1.0 / viewHeight;

    pixelSize = vec2(pixelWidth, pixelHeight);

    
    if (worldTime < 13000 || worldTime > 23000) {
        lightVector = normalize(sunPosition);
    } else {
        lightVector = normalize(moonPosition);
    }
}