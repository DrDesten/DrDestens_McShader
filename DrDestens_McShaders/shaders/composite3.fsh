#version 130

#include "/lib/framebuffer.glsl"
#include "/lib/skyColor.glsl"


#define SSR_STEPS 64                    // Screen Space Reflection Steps                [4 6 8 12 16 32 48 64 80 96 112 128 144 160 176 192 208 224 240 256]
#define SSR_DEPTH_TOLERANCE 1.0         // Modifier to the thickness estimation         [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0]
#define SSR_DISTANCE 0.9                // How far reflections go                       [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define SSR_FINE_STEPS 4

//#define SSR_CHEAP

//#define SSAO_TWO_PASS
#define SSAO_RANDOMIZE_AMOUNT 1


uniform sampler2D depthtex2;

varying vec2 coord;
varying vec2 pixelSize;
varying vec3 lightVector;

#ifdef SSR_CHEAP
#else

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

#endif

uniform float near;
uniform float far;


const vec2 SSAO_kernel_low_polar[8] = vec2[8](
    vec2(0.25, 0),
    vec2(0.43301270189221924, 2.399963229728653),
    vec2(0.5590169943749475, 4.799926459457306),
    vec2(0.6614378277661476, 7.199889689185959),
    vec2(0.7499999999999999, 9.599852918914612),
    vec2(0.82915619758885, 11.999816148643266),
    vec2(0.9013878188659972, 14.399779378371917),
    vec2(0.9682458365518541, 16.799742608100573)
);

const vec2 SSAO_kernel_high_polar[16] = vec2[16](
    vec2(0.1767766952966369, 0),
    vec2(0.30618621784789724, 2.399963229728653),
    vec2(0.39528470752104744, 4.799926459457306),
    vec2(0.46770717334674267, 7.199889689185959),
    vec2(0.5303300858899106, 9.599852918914612),
    vec2(0.5863019699779287, 11.999816148643266),
    vec2(0.6373774391990981, 14.399779378371917),
    vec2(0.6846531968814576, 16.799742608100573),
    vec2(0.7288689868556626, 19.199705837829224),
    vec2(0.770551750371122, 21.599669067557876),
    vec2(0.8100925873009825, 23.99963229728653),
    vec2(0.8477912478906585, 26.399595527015183),
    vec2(0.8838834764831844, 28.799558756743835),
    vec2(0.9185586535436918, 31.19952198647249),
    vec2(0.9519716382329886, 33.599485216201145),
    vec2(0.9842509842514764, 35.999448445929794)
);

const vec2 SSAO_kernel_high[16] = vec2[16](
    vec2(0.1767766952966369, 0),
    vec2(-0.225772187937548, 0.20682581839289915),
    vec2(0.03455805202455909, -0.39377117852919086),
    vec2(0.28457121982273553, 0.37117276415249045),
    vec2(-0.5222231872442845, -0.09237392870513249),
    vec2(0.4946953915278165, -0.3146847145972304),
    vec2(-0.16546592706317265, 0.6155250011016001),
    vec2(-0.31556146793512924, -0.6075944041501916),
    vec2(0.6846421615837076, 0.25003021933756037),
    vec2(-0.7122560862297537, 0.294008958415681),
    vec2(0.34335449874552143, -0.7337286202617503),
    vec2(0.2537302409112575, 0.8089319902483244),
    vec2(-0.7647458919689066, -0.4431858760347418),
    vec2(0.897133983572641, -0.19723238962980807),
    vec2(-0.5475069048541611, 0.7787722318733614),
    vec2(-0.12648677292149527, -0.9760896968393356)
);

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
        if (getType(pixelPos) != vec3(0,0,1)) {
            vec2 reflectPos = pixelPos + (pixelPos - coord);
            float hitdepth = getDepth(reflectPos);

            if (clamp(reflectPos, 0, 1) != reflectPos || getType(reflectPos) == vec3(0,0,1) || hitdepth >= 1 || hitdepth < depth) {
                break;
            }

            return getAlbedo(reflectPos);
        }
    }

    return fallBackColor;
}

