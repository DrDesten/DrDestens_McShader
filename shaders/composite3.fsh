#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         REFLECTIONS AND WATER EFFECTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/skyColor.glsl"


#define SSR_STEPS 32                    // Screen Space Reflection Steps                [4 6 8 12 16 32 48 64]
#define SSR_DEPTH_TOLERANCE 1.0         // Modifier to the thickness estimation         [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0]
#define SSR_DISTANCE 1.0                // How far reflections go                       [0.5 0.6 0.7 0.8 0.9 1.0]
#define SSR_FINE_STEPS 3
#define SSR_STEP_OPTIMIZATION
//#define SSR_CHEAP
//#define DEBUG_SSR_ERROR_CORRECTION


//#define SSAO_TWO_PASS
#define SSAO_RANDOMIZE_AMOUNT 1

#define REFRACTION
#define REFRACTION_AMOUNT 0.03          // Refraction Strength                          [0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]

uniform sampler2D depthtex1;
const bool        colortex0MipmapEnabled = true; //Enabling Mipmapping

in vec2 coord;
in vec2 pixelSize;
in vec3 lightVector;

uniform float near;
uniform float far;
uniform float frameTimeCounter;
uniform int isEyeInWater;


//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE REFLECTION
//////////////////////////////////////////////////////////////////////////////

vec3 cheapSSR(vec2 coord, vec3 normal, vec3 fallBackColor, int steps, float stepsize) {
    vec2 pixelPos = coord;
    float depth = getDepth(coord);

    vec2 pixelStep = normalize(normal.xy) * pixelSize * stepsize;

    for (int i = 0; i < steps; i++) {
        pixelPos += pixelStep;

        if (clamp(pixelPos, 0, 1) != pixelPos) {
            break;
        }

        // Check if out of water
        if (getType(pixelPos) != 1) {
            vec2 reflectPos = pixelPos + (pixelPos - coord);
            float hitdepth = getDepth(reflectPos);

            if (clamp(reflectPos, 0, 1) != reflectPos || getType(reflectPos) == 1 || hitdepth >= 1 || hitdepth < depth) {
                break;
            }

            return getAlbedo(reflectPos);
        }
    }

    return fallBackColor;
}

vec3 cheapSSR_final(vec2 coord, vec3 normal, vec3 fallBackColor, float surfaceType, float dist, int steps) {
    vec2 pixelPos = coord;
    float depth = linearizeDepth(getDepth(coord), near, far);

    vec2 marchDirection = normalize(normal.xy);

    // Border position ( for binary search )
    vec2 increment = marchDirection * dist;

    vec2 b1 = pixelPos + (randf_01(coord) * increment * 0.0075);
    vec2 b2 = clamp(increment + pixelPos, 0, 1);

    vec2 sampleCoord;
    float sampleDepth;

    for (int i = 0; i < steps; i++) {
        sampleCoord = midpoint(b1, b2);
        sampleDepth = getDepth(sampleCoord);

        if (getType(sampleCoord) != surfaceType && linearizeDepth(sampleDepth, near, far) + 5 > depth) {
            //Hit
            b2 = sampleCoord;
        } else {
            //No Hit
            b1 = sampleCoord;
        }
    }
    if (getType_interpolated(sampleCoord) != surfaceType) {
        vec2 reflectPos = sampleCoord + (sampleCoord - coord);
        sampleDepth = getDepth(reflectPos);

        if (clamp(reflectPos, 0, 1) != reflectPos || getType(reflectPos) == surfaceType || sampleDepth == 1.0) {
            return fallBackColor;
        }

        return getAlbedo(reflectPos);
    }

    return fallBackColor;
}


/* vec3 testSSR(vec2 coord, vec3 normal, vec3 screenPos, vec3 clipPos, vec3 viewPos, vec3 viewDirection, float surfaceType) {    
    // Reflect view Ray along normals of surface
    vec3 reflectionRay = reflect(viewDirection, normal);
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
    rayStep *= SSR_DISTANCE;

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

vec4 testSSR_opt(vec2 coord, vec3 normal, vec3 screenPos, vec3 clipPos, vec3 viewPos, vec3 viewDirection, float surfaceType) {    
    // Reflect view Ray along normals of surface
    vec3 reflectionRay = reflect(viewDirection, normal);
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
    rayStep *= SSR_DISTANCE;

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
} */

vec3 universalSSR(vec2 coord, vec3 normal, vec3 screenPos, float roughness, bool skipSame) {
    vec3 clipPos        = screenPos * 2 - 1;
    // Reflect in View Space
    vec3 viewPos        = toView(screenPos * 2 - 1);
    vec3 viewReflection = reflect(normalize(viewPos), normal) + viewPos;

    if (viewReflection.z > 0) { // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
        return getSkyColor3(viewReflection - viewPos);
    }

    // Project to Screen Space
    vec3 screenSpaceRay = normalize(backToClip(viewReflection) - clipPos);
    
    float randfac    = Bayer4(coord * ScreenSize) * 0.5;

    float zDir       = step(0, screenSpaceRay.z);                                      // Checks if Reflection is pointing towards the camera in the z-direction (depth)
    float maxZtravel = mix(screenPos.z - 0.56, 1 - screenPos.z, zDir);                        // Selects the maximum Z-Distance a ray can travel based on the information
    vec3 rayStep     = screenSpaceRay * clamp(maxZtravel / screenSpaceRay.z, 0.05, 1); // Scales the vector so that the total Z-Distance corresponds to the maximum possible Z-Distance

    rayStep         *= SSR_DISTANCE / SSR_STEPS;
    vec3 rayPos      = rayStep * randfac + screenPos;

    float depthTolerance = abs(rayStep.z) * SSR_DEPTH_TOLERANCE * 2.5;
    float hitDepth       = 0;

    for (int i = 0; i < SSR_STEPS; i++) {

        if ( rayPos.x < 0 || rayPos.y < 0 || rayPos.x > 1 || rayPos.y > 1 || rayPos.z < 0 || hitDepth == 1) {
            break; // Break if out of bounds
        }

        rayPos  += rayStep;
        
        hitDepth = getDepth_int(rayPos.xy);

        if (rayPos.z > hitDepth && hitDepth != 1 && hitDepth > 0.56) { // Next: Binary Refinement
            if (getType(screenPos.xy) == getType(rayPos.xy) && skipSame) {break;}

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
                //float rayLength = log2(length(toView(rayPos * 2 -1) - viewPos));
                return textureLod(colortex0, rayPos.xy, roughness * 10).rgb;
            } else {
                break;
            }
        }
    }

    return vec3(getSkyColor3(viewReflection - viewPos));
}


