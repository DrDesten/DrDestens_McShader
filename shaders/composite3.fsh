#version 130

/*
const int colortex0Format = RGB16F;      // Color
const int colortex1Format = R8;          // Reflectiveness (and in the future other PBR values)
const int colortex2Format = RGB16_SNORM; // Normals

const int colortex3Format = R16F;        // colortex3 = blockId
const int colortex4Format = RGB8;        // colortex4 = bloom

const int colortex5Format = RGBA16;      // TAA

*/

const vec4 colortex1ClearColor = vec4(0,0,0,1);
const bool colortex3Clear      = false;
const bool colortex4Clear      = false;
const bool colortex5Clear      = false;

const float sunPathRotation = -40.0;
const int   noiseTextureResolution = 64;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         REFLECTIONS AND WATER EFFECTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/skyColor.glsl"

uniform sampler2D depthtex1;
uniform sampler2D colortex1;

in vec2 coord;
in vec3 lightVector;

uniform float near;
uniform float far;
uniform float frameTimeCounter;
uniform int   isEyeInWater;

uniform float isInvisibleSmooth;

struct position { // A struct for holding positions in different spaces
    vec3 screen;
    vec3 clip;
    vec3 view;
    vec3 vdir;
};

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE REFLECTION
//////////////////////////////////////////////////////////////////////////////

vec3 cheapSSR1(vec3 viewPos) {
    vec3 horizon = toPlayerEye(viewPos);
    horizon.y    = 0;
    horizon      = playerEyeToFeet(horizon);
    horizon      = backToView(horizon);
    horizon      = backToClip(horizon) * .5 + .5;

    float flipAxis = horizon.y;

    vec2 nc = vec2(coord.x, flipAxis * 2 - coord.y);
    return getAlbedo_int(nc);
}

vec3 cheapSSR2(vec3 viewPos) {
    vec3 horizon = toPlayerEye(viewPos);
    horizon.y   *= -1;
    horizon      = playerEyeToFeet(horizon);
    horizon      = backToView(horizon);
    horizon      = backToClip(horizon) * .5 + .5;

    return getAlbedo_int(horizon.xy);
}

vec4 CubemapStyleReflection(position pos, vec3 normal, bool skipSame) { // "Cubemap style"
    vec3 reflection   = reflect(pos.view, normal);
    vec4 screenPos    = backToClipW(reflection) * .5 + .5;

    //return (saturate(screenPos.xy) != screenPos.xy || screenPos.w <= .5 || getDepth(screenPos.xy) == 1) ? vec4(getSkyColor3(reflection), 0) : vec4(getAlbedo_int(screenPos.xy), 1);
    if (clamp(screenPos.xy, vec2(-.2 * SSR_DEPTH_TOLERANCE, -.025), vec2(.2 * SSR_DEPTH_TOLERANCE + 1., 1.025)) != screenPos.xy || screenPos.w <= .5 || getDepth_int(screenPos.xy) == 1) {
        return vec4(getSkyColor3(reflection), 0);
    }
    return vec4(getAlbedo_int(screenPos.xy), 1);
}

