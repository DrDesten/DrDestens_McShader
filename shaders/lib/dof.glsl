
vec3 chromaticAberrationTint(vec2 relPos) {
    float chromAbb     = relPos.x * chromaticAberrationDoF + 0.5;
    vec3  chromAbbTint = vec3(chromAbb, 0.75 - abs(chromAbb - 0.5), 1 - chromAbb) * 2;
    return chromAbbTint;
}


#define PLANE_DIST 5e-3
float getCoC(float linearDepth, float focusLinearDepth, float scale) {
    float focalLength = 1 / ((1/focusLinearDepth) + (1/PLANE_DIST));

    float zaehler = focalLength * (focusLinearDepth - linearDepth);
    float nenner  = linearDepth * (focusLinearDepth - focalLength);
    float CoC     = abs(zaehler / nenner) * scale;
    return CoC;
}
vec2 aspectCorrect(vec2 circular, float aspect) {
    return vec2(circular.x, circular.y * aspect);
}
vec2 aspectCorrect(float circular, float aspect) {
    return vec2(circular, circular * aspect);
}


/* vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    vec2 sample   = blurStep * 0.5 + coord;

    for (int i = 0; i < samples; i++) {
        col    += textureLod(tex, sample, lod).rgb;
        sample += blurStep;
    }

    return col * samplesInv;
} */
/* vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod, float aspect) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    float stepLength = length(blurStep);
    vec2 sample   = blurStep * 0.5 + coord;

    float tw = 1;
    for (int i = 0; i < samples; i++) {
        vec4  s  = textureLod(tex, sample, lod); // Sample
        float sc = length(aspectCorrect(s.a, aspect));

        float d  = stepLength * float(i);
        float w  = float(sc >= d);
        
        col     += s.rgb * w;
        tw      += w;
        sample  += blurStep;
    }

    //return col * samplesInv;
    return col / tw;
} */
vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod, float aspect) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    float stepLength = length(blurStep);
    vec2 sample   = blurStep * 0.5 + coord;

    float tw = 0;
    for (int i = 0; i < samples; i++) {
        vec4  s  = textureLod(tex, sample, lod); // Sample

        s.a      = saturate(s.a - screenSizeInverse.x);
        float sc = length(aspectCorrect(s.a, aspect));
        float d  = stepLength * float(i) + stepLength;
        if (sc <= d) break;
        
        col     += s.rgb;
        tw      += 1;
        sample  += blurStep;
    }

    //return col * samplesInv;
    //return tw == 0 ? vec3(1,0,0) : col / tw;
    return tw == 0 ? textureLod(tex, sample, 0).rgb : col / tw;
}
vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod, float aspect, sampler2D coctex) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    float stepLength = length(blurStep);
    vec2 sample   = blurStep * 0.5 + coord;

    float tw = 0;
    for (int i = 0; i < samples; i++) {
        vec4  s  = textureLod(tex, sample, lod); // Sample
        s.a      = textureLod(coctex, sample, lod).a; // Coc sample

        float sc = length(aspectCorrect(s.a, aspect));
        float d  = stepLength * float(i) + stepLength;
        if (sc <= d) break;
        
        col     += s.rgb;
        tw      += 1;
        sample  += blurStep;
    }

    //return col * samplesInv;
    //return tw == 0 ? vec3(1,0,0) : col / tw;
    return tw == 0 ? textureLod(tex, sample, 0).rgb : col / tw;
}