//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////




/* DRAWBUFFERS:04 */
void main() {
    vec3 color;
    vec3 normal;
    float depth;
    float linearDepth   = linearizeDepth(getDepth(coord), near, far);
    float type          = getType(coord);

    float denoise       = 0;

    //////////////////////////////////////////////////////////
    //                  WATER EFFECTS
    //////////////////////////////////////////////////////////

    // Refraction
    // This effect simpy distorts the texcoords for things seen through water
    #ifdef REFRACTION

        vec2 coordDistort = coord;

        // In-Water refraction (distorts texcoords when in water)
        if (isEyeInWater != 0) {
            coordDistort += vec2((noise((coord * 50) + (frameTimeCounter * 3)) - 0.5) * 0.1 * REFRACTION_AMOUNT);
        }

        if (type == 1) {
            normal        = getNormal(coord);
            coordDistort -= 0.5;

            // Simple Noise (coord is transformed to [-0.5, 0.5] in order to scale effect correctly)
            vec2 noise    = vec2(noise((coord * 3 * linearDepth) + (frameTimeCounter * 2)));
            coordDistort += ((noise - 0.5) * REFRACTION_AMOUNT / linearDepth);

            coordDistort += 0.5;

            color   = getAlbedo_int(coordDistort);

        } else {

            normal  = getNormal(coord);
            color   = getAlbedo_int(coordDistort);
        }

    #else
        
            color   = getAlbedo(coord);
            normal  = getNormal(coord);

    #endif


    // Absorption
    if (type == 1 || isEyeInWater != 0) {
        #ifdef REFRACTION
            // Adjust the depth coordinates to the distorted coordinates from the refraction effect
            float transparentLinearDepth = linearizeDepth(texture(depthtex1, coordDistort).x, near, far);
            linearDepth = linearizeDepth(getDepth(coordDistort), near, far);
        #else
            float transparentLinearDepth = linearizeDepth(texture(depthtex1, coord).x, near, far);
        #endif

        float water_absorption     = max(1, transparentLinearDepth - linearDepth) * int(isEyeInWater == 0);
        water_absorption          += linearDepth                                  * int(isEyeInWater != 0);
        water_absorption           = 5 / water_absorption;
        water_absorption           = clamp(water_absorption, 0, 1);

        color *= water_absorption;
    }

    // SSR for Water
    if (type == 1 && isEyeInWater == 0) {
        depth     = getDepth(coord);

        // Calculate the view Position for the upcoming SSR
        vec3 screenPos = vec3(coord, depth);
        vec3 clipPos = screenPos * 2.0 - 1.0;
        vec4 tmp = gbufferProjectionInverse * vec4(clipPos, 1.0);
        vec3 viewPos = tmp.xyz / tmp.w;
        vec3 viewDirection = normalize(viewPos);

        float fresnel = customFresnel(viewDirection, normal, 0.02, 2, 3);

        #ifdef SSR_CHEAP

            vec3 sky = getSkyColor3(reflect(viewPos, normal));
            color = mix(color, cheapSSR_final(coord, normal, sky, 1, SSR_DISTANCE, SSR_STEPS), fresnel);

        #else

            vec3 SSR = universalSSR(coord, normal, screenPos, 0.0, false);
            color    = mix(color, SSR.rgb * 0.95, fresnel);
            denoise  = 1;


        #endif
    }

    //////////////////////////////////////////////////////////
    //                  OTHER REFLECTIVE SURFACES
    //////////////////////////////////////////////////////////

    // SSR for other reflective surfaces
    if (type == 2) {
        depth     = getDepth(coord);

        // Calculate the view Position for the upcoming SSR
        vec3 screenPos     = vec3(coord, depth);
        vec3 viewDirection = normalize(toView(screenPos * 2 -1));

        float fresnel      = customFresnel(viewDirection, normal, 0.25, 1, 4);
        vec3  SSR          = universalSSR(coord, normal, screenPos, 0.2, false);

        color   = mix(color, SSR, fresnel);
        denoise = 1;
    }

    //color = textureLod(depthtex0, floor(coord * 100) * 0.01, 5).rrr;
    //color = vec3(Bayer16(coord * ScreenSize));


    //Pass everything forward
    FD0          = vec4(color, 1);

    // If there is some thing to be denoised, override the type buffer to "3", the denoise pass.
    if (denoise != 0) { FD1 = vec4(3, 0, 0, 1); } 
    else              { FD1 = vec4(getType(coord), 0, 0, 1); }
}