vec3 cheapSSR_final(vec2 coord, vec3 normal, vec3 fallBackColor, float dist, int steps) {
    vec2 pixelPos = coord;
    float depth = getDepth(coord);

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

        if (getType(sampleCoord) != vec3(0,0,1) && sampleDepth > depth) {
            //Hit
            b2 = sampleCoord;
        } else {
            //No Hit
            b1 = sampleCoord;
        }
    }
    if (getType_interpolated(sampleCoord) != vec3(0,0,1)) {
        vec2 reflectPos = sampleCoord + (sampleCoord - coord);
        sampleDepth = getDepth(reflectPos);

        if (clamp(reflectPos, 0, 1) != reflectPos || getType(reflectPos) == vec3(0,0,1) || sampleDepth == 1.0) {
            return fallBackColor;
        }

        return getAlbedo(reflectPos);
    }

    return fallBackColor;
}

// Removing the functions to avoid compile errors
#ifdef SSR_CHEAP
#else

vec3 testSSR(vec2 coord, vec3 normal, float depth, vec3 screenPos, vec3 clipPos, vec3 viewPos, vec3 viewDirection) {
    // Reflect view Ray along normals of surface
    vec3 reflectionRay = reflect(viewDirection, normal);
    vec3 viewSpaceReflection = viewPos + reflectionRay;

    // Project ray into screen space
    vec4 screenSpaceRayTemp = gbufferProjection * vec4(viewSpaceReflection, 1);
    vec3 screenSpaceRayDirection = normalize(screenSpaceRayTemp.xyz / screenSpaceRayTemp.w - clipPos);

    vec3 rayPos = screenPos;

    // define the step Size for the ray
    vec3 rayStep = screenSpaceRayDirection;
    rayStep /= SSR_STEPS;
    rayStep *= SSR_DISTANCE;

    float randfac = randf_01(coord) * 0.3333;
    rayPos -= rayStep * randfac;

    float appliedDepthTolerance;
    float hitDepth;
    float rayDepth;


    //////////////////////////////////////////////////////////////////
    //                  Screen Space Raytrace Loop
    //////////////////////////////////////////////////////////////////


    for (int i = 0; i < SSR_STEPS; i++) {        
        rayPos += rayStep;

        if(clamp(rayPos, 0, 1 + rayStep.z) != rayPos) {
            break;
        }

        float hitDepth = getDepth(rayPos.xy).x;

        if (rayPos.z >= hitDepth && hitDepth > 0.5) {
            // Check if reflection hits water
            if (getType(rayPos.xy) == vec3(0,0,1)) {
                break;
            }

            // After having found an intersection, refine Reflection
            // Define new (smaller) Stepsize
            vec3 newRayStep = rayStep / SSR_FINE_STEPS;

            // Move the position back by half a step
            rayPos -= rayStep;

            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                //return getAlbedo(rayPos.xy);

                rayPos += newRayStep;
                
                /*if (clamp(rayPos, 0, 0.999999) != rayPos) {
                    return getSkyColor(reflectionRay);
                }*/
                if (getType(rayPos.xy) == vec3(0,0,1)) {
                    break;
                }
                
                hitDepth = getDepth(rayPos.xy);
                rayDepth = rayPos.z;

                appliedDepthTolerance = rayStep.z * SSR_DEPTH_TOLERANCE;
                
                if (rayDepth > hitDepth && rayDepth - appliedDepthTolerance < hitDepth && hitDepth > 0.5) {
                    return getAlbedo(rayPos.xy);
                }
            }

            //return cheapSSR_final(coord, normal, getSkyColor(reflectionRay), 0.02, 4);
        }
    }

    return getSkyColor(reflectionRay);
}

