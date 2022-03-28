///////////////////////////////////////////////////////////////////
// END SKY is rendered in DEFERRED
///////////////////////////////////////////////////////////////////

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

const vec3 end_sky_up   = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B);  // Color of the upper sky in the end
const vec3 end_sky_down = vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B); // Color of the lower sky in the end

vec3 endSky(vec3 eyePlayerPos) {

    float viewHeight   = clamp(eyePlayerPos.y / sqrt(dot(eyePlayerPos, eyePlayerPos)) * 0.55 + 0.45, 0, 1);
    float offset       = noise(vec2(atan(abs(eyePlayerPos.z / eyePlayerPos.x))) * PI);
    offset            *= 1 - sq(viewHeight * 2 - 1);
    offset             = offset * 0.1 - 0.05;
    viewHeight         = saturate(viewHeight + offset);

    return mix(end_sky_down, end_sky_up, viewHeight);
}

/* DRAWBUFFERS:0 */
void main() {
    float depth = getDepth(coord);
    vec3 color;
    if (depth >= 1) {

        vec3 eyePlayerPos = toPlayerEye(toView(vec3(coord, depth) * 2 - 1));
        color = endSky(eyePlayerPos); //Get sky

        gamma(color.rgb);

    } else {
        color = getAlbedo(coord);
    }
    
    /* float dither = Bayer4(gl_FragCoord.xy) * (1./64) - (.5/64);
    color       += vec3(dither, dither, dither * 2); */

    gl_FragData[0] = vec4(color, 1.0);
}