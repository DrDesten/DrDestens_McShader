//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                    DENOISE AND OUTLINE AND FOG
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/skyColor.glsl"
#include "/lib/kernels.glsl"
#include "/lib/dof.glsl"

uniform sampler2D depthtex1;
uniform sampler2D colortex1;
uniform sampler2D colortex4;

uniform float centerDepthSmooth;

uniform float frameTimeCounter;
uniform int   frameCounter;
uniform float rainStrength;

uniform vec3  lightPosition;

uniform float isInvisibleSmooth;
uniform float blindness;

uniform float near;
uniform float far;
uniform float aspectRatio;

uniform int   isEyeInWater;

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
    vec2 sample   = coord;

    for (int i = 0; i < samples; i++) {
        col    += getAlbedo(sample);
        sample += blurStep;
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

void main() {
    vec3  color = getAlbedo(coord);
    float depth = getDepth(coord);
    float id    = getID(coord);

    #ifdef POM_ENABLED

        if (depth > 0.56 && depth < 0.998) {
            #ifdef POM_DISTORTION
             float height    = mapHeight(texture(colortex1, coord).g, POM_DEPTH);
            #else
             float height    = mapHeightSimple(texture(colortex1, coord).g, POM_DEPTH);
            #endif
            height         *= sq(depth * (1./0.56) - 1); // Reduce POM height closer to the camera (anything closer than the hand does not have POM anymore)

            vec3 viewPos      = toView(vec3(coord, depth) * 2 -1);
            vec3 playerPos    = toPlayerEye(viewPos);
            vec3 playerNormal = normalize(cross(dFdx(playerPos), dFdy(playerPos))); // Calculate normals based on derivatives (faster, accurate eniugh)

            vec3 playerPOM = playerPos + (playerNormal * height);

            vec3  POMPos   = backToScreen(eyeToView(playerPOM));
            POMPos.xy      = mirrorClamp(POMPos.xy);
            float POMdepth = getDepth_int(POMPos.xy);

            float distSQ   = sqmag(playerPos);
            bool error = POMdepth < 0.56 || distSQ > 500;
            if (!error) {

                color  = getAlbedo(POMPos.xy);

                float distFade = saturate(map(distSQ, 300, 500, 1, 0.2));
                color *= texture(colortex1, POMPos.xy).g * distFade + (1 - distFade);

                #ifdef POM_DEBUG
                color  = vec3(height);
                #endif

            }
            depth  = POMdepth;

        } else if (depth <= 0.56) {
            color *= texture(colortex1, coord).g;
        }

    #endif

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
    
    #if FOG != 0

        // Blend between FogColor and normal color based on square distance
        vec3 viewPos    = toView(vec3(coord, depth) * 2 - 1);
        float dist      = sqmag(viewPos) * float(depth < 1 || isEyeInWater != 0);
        dist           *= float(isEyeInWater + 1) * 10;

        #ifdef SUNSET_FOG
         #if FOG == 1
          #ifdef SKY_SUNSET
           #ifdef OVERWORLD
            dist = dist * (sunset * SUNSET_FOG_AMOUNT + 1);
           #endif
          #endif
         #endif
        #endif

        #if FOG == 1
            #ifdef END
                float fog       = 1 - exp(min(-sqrt(dist) * (5e-3 * FOG_AMOUNT) + 0.2, 0));
            #elif defined NETHER
                float fog       = 1 - exp(min(-sqrt(dist) * (3e-3 * FOG_AMOUNT) + 0.2, 0));
            #else
                float fog       = 1 - exp(min(-sqrt(dist) * (1e-3 * FOG_AMOUNT) + 0.2, 0));
            #endif
        #else
            float fog       = smoothstep(far, sq(far * 2.828), dist * FOG_AMOUNT);
        #endif

        vec3 customFogColor = getFogColor_gamma(viewPos, rainStrength, isEyeInWater);
        color               = mix(color, customFogColor, fog);

    #endif

    #ifdef OVERWORLD
    #ifdef GODRAYS

        // Start transforming sunPosition from view space to screen space
        vec4 tmp      = projectHomogeneousMAD(lightPosition, gbufferProjection);

        if (tmp.w > 0) { // If w is negative, the sun is on the opposite side of the screen (this causes bugs, I don't want that)
            // Finish screen space transformation
            vec2 sunScreen    = (tmp.xy / tmp.w) * .5 + .5;

            // Create ray pointing from the current pixel to the sun
            vec2 ray          = sunScreen - coord;
            vec2 rayCorrected = vec2(ray.x * aspectRatio, ray.y); // Aspect Ratio corrected ray for accurate exponential decay

            vec2 rayStep      = ray / GODRAY_STEPS;
            #ifndef TAA
            vec2 rayPos       = coord - (Bayer8(coord * screenSize) * rayStep);
            #else
            vec2 taa_offs     = fract(vec2(frameCounter * 0.2, -frameCounter * 0.2 - 0.5)) * 5 - 10;
            vec2 rayPos       = coord - (Bayer8(coord * screenSize + taa_offs) * rayStep);
            #endif

            float light = 1;
            for (int i = 0; i < GODRAY_STEPS; i++ ) {

                rayPos       += rayStep;

                if (isEyeInWater != 0) {
                    if (texture(depthtex1, rayPos).x != 1) { // Subtract from light when there is an occlusion
                        light    -= 1. / GODRAY_STEPS;
                    }
                } else {
                    if (texture(depthtex0, rayPos).x != 1) { // Subtract from light when there is an occlusion
                        light    -= 1. / GODRAY_STEPS;
                    }
                }

            }

            // Exponential falloff (also making it FOV independent)
            light *= exp2(-sqmag(rayCorrected / (fovScale * GODRAY_SIZE)));

            #if FOG != 0
                color += saturate(light * (GODRAY_STRENGTH * 4) * customFogColor); // Additive Effect
            #else
                color += saturate(light * GODRAY_STRENGTH * fogColor); // Additive Effect
            #endif
        }

    #endif
    #endif

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
    gl_FragData[0]          = vec4(color, 1);
}