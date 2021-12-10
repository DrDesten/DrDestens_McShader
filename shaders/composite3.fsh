
/*

const int colortex0Format = RGB16F; // Color

const int colortex1Format = RG8;            // Reflectiveness, Height (and in the future other PBR values)
const int colortex2Format = RGB16_SNORM;    // Normals

const int colortex3Format = R8;             // colortex3 = blockId
const int colortex4Format = RGB8;           // colortex4 = bloom

const int colortex5Format = R11F_G11F_B10F; // TAA

*/

const vec4 colortex1ClearColor = vec4(0,1,0,1);
//const bool colortex3Clear      = false;
const vec4 colortex3ClearColor = vec4(0,0,0,0);
//const bool colortex4Clear      = false;
const vec4 colortex4ClearColor = vec4(.5, .5, .5, 1);
const bool colortex5Clear      = false;

const float sunPathRotation = -35.0;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         REFLECTIONS AND WATER EFFECTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/skyColor.glsl"

uniform sampler2D depthtex1;
uniform sampler2D colortex1;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float near;
uniform float far;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int   isEyeInWater;

struct position { // A struct for holding positions in different spaces
    vec3 screen;
    vec3 clip;
    vec3 view;
    vec3 vdir;
};

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE REFLECTION
//////////////////////////////////////////////////////////////////////////////

vec4 CubemapStyleReflection(position pos, vec3 normal, bool skipSame) {
    vec3 reflection   = reflect(pos.view, normal);
    vec4 screenPos    = backToClipW(reflection) * .5 + .5;

    //return vec4(getSkyColor5_gamma(reflection, rainStrength), 0);
    //return (saturate(screenPos.xy) != screenPos.xy || screenPos.w <= .5 || getDepth(screenPos.xy) == 1) ? vec4(getSkyColor5_gamma(reflection, rainStrength), 0) : vec4(getAlbedo_int(screenPos.xy), 1);
    if (clamp(screenPos.xy, vec2(-.2 * SSR_DEPTH_TOLERANCE, -.025), vec2(.2 * SSR_DEPTH_TOLERANCE + 1., 1.025)) != screenPos.xy || screenPos.w <= .5 || getDepth_int(screenPos.xy) == 1) {
        return vec4(getFogColor_gamma(reflection, rainStrength, isEyeInWater), 0);
    }
    return vec4(getAlbedo_int(screenPos.xy), 1);
}

vec4 universalSSR(position pos, vec3 normal, bool skipSame) {
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return vec4(getFogColor_gamma(viewReflection - pos.view, rainStrength, isEyeInWater), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * screenSize) * 0.2;

    float zDir       = fstep(0, screenSpaceRay.z);                                            // Checks if Reflection is pointing towards the camera in the z-direction (depth)
    float maxZtravel = mix(pos.screen.z - 0.56, 1 - pos.screen.z, zDir);                     // Selects the maximum Z-Distance a ray can travel based on the information
    vec3  rayStep    = screenSpaceRay * clamp(abs(maxZtravel / screenSpaceRay.z), 0.05, 1);  // Scales the vector so that the total Z-Distance corresponds to the maximum possible Z-Distance

    rayStep         /= SSR_STEPS;
    vec3 rayPos      = rayStep * randfac + pos.screen;

    float depthTolerance = (abs(rayStep.z) + .2 * sqmag(rayStep.xy)) * SSR_DEPTH_TOLERANCE * 3;
    float hitDepth       = 0;

    for (int i = 0; i < SSR_STEPS; i++) {

        if ( clamp(rayPos, 0, 1) != rayPos || hitDepth >= 1) {
            break; // Break if out of bounds
        }

        rayPos  += rayStep;
        
        hitDepth = getDepth(rayPos.xy);

        if (rayPos.z > hitDepth && hitDepth < 1 && hitDepth > 0.56 && abs(rayPos.z - hitDepth) < depthTolerance) { // Next: Binary Refinement
            if (getType(pos.screen.xy) == getType(rayPos.xy) && skipSame) {break;}

            #ifdef SSR_NO_REFINEMENT
                return vec4(getAlbedo_int(rayPos.xy), 1);
            #endif

            vec2 hitPos   = rayPos.xy;

            // We now want to refine between "rayPos - rayStep" (Last Step) and "rayPos" (Current Step)
            rayStep      *= 0.5;
            rayPos       -= rayStep; // Go back half a step to start binary search (you start in the middle)

            float condition;
            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                hitDepth  = getDepth(rayPos.xy);
                rayStep  *= .5;

                if (rayPos.z > hitDepth && (rayPos.z - hitDepth) < depthTolerance) {
                    hitPos   = rayPos.xy;
                    rayPos  -= rayStep;
                } else {
                    rayPos  += rayStep;
                }
            }

            return vec4(texture(colortex0, rayPos.xy, 0).rgb, 1);
        }
    }

    return vec4(getFogColor_gamma(viewReflection - pos.view, rainStrength, isEyeInWater), 0);
}

