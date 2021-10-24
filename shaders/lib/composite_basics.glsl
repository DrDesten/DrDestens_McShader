layout(location = 0) out vec4 FD0;
layout(location = 1) out vec4 FD1;
layout(location = 2) out vec4 FD2;
layout(location = 3) out vec4 FD3;
layout(location = 4) out vec4 FD4;
layout(location = 5) out vec4 FD5;
layout(location = 6) out vec4 FD6;
layout(location = 7) out vec4 FD7;
layout(location = 8) out vec4 FD8;
layout(location = 9) out vec4 FD9;


uniform sampler2D colortex0; // Color
uniform sampler2D colortex1; // Normals
uniform sampler2D colortex2; // ID
uniform sampler2D depthtex0; // Depth

vec3 getColor(vec2 co) {
    return texture(colortex0, co).rgb;
}
float getDepth(vec2 co) {
    return texture(depthtex0, co).x;
}

vec3 getNormal(vec2 co) {
    return texture(colortex1, co).xyz;
}
float getID(vec2 co) {
    return floor(texture(colortex2, co).x * 255 + 0.5);
}
float codeID(float id) {
    return id * .00392156862745;
}