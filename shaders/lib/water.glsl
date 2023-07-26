float waterOffsetSine(vec3 pos, float time) {
    pos.xz *= 0.25;
    pos.xz += time;

    float       offset   = 0;
    const mat2 rot       = MAT2_ROT(0.7, 2);
    vec2       shift     = vec2(.5, -2);
    float      amplitude = 0.4;

    offset += sin(pos.x) * amplitude + cos(pos.z) * amplitude;
    for (int i = 0; i < 1; i++) {
        pos.xz     = rot * pos.xz + shift * time;
        amplitude *= 0.25;
        offset    += sin(pos.x) * amplitude + cos(pos.z) * amplitude;
    }

    return offset;
}

float waterVertexOffset(vec3 pos, float time) {
    float flowHeight = fract(pos.y + 0.01);
    float offset     = waterOffsetSine(pos, time);

    float lowerbound = flowHeight;
    float upperbound = 1 - flowHeight;
    offset          *= (offset < 0 ? lowerbound : upperbound)
                     * float(flowHeight > 0.05);
    return offset;
}

vec3 waterNormalsSine(vec3 pos, float time) {
    pos.xz *= 2;
    time    = mod(time * 0.25, 1000) - 500;

    vec2       derivative = vec2(0);
    const mat2 rot        = MAT2_ROT(.9, 1.5);
    vec2       shift      = vec2(1,0);
    float      amplitude  = 1;

    for (int i = 0; i < 4; i++) {
        amplitude *= 0.5;
        pos.xz     = rot * pos.xz + shift * time;

        derivative.x +=  cos(dot(pos.xz, vec2(0.8, 0.2))) * amplitude;
        derivative.y += -sin(dot(pos.xz, vec2(0.3, 0.7))) * amplitude;
    }

    vec3 tangent   = vec3(1, 0, derivative.x);
    vec3 bitangent = vec3(0, 1, derivative.y);
    vec3 normal    = normalize(cross(tangent, bitangent));
    return normal;
}