vec4 universalSSR(position pos, vec3 normal, bool skipSame, sampler2D depthSampler) {
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return vec4(getFogColor_gamma(viewReflection - pos.view, rainStrength, isEyeInWater), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * screenSize) * 0.2;

    float zDir       = fstep(0, screenSpaceRay.z);                                            // Checks if Reflection is pointing towards the camera in the z-direction (depth)
    float maxZtravel = mix(pos.screen.z - 0.56, 1 - pos.screen.z, zDir);         // Selects the maximum Z-Distance a ray can travel based on the information
    vec3  rayStep    = screenSpaceRay * clamp(abs(maxZtravel / screenSpaceRay.z), 0.05, 1);  // Scales the vector so that the total Z-Distance corresponds to the maximum possible Z-Distance

    rayStep         /= SSR_STEPS;
    vec3 rayPos      = rayStep * randfac + pos.screen;

    float depthTolerance = (abs(rayStep.z) + .2 * sqmag(rayStep.xy)) * SSR_DEPTH_TOLERANCE * 3;
    float hitDepth       = 0;

    for (int i = 0; i < SSR_STEPS; i++) {

        if ( clamp(rayPos, 0, 1) != rayPos || hitDepth >= 1) {
            break; // Break if out of bounds
        }

        rayPos  += rayStep;
        
        hitDepth = texture(depthSampler, rayPos.xy).x;

        if (rayPos.z > hitDepth && hitDepth < 1 && hitDepth > 0.56 && abs(rayPos.z - hitDepth) < depthTolerance) { // Next: Binary Refinement
            if (getType(pos.screen.xy) == getType(rayPos.xy) && skipSame) {break;}

            #ifdef SSR_NO_REFINEMENT
                return vec4(getAlbedo_int(rayPos.xy), 1);
            #endif

            vec2 hitPos   = rayPos.xy;

            // We now want to refine between "rayPos - rayStep" (Last Step) and "rayPos" (Current Step)
            rayStep      *= 0.5;
            rayPos       -= rayStep; // Go back half a step to start binary search (you start in the middle)

            float condition;
            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                hitDepth  = texture(depthSampler, rayPos.xy).x;
                rayStep  *= .5;

                if (rayPos.z > hitDepth && (rayPos.z - hitDepth) < depthTolerance) {
                    hitPos   = rayPos.xy;
                    rayPos  -= rayStep;
                } else {
                    rayPos  += rayStep;
                }
            }

            return vec4(texture(colortex0, rayPos.xy, 0).rgb, 1);
        }
    }

    return vec4(getFogColor_gamma(viewReflection - pos.view, rainStrength, isEyeInWater), 0);
}

/* vec4 universalSSR(position pos, vec3 normal, float roughness, bool skipSame) {
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return vec4(getFogColor_gamma(viewReflection - pos.view, rainStrength, isEyeInWater), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * screenSize) * 0.2;

    float zDir       = fstep(0, screenSpaceRay.z);                                            // Checks if Reflection is pointing towards the camera in the z-direction (depth)
    float maxZtravel = mix(pos.screen.z - 0.56, 1 - pos.screen.z, zDir);         // Selects the maximum Z-Distance a ray can travel based on the information
    vec3  rayStep    = screenSpaceRay * clamp(abs(maxZtravel / screenSpaceRay.z), 0.05, 1);  // Scales the vector so that the total Z-Distance corresponds to the maximum possible Z-Distance

    rayStep         /= SSR_STEPS;
    vec3 rayPos      = rayStep * randfac + pos.screen;

    float depthTolerance = (abs(rayStep.z) + .2 * sqmag(rayStep.xy)) * SSR_DEPTH_TOLERANCE * 3;
    float hitDepth       = 0;

    for (int i = 0; i < SSR_STEPS; i++) {

        if ( clamp(rayPos, 0, 1) != rayPos || hitDepth >= 1) {
            break; // Break if out of bounds
        }

        rayPos  += rayStep;
        
        hitDepth = getDepth(rayPos.xy);

        if (rayPos.z > hitDepth && hitDepth < 1 && hitDepth > 0.56 && abs(rayPos.z - hitDepth) < depthTolerance) { // Next: Binary Refinement
            if (getType(pos.screen.xy) == getType(rayPos.xy) && skipSame) {break;}

            #ifdef SSR_NO_REFINEMENT
                return vec4(getAlbedo_int(rayPos.xy), 1);
            #endif

            vec2 hitPos   = rayPos.xy;

            // We now want to refine between "rayPos - rayStep" (Last Step) and "rayPos" (Current Step)
            rayStep      *= 0.5;
            rayPos       -= rayStep; // Go back half a step to start binary search (you start in the middle)

            float condition;
            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                hitDepth  = getDepth(rayPos.xy);
                rayStep  *= .5;

                if (rayPos.z > hitDepth && (rayPos.z - hitDepth) < depthTolerance) {
                    hitPos   = rayPos.xy;
                    rayPos  -= rayStep;
                } else {
                    rayPos  += rayStep;
                }
            }

            return vec4(texture(colortex0, rayPos.xy, 0).rgb, 1);
        }
    }

    return vec4(getFogColor_gamma(viewReflection - pos.view, rainStrength, isEyeInWater), 0);
} */

