

uniform vec2 screenSizeInverse;

out vec2 coord;

flat out vec2 x3_kernel[9];

void main() {
    gl_Position = ftransform();

    coord = gl_MultiTexCoord0.st;

    for (int i = 0; i < 3; i++) {
        for (int o = 0; o < 3; o++) {
            vec2 stepsize = vec2(screenSizeInverse.x * (i-1), screenSizeInverse.y * (o-1));

            x3_kernel[o * 3 + i] = coord + stepsize;
        }
    }

}