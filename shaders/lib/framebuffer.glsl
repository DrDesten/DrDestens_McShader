uniform sampler2D colortex0; // Color
uniform sampler2D colortex2; // Normals

uniform sampler2D colortex3; // Type (BlockID)
uniform sampler2D depthtex0;

uniform float viewHeight;
uniform float viewWidth;

#define FD0 gl_FragData[0]
#define FD1 gl_FragData[1]
#define FD2 gl_FragData[2]
#define FD3 gl_FragData[3]

vec2 ScreenSize        = vec2(viewWidth, viewHeight);
vec2 ScreenSizeInverse = 1 / ScreenSize;


ivec2 convertIntCoords(vec2 coord, float x, float y) {
    return ivec2(coord.x * x, coord.y * y);
}
vec2 blurOffset(vec2 coord, float lod) {
    return coord + ((0.5 / ScreenSize) * (lod + 1));
}


vec3 getAlbedo(in vec2 coord) {
    return texelFetch(colortex0, convertIntCoords(coord, viewWidth, viewHeight), 0).rgb;
}
vec3 getAlbedo_int(in vec2 coord) {
    return texture(colortex0, coord).rgb;
}

vec3 getNormal(in vec2 coord) {
    return texture(colortex2, coord).rgb;
}

float getDepth(in vec2 coord) {
    return texelFetch(depthtex0, convertIntCoords(coord, viewWidth, viewHeight), 0).x;
}
float getDepth_int(in vec2 coord) {
    return texture(depthtex0, coord).x;
}

float getType(in vec2 coord) {
    return texelFetch(colortex3, convertIntCoords(coord, viewWidth, viewHeight), 0).r;
}
float getType_interpolated(in vec2 coord) {
    return texture(colortex3, coord).r;
}

/* Snipplets for later

// TAA REPROJECTION

//depth is raw depth buffer
//coord is texture coordinates of fullscreen quad (composite yo)
vec2 taa_reproject(vec2 coord, float depth) 
{
    //Clip space
    vec4 pos = vec4(coord, depth, 1.0) * 2.0 - 1.0;

    //View space
    pos = gbufferProjectionInverse * pos;
    pos /= pos.w;

    //World space
    pos = gbufferModelViewInverse * pos;

    //Previous position
    vec4 prev_pos = pos + vec4(cameraPosition-previousCameraPosition, 0.0);
    
    //World to view space
    prev_pos = gbufferPreviousModelView * prev_pos;
    
    //View to projection space
    prev_pos = gbufferPreviousProjection * prev_pos;

    //Projection to UV space
    return (prev_pos.xy / prev_pos.w) * 0.5 + 0.5;
}


// SKY GRADIENT

vec3 dir = normalize(eyePlayerPos); //Get view direction in world space (chech ;position in bot channel to understand what eyePlayerPos is
vec3 sky_up = vec3(0.05, 0.2, 0.5); //Color of upper part of sky
vec3 sky_down = vec3(0.10, 0.40, 1.0); //Color of bottom part of sky

if (texture2D(depthtex0, coord).r == 1.0f)    //Check depth, if it's 1.0 - then it's sky.
    color = mix(sky_down, sky_up, dir.y); //Get sky

*/