vec3 testSSR_opt(vec2 coord, vec3 normal, float depth, vec3 screenPos, vec3 clipPos, vec3 viewPos, vec3 viewDirection) {
    // Reflect view Ray along normals of surface
    vec3 reflectionRay = reflect(viewDirection, normal);
    vec3 viewSpaceReflection = viewPos + reflectionRay;

    // Project ray into screen space
    vec4 screenSpaceRayTemp = gbufferProjection * vec4(viewSpaceReflection, 1);
    vec3 screenSpaceRayDirection = normalize(screenSpaceRayTemp.xyz / screenSpaceRayTemp.w - clipPos);

    vec3 rayPos = screenPos;

    // define the step Size for the ray
    vec3 rayStep = screenSpaceRayDirection;
    rayStep /= SSR_STEPS;
    rayStep *= SSR_DISTANCE;

    float randfac = randf_01(coord) * 0.3333;
    rayPos -= rayStep * randfac;

    float appliedDepthTolerance;
    float hitDepth;
    float rayDepth;


    //////////////////////////////////////////////////////////////////
    //                  Screen Space Raytrace Loop
    //////////////////////////////////////////////////////////////////


    for (int i = 0; i < SSR_STEPS; i++) {        
        rayPos += rayStep;

        if(clamp(rayPos, 0, 1 + rayStep.z) != rayPos) {
            break;
        }

        float hitDepth = getDepth(rayPos.xy).x;

        if (rayPos.z >= hitDepth && hitDepth > 0.5) {
            // Check if reflection hits water
            if (getType(rayPos.xy) == vec3(0,0,1)) {
                break;
            }

            // After having found an intersection, refine Reflection
            // Define new (smaller) Stepsize
            vec3 newRayStep = rayStep / SSR_FINE_STEPS;

            // Move the position back by half a step
            rayPos -= rayStep;

            for (int o = 0; o < SSR_FINE_STEPS; o++) {
                //return getAlbedo(rayPos.xy);

                rayPos += newRayStep;
                
                /*if (clamp(rayPos, 0, 0.999999) != rayPos) {
                    return getSkyColor(reflectionRay);
                }*/
                if (getType(rayPos.xy) == vec3(0,0,1)) {
                    break;
                }
                
                hitDepth = getDepth(rayPos.xy);
                rayDepth = rayPos.z;

                appliedDepthTolerance = rayStep.z * SSR_DEPTH_TOLERANCE;
                
                if (rayDepth > hitDepth && rayDepth - appliedDepthTolerance < hitDepth && hitDepth > 0.5) {
                    return getAlbedo(rayPos.xy);
                }
            }

            //return cheapSSR_final(coord, normal, getSkyColor(reflectionRay), 0.02, 4);
        }
    }

    return getSkyColor(reflectionRay);
}

#endif

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////

float cheapSSAO(vec2 coord, float size, float bias) {
    float depth = getDepth(coord).x;
    if (depth == 1.0) { return 0; }

    depth = linearizeDepth(depth, near, far);
    vec3 normal = getNormal(coord);

    float fine_occlusion = 0;
    float coarse_occlusion = 0;
    float occlusion;
    const int kernelsize = 8;

    for (int i = 0; i < kernelsize; i++) {
        vec2 kernelcoords = SSAO_kernel_low_polar[i];
        kernelcoords.y += randf_01(coord) * 3.141;
        kernelcoords = convertPolarCartesian(kernelcoords) * size * (1/depth);

        float sampleDepth = getLinearDepth(coord + (kernelcoords)).x;

        fine_occlusion += int(sampleDepth < depth - 0.03 && sampleDepth > 0.25);
        fine_occlusion -= int(sampleDepth > depth + 0.03 && sampleDepth > 0.25);
        
        sampleDepth = getLinearDepth(coord + (kernelcoords * 2)).x;

        coarse_occlusion += int(sampleDepth < depth - 0.05 && sampleDepth > 0.25);
        coarse_occlusion -= int(sampleDepth > depth + 0.05 && sampleDepth > 0.25);
    }

    occlusion = max(fine_occlusion, coarse_occlusion) / kernelsize;
    occlusion = clamp(occlusion + bias, 0, 1);

    return occlusion;
}

float cheapSSAO_opt1(vec2 coord, float size, float bias) {
    float depth = getDepth(coord).x;
    if (depth == 1.0) { return 0; }

    depth = linearizeDepth(depth, near, far);
    vec3 normal = getNormal(coord);

    float fine_occlusion = 0;
    float coarse_occlusion = 0;
    float occlusion;
    const int kernelsize = 8;

    for (int i = 0; i < kernelsize; i++) {
        vec2 kernelcoords = SSAO_kernel_low_polar[i];
        kernelcoords.y += randf_01(coord) * 3.141 * SSAO_RANDOMIZE_AMOUNT;
        kernelcoords = convertPolarCartesian(kernelcoords) * size * (1/depth);

        float sampleDepth = getLinearDepth(coord + (kernelcoords)).x;
        int isHand = int(sampleDepth > 0.25);

        fine_occlusion += int(sampleDepth < depth - 0.03) * isHand;
        fine_occlusion -= int(sampleDepth > depth + 0.03) * isHand;
        
        #ifdef SSAO_TWO_PASS
            sampleDepth = getLinearDepth(coord + (kernelcoords * 2)).x;

            coarse_occlusion += int(sampleDepth < depth - 0.05) * isHand;
            coarse_occlusion -= int(sampleDepth > depth + 0.05) * isHand;
        #endif
    }

    occlusion = max(fine_occlusion, coarse_occlusion) / kernelsize;
    occlusion = clamp(occlusion + bias, 0, 1);

    return occlusion;
}

