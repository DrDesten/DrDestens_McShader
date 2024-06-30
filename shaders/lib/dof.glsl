
vec3 chromaticAberrationTint(vec2 relPos) {
    float chromAbb     = relPos.x * chromaticAberrationDoF + 0.5;
    vec3  chromAbbTint = vec3(chromAbb, 0.75 - abs(chromAbb - 0.5), 1 - chromAbb) * 2;
    return chromAbbTint;
}
vec3 chromaticAberrationTint(float relPos) {
    return chromaticAberrationTint(vec2(relPos));
}


#define PLANE_DIST 5e-3
float getCoC(float linearDepth, float focusLinearDepth, float scale) {
    float focalLength = 1 / ((1/focusLinearDepth) + (1/PLANE_DIST));

    float zaehler = focalLength * (focusLinearDepth - linearDepth);
    float nenner  = linearDepth * (focusLinearDepth - focalLength);
    return abs(zaehler / nenner) * scale;
}
float getCoC_sign(float linearDepth, float focusLinearDepth, float scale) {
    float focalLength = 1 / ((1/focusLinearDepth) + (1/PLANE_DIST));

    float zaehler = focalLength * (focusLinearDepth - linearDepth);
    float nenner  = linearDepth * (focusLinearDepth - focalLength);
    return (zaehler / nenner) * scale;
}
vec2 aspectCorrect(vec2 circular, float aspect) {
    return vec2(circular.x, circular.y * aspect);
}
vec2 aspectCorrect(float circular, float aspect) {
    return vec2(circular, circular * aspect);
}

vec3 hexBokehVectorBlur_noReject(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    vec2 scoord   = blurStep * 0.5 + coord;

    for (int i = 0; i < samples; i++) {        
        col     += textureLod(tex, scoord, lod).rgb;
        scoord  += blurStep;
    }

    return col * samplesInv;
}

vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod, float aspect) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    vec2 scoord   = blurStep * 0.5 + coord;
    
    float stepLength = length(blurStep);
    float cocBias    = screenSizeInverse.x * lod + screenSizeInverse.x;

    float aspectLengthChange = sqrt(aspect * aspect + 1.);

    float tw = 0;
    for (int i = 0; i < samples; i++) {
        vec3  sampleColor = textureLod(tex, scoord, lod).rgb; // Sample Color
        float sampleCoc   = textureLod(tex, scoord + blurStep * lod, lod).a; // Sample CoC

        sampleCoc = saturate(sampleCoc - cocBias) * aspectLengthChange;
        //sampleCoc = length(aspectCorrect(sampleCoc, aspect));
        float d   = stepLength * float(i) + stepLength;
        if (sampleCoc <= d) break; 
        
        col     += sampleColor;
        tw      += 1;
        scoord  += blurStep;
    }

    return tw <= 0 ? textureLod(tex, coord, 0).rgb : col / tw;
}
vec3 hexBokehVectorBlur_ChromAbb(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod, float aspect) {
    vec2 blurStep = vector * samplesInv;
    vec2 scoord   = blurStep * 0.5 + coord;
    
    float stepLength = length(blurStep);
    float cocBias    = screenSizeInverse.x * lod + screenSizeInverse.x;

    float aspectLengthChange = sqrt(aspect * aspect + 1.);

    vec3  totalTint, col = vec3(0);
    for (int i = 0; i < samples; i++) {
        vec3  sampleColor = textureLod(tex, scoord, lod).rgb; // Sample Color
        float sampleCoc   = textureLod(tex, scoord + blurStep * lod, lod).a; // Sample CoC

        sampleCoc = saturate(sampleCoc - cocBias) * aspectLengthChange;
        //sampleCoc = length(aspectCorrect(sampleCoc, aspect));
        float d   = stepLength * float(i) + stepLength;
        if (sampleCoc <= d) break; 
        
        vec3 tint = chromaticAberrationTint(i * (1./samples) - 0.5);

        col       += sampleColor * tint;
        totalTint += tint;
        scoord    += blurStep;
    }

    //return col / totalTint;
    return sum(totalTint) <= 0 ? textureLod(tex, coord, 0).rgb : col / totalTint;
}

vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv, float lod, float aspect, sampler2D coctex) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    vec2 scoord   = blurStep * 0.5 + coord;

    float stepLength = length(blurStep);
    float cocBias    = screenSizeInverse.x * lod + screenSizeInverse.x;
    
    float aspectLengthChange = sqrt(aspect * aspect + 1.);

    float tw = 0;
    for (int i = 0; i < samples; i++) {
        vec3  sampleColor = textureLod(tex, scoord, lod).rgb; // Sample Color
        float sampleCoc   = textureLod(coctex, scoord + blurStep * lod, lod).a; // Sample Coc

        sampleCoc = saturate(sampleCoc - cocBias) * aspectLengthChange;
        //sampleCoc = length(aspectCorrect(sampleCoc, aspect)); aspectLengthChange does the equivalent
        float d   = stepLength * float(i) + stepLength;
        if (sampleCoc <= d) break;
        
        col     += sampleColor;
        tw      += 1;
        scoord  += blurStep;
    }

    return tw <= 0 ? textureLod(tex, coord, 0).rgb : col / tw;
}