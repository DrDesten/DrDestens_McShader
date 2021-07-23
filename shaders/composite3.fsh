#version 130

/*
const int colortex0Format = RGB16F;      // Color
const int colortex1Format = R8           // Reflectiveness
const int colortex2Format = RGB16_SNORM; // Normals

const int colortex3Format = R16F;        // colortex3 = blockId
const int colortex4Format = RGB16F;      // colortex4 = bloom

const vec4 colortex1ClearColor = vec4(0,0,0,1);
*/

const float sunPathRotation = -40.0;

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

/*
vec3 testSSR(vec2 coord, vec3 normal, vec3 screenPos, vec3 clipPos, vec3 viewPos, vec3 viewDir, float surfaceType) {    
    // Reflect view Ray along normals of surface
    vec3 reflectionRay = reflect(viewDir, normal);
    vec3 viewSpaceReflection = viewPos + reflectionRay;

    // Project ray into screen space
    vec4 screenSpaceRayTemp = gbufferProjection * vec4(viewSpaceReflection, 1);
    vec3 screenSpaceRayDirection = normalize(screenSpaceRayTemp.xyz / screenSpaceRayTemp.w - clipPos);

    vec3 rayPos = screenPos;

    // Define the step Size for the ray:
    // The multiplication scales the step so that its z-length is not longer than the remaining space in the z-direction
    // "(1-rayPos.z) / screenSpaceRayDirection.z"  is the factor with whom screenSpaceRayDirection has to be changed.
    // In order to avoid errors when looking straight down, the value is clamped to a minimum value.
    #ifdef SSR_STEP_OPTIMIZATION
        vec3 rayStep = screenSpaceRayDirection * max((1-rayPos.z) / screenSpaceRayDirection.z, 0.05); //Optimized stepsize
    #else
        vec3 rayStep = screenSpaceRayDirection;
    #endif
    rayStep /= SSR_STEPS;

    //return screenSpaceRayDirection;

    float randfac = pattern_cross2(coord, 1, viewWidth, viewHeight) * 0.25;
    rayPos -= rayStep * randfac;

    float appliedDepthTolerance = rayStep.z * SSR_DEPTH_TOLERANCE;
    float hitDepth;

    //////////////////////////////////////////////////////////////////
    //                  Screen Space Raytrace Loop
    //////////////////////////////////////////////////////////////////


    for (int i = 0; i < SSR_STEPS; i++) {

        if ( rayPos.x < 0 || rayPos.y < 0 || rayPos.x > 1 || rayPos.y > 1) {
            break;
        }

        rayPos += rayStep;
        
        float hitDepth = getDepth(rayPos.xy);

        if (rayPos.z >= hitDepth && hitDepth > 0.5) {
            // Check if reflection hits water
            if (getType(rayPos.xy) == surfaceType) {
                #ifdef DEBUG_SSR_ERROR_CORRECTION
                    return vec3(0,1,0);
                #endif
                return cheapSSR_final(rayPos.xy, normal, getSkyColor3(reflectionRay), 1, 0.2, 8);
            } 

            // After having found an intersection, refine Reflection

            // Move the position back by half a step
            rayPos -= rayStep;
            // Define new (smaller) Stepsize
            rayStep /= SSR_FINE_STEPS;

            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                //return getAlbedo(rayPos.xy);

                rayPos += rayStep;
                
                if (getType(rayPos.xy) == surfaceType) {
                    break;
                }
                
                hitDepth = getDepth(rayPos.xy);
                
                if (rayPos.z > hitDepth && rayPos.z - appliedDepthTolerance < hitDepth && hitDepth > 0.5) {
                    // Raytrace hit found
                    
                    // Calculate Distance to edge
                    float edgeFade = min(min(rayPos.x, rayPos.y), 1 - max(rayPos.x, rayPos.y));
                    edgeFade = clamp(edgeFade * 25, 0, 1);
                    
                    return mix(getSkyColor3(reflectionRay), getAlbedo_int(rayPos.xy), edgeFade);
                }
            }
        }
    }

    return getSkyColor3(reflectionRay);
}

vec4 testSSR_opt(vec2 coord, vec3 normal, vec3 screenPos, vec3 clipPos, vec3 viewPos, vec3 viewDir, float surfaceType) {    
    // Reflect view Ray along normals of surface
    vec3 reflectionRay = reflect(viewDir, normal);
    vec3 viewSpaceReflection = viewPos + reflectionRay;

    // Project ray into screen space
    vec4 screenSpaceRayTemp = gbufferProjection * vec4(viewSpaceReflection, 1);
    vec3 screenSpaceRayDirection = normalize(screenSpaceRayTemp.xyz / screenSpaceRayTemp.w - clipPos);

    vec3 rayPos = screenPos;

    // I need randfac earlier on for the stepsize scaling
    float randfac = Bayer4(coord * ScreenSize) * 0.5;

    // Define the step Size for the ray:
    // The multiplication scales the step so that its z-length is not longer than the remaining space in the z-direction
    // "(1-rayPos.z) / screenSpaceRayDirection.z"  is the factor with whom screenSpaceRayDirection has to be changed.
    // In order to avoid errors when looking straight down, the value is clamped to a minimum value.
    #ifdef SSR_STEP_OPTIMIZATION
        vec3 rayStep = screenSpaceRayDirection * max((1-rayPos.z) / screenSpaceRayDirection.z, 0.05); //Optimized stepsize
    #else
        vec3 rayStep = screenSpaceRayDirection;
    #endif
    rayStep /= SSR_STEPS;

    //return screenSpaceRayDirection;

    rayPos -= rayStep * randfac;

    float appliedDepthTolerance = abs(rayStep.z) * SSR_DEPTH_TOLERANCE;
    float hitDepth;

    //////////////////////////////////////////////////////////////////
    //                  Screen Space Raytrace Loop
    //////////////////////////////////////////////////////////////////


    for (int i = 0; i < SSR_STEPS; i++) {

        if ( rayPos.x < 0 || rayPos.y < 0 || rayPos.x > 1 || rayPos.y > 1 || rayPos.z < 0 || rayPos.z > 1 - rayStep.z) {
            break;
        }

        rayPos += rayStep;
        
        float hitDepth = getDepth(rayPos.xy);

        if (rayPos.z >= hitDepth && hitDepth > 0.5) {
            // Check if reflection hits water
            if (getType(rayPos.xy) == surfaceType) {
                #ifdef DEBUG_SSR_ERROR_CORRECTION
                    return vec3(0,1,0,0);
                #endif
                return vec4(cheapSSR_final(rayPos.xy, normal, getSkyColor3(reflectionRay), 1, 0.2, 8), 1);
            } 

            // After having found an intersection, refine Reflection

            // Move the position back by half a step
            rayPos -= rayStep;
            // Define new (smaller) Stepsize
            rayStep /= SSR_FINE_STEPS;

            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                //return getAlbedo(rayPos.xy);

                rayPos += rayStep;
                
                if (getType(rayPos.xy) == surfaceType) {
                    break;
                }
                
                hitDepth = getDepth(rayPos.xy);
                
                if (rayPos.z > hitDepth && rayPos.z - appliedDepthTolerance < hitDepth && hitDepth > 0.5) {
                    // Raytrace hit found
                    
                    // Calculate Distance to edge
                    float edgeFade = min(min(rayPos.x, rayPos.y), 1 - max(rayPos.x, rayPos.y));
                    edgeFade = clamp(edgeFade * 25, 0, 1);
                    
                    return vec4(mix(getSkyColor3(reflectionRay), getAlbedo_int(rayPos.xy), edgeFade), 0);
                }
            }
        }
    }

    return vec4(getSkyColor3(reflectionRay), 1);
}
*/

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
    
    float randfac    = Bayer4(screenPos.xy * ScreenSize);

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
    
    float randfac    = Bayer4(pos.screen.xy * ScreenSize);

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
vec4 universalSSR(position pos, vec3 normal, bool skipSame) {
    // Reflect in View Space
    vec3 viewReflection = reflect(pos.vdir, normal) + pos.view;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return vec4(getSkyColor3(viewReflection - pos.view), 0);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - pos.clip);
    
    float randfac    = Bayer4(pos.screen.xy * ScreenSize);

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
}

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////

