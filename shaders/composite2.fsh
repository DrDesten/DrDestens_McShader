
/*

const int colortex0Format = RGBA16F; // Color

const int colortex1Format = RGB8;          // f0, roughness, Height (and in the future other PBR values)
const int colortex2Format = RGB8_SNORM;    // Normals

const int colortex3Format = R8;             // colortex3 = blockId
const int colortex4Format = R11F_G11F_B10F; // DOF 2 (DOF1 is colortex0) + Bloom

const int colortex5Format = R11F_G11F_B10F; // TAA


*/

const bool colortex0Clear      = false;
const bool colortex1Clear      = false;
const bool colortex2Clear      = false;
//const bool colortex3Clear      = false;
const bool colortex4Clear      = false;
const bool colortex5Clear      = false;

const vec4 colortex1ClearColor = vec4(0,1,0,1);
const vec4 colortex3ClearColor = vec4(0,0,0,0);
const vec4 colortex4ClearColor = vec4(.5, .5, .5, 1);

const float eyeBrightnessHalflife = 1.0;

const float sunPathRotation = -35;        // [-50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]
const float ambientOcclusionLevel = 1.00; // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         REFLECTIONS AND WATER EFFECTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////

//const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/lib/transform.glsl"

uniform float rainStrength;
#include "/lib/sky.glsl"

uniform sampler2D depthtex1;
#ifdef PHYSICALLY_BASED
uniform sampler2D colortex1;
#endif

uniform float frameTimeCounter;

uniform float near;
uniform float far;

uniform float nearInverse;
uniform float aspectRatio;

uniform ivec2 eyeBrightnessSmooth;
uniform float lightBrightness;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

const vec3 waterAbsorptionColor = vec3(WATER_ABSORPTION_COLOR_DAY_R, WATER_ABSORPTION_COLOR_DAY_G, WATER_ABSORPTION_COLOR_DAY_B) * water_absorption_color_mult;

struct position { // A struct for holding positions in different spaces
    vec3 screen;
    vec3 clip;
    vec3 view;
    vec3 vdir;
};

vec4 CubemapStyleReflection(vec3 viewPos, vec3 normal) {
    vec3 reflection   = reflect(viewPos, normal);
    vec4 screenPos    = backToClipW(reflection) * .5 + .5;

    if (clamp(screenPos.xy, vec2(-.5 * SSR_DEPTH_TOLERANCE, -.1), vec2(.5 * SSR_DEPTH_TOLERANCE + 1., 1.1)) != screenPos.xy || screenPos.w <= .5 || getDepth(screenPos.xy) == 1) {
        return vec4(getFog(toPlayerEye(reflection)), 0);
    }
    return vec4(getAlbedo(distortClamp(screenPos.xy)), 1);
}

/* vec4 universalSSR(position pos, vec3 normal) { // Old Raytracer (keeping it in case I need binary refinement again)
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return vec4(getFog(toPlayerEye(viewReflection - pos.view)), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * screenSize) * 0.2;

    float zDir         = fstep(0, screenSpaceRay.z);                                          // Checks if Reflection is pointing towards the camera in the z-direction (depth)
    float zCompression = mix(pos.screen.z - 0.56, 1 - pos.screen.z, zDir);                    // Selects the maximum Z-Distance a ray can travel based on the information
    vec3  rayStep      = screenSpaceRay * saturate(abs(zCompression / screenSpaceRay.z));     // Scales the vector so that the total Z-Distance corresponds to the maximum possible Z-Distance

    //if (zCompression / screenSpaceRay.z < 0.05 )    return vec4(1,0,0,1);

    rayStep         *= (1. / SSR_STEPS);
    vec3 rayPos      = rayStep * randfac + pos.screen;

    float depthTolerance = abs(rayStep.z * max(abs(normal.x), abs(normal.y)) + rayStep.z) * SSR_DEPTH_TOLERANCE; // We have to consider: the ray step AND the angle at which the surface is hit
    float hitDepth       = 0;

    for (int i = 0; i < SSR_STEPS; i++) {

        // if (hitDepth >= 1) break; // Break if sky (bad)

        rayPos  += rayStep;
        
        hitDepth = getDepth(rayPos.xy);

        if (rayPos.z > hitDepth && hitDepth < 1 && hitDepth > 0.56 && abs(rayPos.z - hitDepth) < depthTolerance) { // Next: Binary Refinement

            #ifdef SSR_NO_REFINEMENT
                return vec4(getAlbedo(rayPos.xy), 1);
            #endif

            vec2  hitPos   = rayPos.xy;
            float lastDiff = abs(rayPos.z - hitDepth);

            // We now want to refine between "rayPos - rayStep" (Last Step) and "rayPos" (Current Step)
            rayStep      *= 0.5;
            rayPos       -= rayStep; // Go back half a step to start binary search (you start in the middle)

            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                hitDepth  = getDepth(rayPos.xy);
                rayStep  *= .5;

                if (abs(rayPos.z - hitDepth) < lastDiff) {
                    hitPos   = rayPos.xy;
                    lastDiff = abs(rayPos.z - hitDepth);
                    rayPos  -= rayStep;
                } else {
                    rayPos  += rayStep;
                }
            }

            return vec4(texture(colortex0, (rayPos.xy), 0).rgb, 1);
        }
    }

    return vec4(getFog(viewReflection - pos.view), 0);
} */

