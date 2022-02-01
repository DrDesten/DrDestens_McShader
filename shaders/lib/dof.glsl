
vec3 chromaticAberrationTint(vec2 relPos) {
    float chromAbb     = relPos.x * chromaticAberrationDoF + 0.5;
    vec3  chromAbbTint = vec3(chromAbb, 0.75 - abs(chromAbb - 0.5), 1 - chromAbb) * 2;
    return chromAbbTint;
}


#define PLANE_DIST 5e-3
vec2 getCoC(float linearDepth, float focusLinearDepth, float aspect, float scale) {
    float focalLength = 1 / ((1/focusLinearDepth) + (1/PLANE_DIST));

    float zaehler = focalLength * (focusLinearDepth - linearDepth);
    float nenner  = linearDepth * (focusLinearDepth - focalLength);
    float CoC     = abs(zaehler / nenner) * scale;
    return vec2(CoC, CoC * aspect);
}

vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    vec2 sample   = blurStep * 0.5 + coord;

    for (int i = 0; i < samples; i++) {
        col    += texture(tex, sample).rgb;
        sample += blurStep;
    }

    return col * samplesInv;
}
vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    vec2 sample   = blurStep * 0.5 + coord;

    for (int i = 0; i < samples; i++) {
        col    += textureLod(tex, sample, lod).rgb;
        sample += blurStep;
    }

    return col * samplesInv;
}