/* DRAWBUFFERS:0 */
void main() {
    #ifndef REFRACTION
     vec3  color                  = getAlbedo(coord);
     float transparentLinearDepth = linearizeDepth(texture(depthtex1, coord).x, near, far);
    #endif

    float depth         = getDepth(coord);
    float linearDepth   = linearizeDepth(depth, near, far);
    vec3  normal        = getNormal(coord);
    float type          = getType(coord);

    vec3  screenPos     = vec3(coord, depth);
    vec3  clipPos       = screenPos * 2 - 1;
    vec3  viewPos       = toView(clipPos);
    vec3  viewDir       = normalize(viewPos);

    position Positions  = position(screenPos, clipPos, viewPos, viewDir);

    //////////////////////////////////////////////////////////
    //                  WATER EFFECTS
    //////////////////////////////////////////////////////////

    #ifdef WATER_EFFECTS

    // Refraction
    // This effect simpy distorts the texcoords for things seen through water
    #ifdef REFRACTION

        vec2 coordDistort = coord;

        // In-Water refraction (distorts texcoords when in water/lava)
        if (isEyeInWater != 0) {
            coordDistort += vec2((noise((coord * 50) + (frameTimeCounter * 3)) - 0.5) * 0.1 * REFRACTION_AMOUNT);
        }

        if (type == 10) {
            coordDistort -= 0.5;

            // Simple Noise (coord is transformed to [-0.5, 0.5] in order to scale effect correctly)
            vec2 noise    = vec2(noise((coord * 3 * linearDepth) + (frameTimeCounter * 2)));
            coordDistort += (noise - 0.5) * (REFRACTION_AMOUNT / linearDepth);

            coordDistort += 0.5;
        }

        vec3  color                  = getAlbedo_int(coordDistort);
              depth                  = getDepth_int(coordDistort);
              linearDepth            = linearizeDepth(depth, near, far);
        float transparentLinearDepth = linearizeDepth(texture(depthtex1, coordDistort).x, near, far);

    #endif

    // Absorption Above Water
    if (type == 10 && isEyeInWater == 0) {
        // Height difference between water surface and ocean floor
        float absorption = exp2(-(transparentLinearDepth - linearDepth) * 0.2);

        color *= absorption;
    }
    

    #ifdef SCREEN_SPACE_REFLECTION

        // SSR for Water
        if (type == 10) {

            /* vec2 n           = N22(fract(coord + frameTimeCounter)) * 2 - 1;
            vec3 roughNormal = normalize(vec3(n * 0.1, 1)) * arbitraryTBN(normal); */

            float fresnel   = customFresnel(viewDir, normal, 0.05, 1, 3);

            #if SSR_MODE == 0
                vec4 Reflection = universalSSR(Positions, normal, false);
            #else
                vec4 Reflection = CubemapStyleReflection(Positions, normal, false);
            #endif

            color           = mix(color, Reflection.rgb, fresnel);

            #ifdef SSR_DEBUG
                color = vec3(fresnel);
            #endif

        }

        //////////////////////////////////////////////////////////
        //                  OTHER REFLECTIVE SURFACES
        //////////////////////////////////////////////////////////

        // Reflections on PBR Materials
        #ifdef PHYSICALLY_BASED

        // SSR for other reflective surfaces
        float reflectiveness = texture(colortex1, coord).r; // Fresnel is included here
        if (reflectiveness > 0.6/255) {

            //reflectiveness = smoothCutoff(reflectiveness, SSR_REFLECTION_THRESHOLD, 0.5);

            #if SSR_MODE == 0
                vec4 Reflection = universalSSR(Positions, normal, false);
            #else
                vec4 Reflection = CubemapStyleReflection(Positions, normal, false);
            #endif

            color              = mix(color, Reflection.rgb, reflectiveness * Reflection.a);

            #ifdef SSR_DEBUG
                color = vec3(1, 0,0);
            #endif
        }

        // Reflections on Glass
        #elif defined GLASS_REFLECTIONS

        if (type == 11) { 

            float fresnel   = customFresnel(viewDir, normal, 0.1, 1, 7);

            #if SSR_MODE == 0
                vec4 Reflection = universalSSR(Positions, normal, false, depthtex1);
            #else
                vec4 Reflection = CubemapStyleReflection(Positions, normal, false);
            #endif

            color           = mix(color, Reflection.rgb, fresnel);

            #ifdef SSR_DEBUG
                color = vec3(fresnel);
            #endif

        }

        #endif
        

    #endif

    // Absorption Underwater
    if (isEyeInWater != 0) {
        // Distance to closest Surface
        float absorption = exp2(linearDepth * -0.1);

        color *= absorption;
        if (isEyeInWater == 2) { // Lava
            color = mix(fogColor, color, absorption * 0.75);
        }
    }

    #endif // WATER_EFFECTS

    //Pass everything forward
    FD0 = vec4(color, 1);
}