float AmbientOcclusionLOW(position pos, vec3 normal, float size) {
    vec3 tangent           = normalize(cross(normal, vec3(0,0,1)));              //Simply Creating A orthogonal vector to the normals, actual tangent doesnt really matter
    mat3 TBN               = mat3(tangent, cross(tangent, normal), normal);

    float ditherTimesSize  = (Bayer4(pos.screen.xy * ScreenSize) * 0.8 + 0.2) * size;
    float depthTolerance   = 0.075/-pos.view.z;

    float hits = 0;
    vec3 sample;
    for (int i = 0; i < 8; i++) {
        sample      = half_sphere_8[i] * ditherTimesSize; 
        sample.z   += 0.05;                                                       // Adding a small (5cm) z-offset to avoid clipping into the block due to precision errors
        sample      = TBN * sample;
        sample      = backToClip(sample + pos.view) * 0.5 + 0.5;                  // Converting Sample to screen space, since normals are in view space
    
        float hitDepth = getDepth(sample.xy);

        hits += float(sample.z > hitDepth && (sample.z - hitDepth) < depthTolerance || sample.z < .8);
    }

    hits  = 1 - (hits / 8);
    return sq(hits);
}

float AmbientOcclusionHIGH(position pos, vec3 normal, float size) {
    vec3 tangent           = normalize(cross(normal, vec3(0,0,1)));              //Simply Creating A orthogonal vector to the normals, actual tangent doesnt really matter
    mat3 TBN               = mat3(tangent, cross(tangent, normal), normal);

    float ditherTimesSize  = (Bayer4(pos.screen.xy * ScreenSize) * 0.8 + 0.2) * size;
    float depthTolerance   = 0.075/-pos.view.z;

    float hits = 0;
    vec3 sample;
    for (int i = 0; i < 16; i++) {
        sample      = half_sphere_16[i] * ditherTimesSize; 
        sample.z   += 0.05;                                                      // Adding a small (5cm) z-offset to avoid clipping into the block due to precision errors
        sample      = TBN * sample;
        sample      = backToClip(sample + pos.view) * 0.5 + 0.5;                  // Converting Sample to screen space, since normals are in view space
    
        float hitDepth = getDepth(sample.xy);

        hits += float(sample.z > hitDepth && (sample.z - hitDepth) < depthTolerance);
    }

    hits  = 1 - (hits / 16);
    return sq(hits);
}