vec4 cheapSSAO_GI(vec2 coord, float size, float bias) {
    float depth = getDepth(coord);
    if (depth == 1.0) { return vec4(0); }

    depth = linearizeDepth(depth, near, far);
    vec3 normal = getNormal(coord);

    vec3 color = vec3(0);
    float fine_occlusion = 0;
    float coarse_occlusion = 0;
    float occlusion;
    const int kernelsize = 8;

    for (int i = 0; i < kernelsize; i++) {
        vec2 kernelcoords = SSAO_kernel_low_polar[i];
        kernelcoords.y += randf_01(coord) * 3.141 * SSAO_RANDOMIZE_AMOUNT;
        kernelcoords = convertPolarCartesian(kernelcoords) * size * (1/depth);

        float sampleDepth = getLinearDepth(coord + (kernelcoords)).x;
        int isHand = int(sampleDepth > 0.25);
        int isInfluence = int(sampleDepth < depth - 0.03);

        color += getAlbedo(coord + (kernelcoords));
        fine_occlusion += isInfluence * isHand;
        fine_occlusion -= int(sampleDepth > depth + 0.03) * isHand;
        
        #ifdef SSAO_TWO_PASS
            sampleDepth = getLinearDepth(coord + (kernelcoords * 2)).x;

            coarse_occlusion += int(sampleDepth < depth - 0.05) * isHand;
            coarse_occlusion -= int(sampleDepth > depth + 0.05) * isHand;
        #endif
    }

    color /= kernelsize;
    occlusion = max(fine_occlusion, coarse_occlusion) / kernelsize;
    occlusion = clamp(occlusion + bias, 0, 1);

    return vec4(color, occlusion);
}

float getSpecularP(vec3 viewDirection, vec3 normal, float bias, float shininess) {
    vec3 lightDir = lightVector;
    vec3 reflection = reflect(viewDirection, normal);

    float spec = mapclamp(max(dot(reflection, lightDir), 0.0), 0.95, 0.999, 0, 1);

    spec = pow(spec, shininess);
    return spec;
}

/* DRAWBUFFERS:0 */

void main() {
    /*
    vec2 weirdCoord = (coord * 2) - 1;
    weirdCoord /= ((getLinearDepth(coord)));
    weirdCoord = (weirdCoord * 0.5) + 0.5;
    weirdCoord = clamp(weirdCoord, 0, 0.999999);
    vec3 color          = getAlbedo(weirdCoord);
    */

    vec3 color          = getAlbedo(coord);

    
    // Check if pixel is water
    if (getType(coord) == vec3(0,0,1)) {
        vec3 normal         = getNormal(coord);
        float depth         = getDepth(coord);

        vec3 screenPos = vec3(coord, depth);
        vec3 clipPos = screenPos * 2.0 - 1.0;
        vec4 tmp = gbufferProjectionInverse * vec4(clipPos, 1.0);
        vec3 viewPos = tmp.xyz / tmp.w;
        vec3 viewDirection = normalize(viewPos);

        float fresnel = customFresnel(viewDirection, normal, 0.02, 2, 3);

        #ifdef SSR_CHEAP

            vec3 viewPos = getViewPosition(coord);
            vec3 sky = getSkyColor(reflect(viewPos, normal));
            color = mix(color, cheapSSR_final(coord, normal, sky, SSR_DISTANCE, SSR_STEPS), fresnel);

        #else
        
            color = mix(color, testSSR_opt(coord, normal, depth, screenPos, clipPos, viewPos, viewDirection), fresnel);

        #endif


    }

    //Pass everything forward
    
    COLORTEX_0          = vec4(color, 1);
}