vec4 efficientSSR(position pos, vec3 normal) {
    vec3 reflection     = reflect(pos.vdir, normal);
    vec3 viewReflection = reflection + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This happens when viewReflection.z is positive
        return vec4(getFog(toPlayerEye(reflection)), 0);
    }

    vec3  screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);

    // If the reflected direction is pointing away from the camera, then calculate the maximum Z-Travel "1 - pos.screen.z"
    // Adjust the length of the ray so that the z-component is equal to the maximum z-travel "(1 - pos.screen.z) / screenSpaceRay.z)"
    // Only do so if it decreases the length "saturate()"
    screenSpaceRay *= screenSpaceRay.z > 0.0 ? saturate((1 - pos.screen.z) / screenSpaceRay.z) : 1;

    vec3  rayStep = screenSpaceRay * (1./SSR_STEPS);
    float dither  = Bayer4(gl_FragCoord.xy) * 0.2;
    vec3  rayPos  = rayStep * dither + pos.screen;

    float depthTolerance = max(abs(rayStep.z) * 3, .02 / sq(pos.view.z)) * SSR_DEPTH_TOLERANCE; // Increase depth tolerance when close, because it is usually too small in these situations

    float hitDepth = 0;
    for (int i = 0; i < SSR_STEPS; i++) {

        rayPos += rayStep;

        if (saturate(rayPos.y) != rayPos.y) break;

        hitDepth = getDepth(rayPos.xy);

        if (hitDepth < rayPos.z && hitDepth > 0.56 && hitDepth < 1 && abs(rayPos.z - hitDepth) < depthTolerance) {
            return vec4(getAlbedo(rayPos.xy), 1);
        }

    }

    return vec4(getFog(toPlayerEye(reflection)), 0);
}