/* vec3 universalSSR(vec3 screenPos, vec3 normal, float roughness, bool skipSame) {
    vec3 clipPos        = screenPos * 2 - 1;
    // Reflect in View Space
    vec3 viewPos        = toView(screenPos * 2 - 1);
    vec3 viewReflection = reflect(normalize(viewPos), normal) + viewPos;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return getSkyColor3(viewReflection - viewPos);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - clipPos);
    
    float randfac    = Bayer4(screenPos.xy * screenSize);

    float zDir       = step(0, screenSpaceRay.z);                                            // Checks if Reflection is pointing towards the camera in the z-direction (depth)
    float maxZtravel = mix(screenPos.z - 0.56, 1 - screenPos.z, zDir);                       // Selects the maximum Z-Distance a ray can travel based on the information
    vec3  rayStep    = screenSpaceRay * clamp(abs(maxZtravel / screenSpaceRay.z), 0.05, 1);  // Scales the vector so that the total Z-Distance corresponds to the maximum possible Z-Distance


    rayStep         /= SSR_STEPS;
    vec3 rayPos      = rayStep * randfac + screenPos;

    float depthTolerance = abs(rayStep.z) * SSR_DEPTH_TOLERANCE * 3;
    float hitDepth       = 0;

    for (int i = 0; i < SSR_STEPS; i++) {

        if ( rayPos.x < 0 || rayPos.y < 0 || rayPos.x > 1 || rayPos.y > 1 || rayPos.z < 0 || hitDepth == 1) {
            break; // Break if out of bounds
        }

        rayPos  += rayStep;
        
        hitDepth = getDepth_int(rayPos.xy);

        if (rayPos.z > hitDepth && hitDepth != 1 && hitDepth > 0.56 && abs(rayPos.z - hitDepth) < depthTolerance) { // Next: Binary Refinement
            if (getType(screenPos.xy) == getType(rayPos.xy) && skipSame) {break;}

            #ifdef SSR_NO_REFINEMENT
                return getAlbedo(rayPos.xy);
            #endif

            // We now want to refine between "rayPos - rayStep" (Last Step) and "rayPos" (Current Step)
            rayStep      *= 0.5;
            rayPos       -= rayStep; // Go back half a step to start binary search (you start in the middle)

            float condition;
            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                hitDepth  = getDepth(rayPos.xy);

                // Branchless version of: If hit, go back half a step, else go forward half a step
                condition = float(rayPos.z > hitDepth && (rayPos.z - hitDepth) < depthTolerance); // 1 if true, 0 if false
                rayPos   -= rayStep * (condition - 0.5);

                rayStep  *= 0.5;
            }

            if ((rayPos.z - hitDepth) < depthTolerance) {
                return textureLod(colortex0, rayPos.xy, roughness * 10).rgb;
            } else {
                break;
            }
        }
    }

    return vec3(getSkyColor3(viewReflection - viewPos));
} */
/* vec4 universalSSR(position pos, vec3 normal, bool skipSame) {
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an to me unknown reason) happens when vieReflection.z is positive
        return vec4(getSkyColor3(viewReflection - pos.view), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * screenSize);

    float zDir       = step(0, screenSpaceRay.z);                                            // Checks if Reflection is pointing towards the camera in the z-direction (depth)
    float maxZtravel = mix(pos.screen.z - 0.56, 1 - pos.screen.z, zDir);         // Selects the maximum Z-Distance a ray can travel based on the information
    vec3  rayStep    = screenSpaceRay * clamp(abs(maxZtravel / screenSpaceRay.z), 0.05, 1);  // Scales the vector so that the total Z-Distance corresponds to the maximum possible Z-Distance

    rayStep         /= SSR_STEPS;
    vec3 rayPos      = rayStep * randfac + pos.screen;

    float depthTolerance = length(rayStep * vec3(0.2, 0.2, 1)) * SSR_DEPTH_TOLERANCE * 3;
    float hitDepth       = 0;

    for (int i = 0; i < SSR_STEPS; i++) {

        if (clamp(rayPos, 0, 1) != rayPos) {
            break; // Break if out of bounds
        }

        rayPos  += rayStep;
        
        hitDepth = getDepth_int(rayPos.xy);

        if (rayPos.z > hitDepth && hitDepth != 1 && hitDepth > 0.56 && abs(rayPos.z - hitDepth) < depthTolerance) { // Next: Binary Refinement
            if (getType(pos.screen.xy) == getType(rayPos.xy) && skipSame) {break;}

            #ifdef SSR_NO_REFINEMENT
                return vec4(getAlbedo(rayPos.xy), 1);
            #endif

            // We now want to refine between "rayPos - rayStep" (Last Step) and "rayPos" (Current Step)
            rayStep      *= 0.5;
            rayPos       -= rayStep; // Go back half a step to start binary search (you start in the middle)

            float condition;
            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                hitDepth  = getDepth(rayPos.xy);

                // Branchless version of: If hit, go back half a step, else go forward half a step
                condition = float(rayPos.z > hitDepth && (rayPos.z - hitDepth) < depthTolerance); // 1 if true, 0 if false
                rayPos   -= rayStep * (condition - 0.5);

                rayStep  *= 0.5;
            }

            if ((rayPos.z - hitDepth) < depthTolerance) {
                return vec4(getAlbedo(rayPos.xy), 1);
            } else {
                return vec4(getSkyColor3(viewReflection - pos.view), 0);
            }
        }
    }

    return vec4(getSkyColor3(viewReflection - pos.view), 0);
} */
/* vec4 universalSSR(position pos, vec3 normal, bool skipSame) {
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return vec4(getSkyColor3(viewReflection - pos.view), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * screenSize);

    float zDir       = step(0, screenSpaceRay.z);                                            // Checks if Reflection is pointing towards the camera in the z-direction (depth)
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

            // We now want to refine between "rayPos - rayStep" (Last Step) and "rayPos" (Current Step)
            rayStep      *= 0.5;
            rayPos       -= rayStep; // Go back half a step to start binary search (you start in the middle)

            float condition;
            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                hitDepth  = getDepth(rayPos.xy);

                // Branchless version of: If hit, go back half a step, else go forward half a step
                condition = float(rayPos.z > hitDepth && (rayPos.z - hitDepth) < depthTolerance); // 1 if true, 0 if false
                rayPos   -= rayStep * (condition - 0.5);

                rayStep  *= 0.5;
            }

            if ((rayPos.z - hitDepth) < depthTolerance) {
                return vec4(texture(colortex0, rayPos.xy).rgb, 1);
            } else {
                break;
            }
        }
    }

    return vec4(getSkyColor3(viewReflection - pos.view), 0);
} */
vec4 universalSSR(position pos, vec3 normal, bool skipSame) {
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return vec4(getSkyColor3(viewReflection - pos.view), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * screenSize) * 0.25;

    float zDir       = step(0, screenSpaceRay.z);                                            // Checks if Reflection is pointing towards the camera in the z-direction (depth)
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

    return vec4(getSkyColor3(viewReflection - pos.view), 0);
}


