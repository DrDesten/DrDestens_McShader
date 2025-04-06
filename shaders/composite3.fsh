//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                    DENOISE AND OUTLINE AND FOG
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/core/kernels.glsl"

#if defined GODRAYS && defined OVERWORLD
uniform sampler2D depthtex1;
uniform int   frameCounter;
uniform vec4  lightPositionClip; // lightPositionClip returns the clip position of the light with the homogenous w-component
uniform float aspectRatio;
#endif

#ifdef POM_ENABLED
#include "/lib/pbr/pbr.glsl"
#include "/lib/pbr/read.glsl"
#endif

#ifdef HAND_INVISIBILITY_EFFECT
uniform float isInvisibleSmooth;
#endif

uniform float frameTimeCounter;
#if FOG != 0 || (defined GODRAYS && defined OVERWORLD)
uniform float far;
#include "/lib/sky.glsl"
#endif

uniform float blindness;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

float depthEdge(vec2 coord, float depth) {
    depth = texelFetch(depthtex0, ivec2(clamp(coord * screenSize - 2, vec2(0), screenSize)), 0).x;
    float maxdiff  = 0;
    for (int x = 0; x <= 2; x++) {
        for (int y = 0; y <= 2; y++) {
            float d = texelFetch(depthtex0, ivec2(clamp(coord * screenSize - 2, vec2(0), screenSize)) + ivec2(x, y), 0).x;
            maxdiff = max(maxdiff, abs(d-depth));
        }
    }
    return clamp(pow(maxdiff * 2e2 * OUTLINE_DISTANCE, 7), 0, 1);
}

float depthEdgeFast(vec2 coord, float depth) { // Essentially the same speed
    ivec2 intcoord = ivec2(coord * screenSize);
    float maxdiff  = 0;
    for (int x = -1; x <= 1; x++) {
        ivec2 c = intcoord; //ivec2(saturate(coord) * (screenSize - 2)) + 1;
        c.x    += x;
        float d = texelFetch(depthtex0, c, 0).x;
        maxdiff = max(maxdiff, abs(d-depth));
    }
    for (int y = -1; y <= 1; y++) {
        ivec2 c = intcoord; //ivec2(saturate(coord) * (screenSize - 2)) + 1;
        c.y    += y;
        float d = texelFetch(depthtex0, c, 0).x;
        maxdiff = max(maxdiff, abs(d-depth));
    }
    return clamp(pow(maxdiff * 2e2 * OUTLINE_DISTANCE, 7), 0, 1);
}

vec3 vectorBlur(vec2 coord, vec2 blur, int samples) {
    if (sqmag(blur) < sq(screenSizeInverse.x)) { return getAlbedo(coord); }

    vec3 col      = vec3(0);
    vec2 blurStep = blur / float(samples);
    vec2 scoord   = coord;

    for (int i = 0; i < samples; i++) {
        col    += getAlbedo(scoord);
        scoord += blurStep;
    }

    return col / float(samples);
}

float mapHeight(float height, float maxVal) {
    return sq(sq(height)) * -maxVal + maxVal;
}
float mapHeightSimple(float height, float maxVal) {
    return height * -maxVal + maxVal;
}


float customLength(vec2 vec, float power) {
    return pow(pow(abs(vec.x), power) + pow(abs(vec.y), power), 1/power);
}
float customLengthPow(vec2 vec, float power) {
    return pow(abs(vec.x), power) + pow(abs(vec.y), power);
}

