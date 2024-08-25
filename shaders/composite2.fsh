#include "/lib/setup.glsl"

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         REFLECTIONS AND WATER EFFECTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////

//const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/core/transform.glsl"

uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
uniform float frameTimeCounter;
#include "/lib/sky.glsl"

uniform sampler2D depthtex1;

#ifdef PBR
#include "/lib/pbr/pbr.glsl"
#include "/lib/pbr/read.glsl"
//#include "/lib/pbr/ambient.glsl"
#endif

uniform float nearInverse;
uniform float aspectRatio;

uniform float lightBrightness;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

const vec3 waterAbsorptionColor = vec3(WATER_ABSORPTION_COLOR_DAY_R, WATER_ABSORPTION_COLOR_DAY_G, WATER_ABSORPTION_COLOR_DAY_B) * water_absorption_color_mult;

struct position { // A struct for holding positions in different spaces
    vec3 screen;
    vec3 clip;
    vec3 view;
    vec3 vdir;
};

vec4 CubemapStyleReflection(vec3 viewPos, vec3 reflection) {
    vec4 screenPos    = backToClipW(reflection) * .5 + .5;
    if (
        clamp(screenPos.xy, vec2(-.5 * SSR_DEPTH_TOLERANCE, -.1), vec2(.5 * SSR_DEPTH_TOLERANCE + 1., 1.1)) != screenPos.xy || 
        screenPos.w <= .5 || getDepth(screenPos.xy) == 1
    ) {
        return vec4(0);
    }

    #if REFLECTION_FADE == 0
    return vec4(getAlbedo(distortClamp(screenPos.xy)), 1);
    #elif REFLECTION_FADE == 1
    vec2 hit = distortClamp(screenPos.xy);
    return vec4(getAlbedo(hit), smoothstep(0, 1, 5 - 5 * abs(hit.y * 2 - 1)));
    #elif REFLECTION_FADE == 2
    vec2 hit = distortClamp(screenPos.xy);
    return vec4(
        getAlbedo(hit),
        smoothstep(0, 1, 3.5 - 3.5 * max(abs(hit.x * 1.5 - .75), abs(hit.y * 2 - 1)))
    );
    #endif
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

vec4 efficientSSR(position pos, vec3 reflection) {
    vec3 viewReflection = pos.view + reflection;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This happens when viewReflection.z is positive
        return vec4(0);
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
            #if REFLECTION_FADE == 0
            return vec4(getAlbedo(rayPos.xy), 1);
            #elif REFLECTION_FADE == 1
            return vec4(getAlbedo(rayPos.xy), smoothstep(0, 1, 5 - 5 * abs(rayPos.y * 2 - 1)));
            #elif REFLECTION_FADE == 2
            return vec4(
                getAlbedo(rayPos.xy),
                smoothstep(0, 1, 3.5 - 3.5 * max(abs(rayPos.x * 1.5 - .75), abs(rayPos.y * 2 - 1)))
            );
            #endif
        }

    }

    return vec4(0);
}


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
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

    #ifdef PBR
    vec3  viewPos = toView(vec3(coord, depth) * 2 - 1);
    vec3  viewDir = normalize(viewPos);
    vec3  normal  = normalize(getNormal(coord));
    #endif

    vec3  color = getAlbedo(coord);

    if (id == 10) {

        // ABSORPTION <SEE THROUGH> /////////////////////////////////////////////////////////////
        if (isEyeInWater == 0) {

            float transparentDepth       = texture(depthtex1, coord).r;
            float transparentLinearDepth = min( linearizeDepthf(transparentDepth, nearInverse), 1e5);

            float absorption = exp(-abs(transparentLinearDepth - linearDepth) * WATER_ABSORPTION_DENSITY - (WATER_ABSORPTION_DENSITY * WATER_ABSORPTION_BIAS));

            vec3  waterColor = waterAbsorptionColor * (eyeBrightnessSmooth.y * (.9/140) + .01) * getSky(vec3(1,1,0));
            color = mix(waterColor, color, absorption);

        }

        // SCREEN SPACE REFLECTION <WATER> /////////////////////////////////////////////////////////////

#if SSR_MODE != 0

        #ifndef PBR
        vec3 viewPos = toView(vec3(coord, depth) * 2 - 1);
        vec3 viewDir = normalize(viewPos);
        vec3 normal  = getNormal(coord);
        #endif

        float fresnel        = customFresnel(viewDir, normal, 0.05, 1, 3);
        vec3  reflectViewDir = reflect(viewDir, normal);


        #if SSR_MODE == 3
        position posData = position(vec3(coord, depth), vec3(coord, depth) * 2 - 1, viewPos, viewDir);
        vec4  reflection = efficientSSR(posData, reflectViewDir);
        #elif SSR_MODE == 2
        vec4  reflection = CubemapStyleReflection(viewPos, reflectViewDir);
        #else
        vec4  reflection = vec4(0);
        #endif
        if (reflection.a != 1) {
            reflection.rgb = mix(getFog(toPlayerEye(reflectViewDir)), reflection.rgb, reflection.a);
        }

        #if defined END
        reflection.rgb *= saturate(0.5 + reflection.a);
        #else
        reflection.rgb *= saturate(eyeBrightnessSmooth.y * (1./140) + reflection.a);
        #endif

        color = mix(color, reflection.rgb, fresnel);

        #ifdef SSR_DEBUG
        color = vec3(0, reflection.a, fresnel);
        #endif

#endif

    }
#else
    vec3 color = getAlbedo(coord);
#endif

#ifdef PBR

    // SCREEN SPACE REFLECTION <PBR> /////////////////////////////////////////////////////////////

#if SSR_MODE != 0

    MaterialTexture material = getPBR(ivec2(gl_FragCoord.xy));
    float f0 = 1;
    if (material.reflectance > 0.5 && depth < 1.0) {

        float fresnel = schlickFresnel(viewDir, normal, f0);
        vec3  reflectViewDir = reflect(viewDir, normal);

        #if SSR_MODE == 3
        position posData = position(vec3(coord, depth), vec3(coord, depth) * 2 - 1, viewPos, viewDir);
        vec4 reflection = efficientSSR(posData, reflectViewDir);
        #elif SSR_MODE == 2
        vec4 reflection = CubemapStyleReflection(viewPos, reflectViewDir);
        #else
        vec4 reflection = vec4(0);
        #endif

        /* if (reflection.a != 1) {
            reflection.rgb = mix(getFog(toPlayerEye(reflectViewDir)), reflection.rgb, reflection.a);
        } */
        color = mix(color, reflection.rgb, fresnel * reflection.a);

        #ifdef SSR_DEBUG
        color = vec3(fresnel, reflection.a, 0);
        #endif

    }

#endif
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
    FragOut0 = vec4(max(color, vec3(0)), 1);
}