/* DRAWBUFFERS:0 */
void main() {
    vec3  color         = getAlbedo(coord);
    vec3  normal        = getNormal(coord);
    float depth         = getDepth(coord);
    float linearDepth   = linearizeDepth(depth, near, far);
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

        if (type == 1) {
            coordDistort -= 0.5;

            // Simple Noise (coord is transformed to [-0.5, 0.5] in order to scale effect correctly)
            vec2 noise    = vec2(noise((coord * 3 * linearDepth) + (frameTimeCounter * 2)));
            coordDistort += (noise - 0.5) * (REFRACTION_AMOUNT / linearDepth);

            coordDistort += 0.5;
        }

        color         = getAlbedo_int(coordDistort);
        depth         = getDepth_int(coordDistort);
        linearDepth   = linearizeDepth(depth, near, far);

    #endif

    // Absorption Above Water
    if (type == 1 && isEyeInWater == 0) {
        #ifdef REFRACTION
            float transparentLinearDepth = linearizeDepth(texture(depthtex1, coordDistort).x, near, far);
        #else
            float transparentLinearDepth = linearizeDepth(texture(depthtex1, screenPos.xy).x, near, far);
        #endif

        // Height difference between water surface and ocean floor
        float absorption = exp2(-(transparentLinearDepth - linearDepth) * 0.2);

        color *= absorption;
    }
    

    #ifdef SCREEN_SPACE_REFLECTION

        // SSR for Water
        if (type == 1 && isEyeInWater != -1) {

            float fresnel   = customFresnel(viewDir, normal, 0.03, .7, 2);

            #if SSR_MODE == 0
                vec4 Reflection = universalSSR(Positions, normal, false);
            #else
                vec4 Reflection = CubemapStyleReflection(Positions, normal, false);
            #endif

            color           = mix(color, Reflection.rgb * 0.95, fresnel);

            #ifdef SSR_DEBUG
                color = vec3(fresnel);
            #endif

        }

        //////////////////////////////////////////////////////////
        //                  OTHER REFLECTIVE SURFACES
        //////////////////////////////////////////////////////////

        // SSR for other reflective surfaces
        float reflectiveness = texture(colortex1, coord).r; // Fresnel is included here
        if (reflectiveness > 5./255) {

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

    #endif

    // Absorption Underwater
    if (isEyeInWater != 0) {
        #ifdef REFRACTION
            float transparentLinearDepth = linearizeDepth(texture(depthtex1, coordDistort).x, near, far);
        #else
            float transparentLinearDepth = linearizeDepth(texture(depthtex1, screenPos.xy).x, near, far);
        #endif

        // Distance to closest Surface
        float absorption = exp2(-(linearDepth) * 0.2);

        color *= absorption;
        if (isEyeInWater == 2) { // Lava
            color = mix(fogColor, color, absorption * 0.75);
        }
    }

    #endif // WATER_EFFECTS

    

    //color = normal * .5 + .5;

    //Pass everything forward
    FD0 = vec4(color, 1);
}