/* DRAWBUFFERS:0 */
void main() {

    float id          = getID(ivec2(gl_FragCoord.xy));
    float depth       = getDepth(ivec2(gl_FragCoord.xy));
    float linearDepth = linearizeDepthf(depth, nearInverse);
    
    #ifdef WATER_EFFECTS
    #ifdef REFRACTION
    if (id == 10) {   // REFRACTION <SEE THROUGH> /////////////////////////////////////////////////////////////

        vec2 noiseCoord = vec2((coord.x - 0.5) * aspectRatio, coord.y - 0.5);
        vec2 distort    = vec2( sin( noise(noiseCoord * 3 * linearDepth) * TWO_PI + (frameTimeCounter * 2)) * (0.02 * REFRACTION_AMOUNT) );
        coord += distort / linearDepth;

    }
    if (isEyeInWater != 0) {   // REFRACTION <IN MEDIUM> /////////////////////////////////////////////////////////////

        vec2 noiseCoord = vec2((coord.x - 0.5) * aspectRatio, coord.y - 0.5);
        vec2 distort    = vec2( sin( noise(noiseCoord * 10) * TWO_PI + (frameTimeCounter * 2)) * (0.005 * REFRACTION_AMOUNT) );
        coord += distort;

    }
    #endif

    depth       = getDepth(coord);
    linearDepth = min( linearizeDepthf(depth, nearInverse), 1e5); // I have to clamp it else the sky is inf (resulting in NaNs)

    #ifdef PHYSICALLY_BASED
    vec3  viewPos = toView(vec3(coord, depth) * 2 - 1);
    vec3  viewDir = normalize(viewPos);
    vec3  normal  = normalize(getNormal(coord));
    #endif

    vec3  color = getAlbedo(coord);

    if (id == 10 || (id == 53 && depth != 1)) {

        // ABSORPTION <SEE THROUGH> /////////////////////////////////////////////////////////////
        if (isEyeInWater == 0) {

            float transparentDepth       = texture(depthtex1, coord).r;
            float transparentLinearDepth = min( linearizeDepthf(transparentDepth, nearInverse), 1e5);

            float absorption = exp(-abs(transparentLinearDepth - linearDepth) * WATER_ABSORPTION_DENSITY - (WATER_ABSORPTION_DENSITY * WATER_ABSORPTION_BIAS));

            vec3  waterColor = waterAbsorptionColor * (eyeBrightnessSmooth.y * (.9/140) + .01) * getSky(0.5);
            color = mix(waterColor, color, absorption);

        }

        // SCREEN SPACE REFLECTION <WATER> /////////////////////////////////////////////////////////////

        #ifndef PHYSICALLY_BASED
        vec3  viewPos = toView(vec3(coord, depth) * 2 - 1);
        vec3  viewDir = normalize(viewPos);
        vec3  normal  = getNormal(coord);
        #endif

        float fresnel = customFresnel(viewDir, normal, 0.05, 1, 3);

        #if SSR_MODE == 0
        position posData = position(vec3(coord, depth), vec3(coord, depth) * 2 - 1, viewPos, viewDir);
        vec4  reflection = efficientSSR(posData, normal);
        #else
        vec4  reflection = CubemapStyleReflection(viewPos, normal);
        #endif

        #if defined END
        reflection.rgb *= saturate(0.5 + reflection.a);
        #else
        reflection.rgb *= saturate(eyeBrightnessSmooth.y * (1./140) + reflection.a);
        #endif

        color = mix(color, reflection.rgb, fresnel);

        #ifdef SSR_DEBUG
        color = vec3(0, reflection.a, fresnel);
        #endif

    }
    #endif

    #ifdef PHYSICALLY_BASED

        // SCREEN SPACE REFLECTION <PBR> /////////////////////////////////////////////////////////////

        float f0 = texture(colortex1, coord).r;
        if (f0 > SSR_REFLECTION_THRESHOLD && depth < 1.0) {

            float fresnel = schlickFresnel(viewDir, normal, f0);

            #if SSR_MODE == 0
            position posData = position(vec3(coord, depth), vec3(coord, depth) * 2 - 1, viewPos, viewDir);
            vec4 reflection = efficientSSR(posData, normal);
            #else
            vec4 reflection = CubemapStyleReflection(Positions, normal, false);
            #endif

            /* vec3 albedoTint = normalizeColor(color);
            color = mix(color, reflection.rgb * albedoTint, fresnel * reflection.a); */
            color = mix(color, reflection.rgb, fresnel * reflection.a);

            #ifdef SSR_DEBUG
            color = vec3(fresnel, reflection.a, 0);
            #endif

        }

    #endif
    
    #ifdef WATER_EFFECTS
    // ABSORPTION <IN MEDIUM> /////////////////////////////////////////////////////////////
    if (isEyeInWater == 1) {

        float absorption = exp(-linearDepth * (0.2 * WATER_ABSORPTION_DENSITY));
        vec3  waterColor = waterAbsorptionColor * (eyeBrightnessSmooth.y * (.9/140) + .01) * gamma(fogColor);
        color            = mix(waterColor, color, absorption);

    } else if (isEyeInWater == 2) {

        float absorption = exp(-abs(linearDepth));
        color            = mix(gamma(fogColor), color, absorption);

    }
    #endif
    
    //Pass everything forward
    gl_FragData[0] = vec4(color, 1);
}