/* DRAWBUFFERS:03 */
void main() {
    vec3  color         = getAlbedo(coord);
    vec3  normal        = getNormal(coord);
    float depth         = getDepth(coord);
    float linearDepth   = linearizeDepth(depth, near, far);
    float type          = getType(coord);

    float denoise       = 0;

    vec3  screenPos     = vec3(coord, depth);
    vec3  clipPos       = screenPos * 2 - 1;
    vec3  viewPos       = toView(clipPos);
    vec3  viewDir       = normalize(viewPos);

    #ifdef PIXELIZE
        vec3 worldPos   = toWorld(toPlayer(viewPos));
        worldPos        = floor(worldPos * PIXELIZE_SIZE) / PIXELIZE_SIZE;

        viewPos         = backToView(backToPlayer(worldPos));
        viewDir         = normalize(viewPos);
        clipPos         = backToClip(viewPos);
        screenPos       = clipPos * .5 + .5;

        normal          = getNormal(screenPos.xy);
    #endif

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

            vec4 Reflection = universalSSR(Positions, normal, false);
            color           = mix(color, Reflection.rgb * 0.95, fresnel);
            denoise         = 1;

            #ifdef SSR_DEBUG
                color = vec3(fresnel);
            #endif

        }

        //////////////////////////////////////////////////////////
        //                  OTHER REFLECTIVE SURFACES
        //////////////////////////////////////////////////////////

        // SSR for other reflective surfaces
        float reflectiveness = texture(colortex1, coord).r; // Fresnel is included here
        if (reflectiveness > 12.75/255) { // 12.75/255 represents 5% reflectiveness, lower is practically invisible

            vec4  Reflection   = universalSSR(Positions, normal, false);
            denoise            = 1;

            #ifdef PBR_REFLECTION_REALISM
            if (reflectiveness > 254.5/255) {
                color          = mix(color, Reflection.rgb, Reflection.a * sum(color * .333));
                //color          = mix(color, color * Reflection.rgb, Reflection.a);
            } else {
                color          = mix(color, Reflection.rgb, reflectiveness * Reflection.a);
            }
            #else
            color              = mix(color, Reflection.rgb, reflectiveness * Reflection.a);
            #endif

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

    //////////////////////////////////////////////////////////
    //                  SSAO
    //////////////////////////////////////////////////////////

    #ifdef SCREEN_SPACE_AMBIENT_OCCLUSION

        if (abs(type - 50) > .2 && type != 1 && depth != 1) {

            #if   SSAO_QUALITY == 1
                color *= AmbientOcclusionLOW(Positions, normal, .5) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);
            #elif SSAO_QUALITY == 2
                color *= AmbientOcclusionHIGH(Positions, normal, .5) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);
            #endif
            
        }

    #endif

    //color = normal * .5 + .5;


    // Create some atmosphere
    //color *= (fogColor * 0.5 + 0.5);

    //Pass everything forward
    FD0          = vec4(color, 1);
    
    // If there is some thing to be denoised, override the type buffer to "3", the denoise pass.
    if (denoise != 0) { FD1 = vec4(3, 0, 0, 1); } 
    else              { FD1 = vec4(getType(coord), 0, 0, 1); }
}