vec2 warpCoord(vec2 co) {
    return -1 / (exp(4 * (co-0.5)) + 1) + 1;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
    vec3  color = getAlbedo(ivec2(gl_FragCoord.xy));
    float depth = getDepth(ivec2(gl_FragCoord.xy));
    float id    = getID(ivec2(gl_FragCoord.xy));

    //////////////////////////////////////////////////////////////////////////////
    //                              POM
    //////////////////////////////////////////////////////////////////////////////

#ifdef POM_ENABLED

        if (depth > 0.56 && depth < 0.998) {
            MaterialTexture material = getPBR(ivec2(gl_FragCoord.xy));
#ifdef POM_DISTORTION
            float height    = mapHeight(material.height, POM_DEPTH);
#else
            float height    = mapHeightSimple(material.height, POM_DEPTH);
#endif
            height         *= sq(depth * (1./0.56) - 1); // Reduce POM height closer to the camera (anything closer than the hand does not have POM anymore)

            vec3 viewPos      = toView(vec3(coord, depth) * 2 -1);
            vec3 playerPos    = toPlayerEye(viewPos);
            vec3 playerNormal = normalize(cross(dFdx(playerPos), dFdy(playerPos))); // Calculate normals based on derivatives (faster, accurate eniugh)

            vec3 playerPOM = playerPos + (playerNormal * height);

            vec3  POMPos   = backToScreen(eyeToView(playerPOM));
            POMPos.xy      = mirrorClamp(POMPos.xy);
            float POMdepth = getDepth(POMPos.xy);

            float distSQ   = sqmag(playerPos);
            bool error = POMdepth < 0.56 || distSQ > 500;
            if (!error) {

                color  = getAlbedo(POMPos.xy);

                float distFade = saturate(map(distSQ, 300, 500, 1, 0.2));
                //color *= texture(colortex3, POMPos.xy).w * distFade + (1 - distFade);

                #ifdef POM_DEBUG
                color  = vec3(height);
                #endif

            }
            depth  = POMdepth;

        } else if (depth <= 0.56) {
            color *= texture(colortex3, coord).w;
        }

    #endif

    //////////////////////////////////////////////////////////////////////////////
    //                              OUTLINE
    //////////////////////////////////////////////////////////////////////////////

    #if OUTLINE != 0

        float outline = depthEdge(coord, depth);
        #if OUTLINE == 1
         color = mix(color, vec3(1), outline * OUTLINE_BRIGHTNESS);
        #elif OUTLINE == 2
         color = color * saturate( -outline * OUTLINE_BRIGHTNESS + 1);
        #else
         color = mix(color, cos( ((frameTimeCounter * 0.5) + (coord * 4).xyx + vec3(0, 0, 4)) ) + 1, outline);
        #endif
        
    #endif

    //////////////////////////////////////////////////////////////////////////////
    //                              GODRAYS
    //////////////////////////////////////////////////////////////////////////////

    #if defined GODRAYS && defined OVERWORLD
    if (lightPositionClip.w > 0 && rainStrength < 1) { // If w is negative, the sun is on the opposite side of the screen (this causes bugs, I don't want that)

        // Finish screen space transformation
        vec2 sunScreen    = lightPositionClip.xy * 0.5 + 0.5;

        // Create ray pointing from the current pixel to the sun
        vec2 ray          = sunScreen - coord;
        vec2 rayCorrected = vec2(ray.x * aspectRatio, ray.y); // Aspect Ratio corrected ray for accurate exponential decay

        // Exponential falloff (also making it FOV independent)
        float falloff     = exp2(-sqmag(rayCorrected / (fovScale * GODRAY_SIZE)));

        if (falloff > 1./256) {

            vec2 rayStep      = ray / GODRAY_STEPS;
            #ifndef TAA
            vec2 rayPos  = coord - (Bayer8(coord * screenSize) * rayStep);
            #else
            float dither = fract(Bayer8(coord * screenSize) + frameCounter * PHI);
            vec2  rayPos = coord - ( dither * rayStep);
            #endif

            float light = 1;
            for (int i = 0; i < GODRAY_STEPS; i++ ) {

                rayPos += rayStep;

                if (isEyeInWater != 0) {
                    if (texture(depthtex1, rayPos).x != 1) { // Subtract from light when there is an occlusion
                        light -= 1. / GODRAY_STEPS;
                    }
                } else {
                    if (texture(depthtex0, rayPos).x != 1) { // Subtract from light when there is an occlusion
                        light -= 1. / GODRAY_STEPS;
                    }
                }

            }

            #if FOG != 0
                color += saturate(light * falloff * GODRAY_STRENGTH * getGodrayColor()); // Additive Effect
            #else
                color += saturate(light * falloff * GODRAY_STRENGTH * fogColor); // Additive Effect
            #endif
        }

    }
    #endif

    
    //////////////////////////////////////////////////////////////////////////////
    //                              EFFECTS
    //////////////////////////////////////////////////////////////////////////////

    #ifdef HAND_INVISIBILITY_EFFECT

        if (getID(coord) == 51 && isInvisibleSmooth > 0.0001) { // Hand invisbility Effect

            vec2 seed1 = coord * 15 + vec2(0., frameTimeCounter * 2);
            vec2 seed2 = coord * 15 + vec2(frameTimeCounter * 2, 0.);
            vec2 noise = vec2(
                fbm(seed1, 2, 5, .05), 
                fbm(seed2, 2, 5, .05)
            );
            noise = normalize(noise - .25) * isInvisibleSmooth * 0.05;

            color = vectorBlur(coord + noise, -(noise * Bayer4(coord * screenSize)), 5);
        }

    #endif

    if (blindness > 0) { // Handling Blindness
        float dist = sqmag(toView(vec3(coord, depth) * 2 - 1));
        color     /= sq(dist * blindness + 1);
    }

    //Pass everything forward
    FragOut0 = vec4(color, 1);
}