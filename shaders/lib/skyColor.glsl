uniform int   worldTime;
uniform float daynight;
//uniform float sunset;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 fogColor;

/* // My original values
const vec3 sky_up_day   = vec3(0.1, 0.35, 1.0);  //Color of upper part of sky at noon
const vec3 sky_up_night = vec3(0.1, 0.13, 0.25); //Color of upper part of sky at midnight
const vec3 end_sky_up   = vec3(0.2, 0, 0.3);  // Color of the upper sky in the end
const vec3 end_sky_down = vec3(0.05, 0, 0.1); // Color of the lower sky in the end
*/

const vec3 sky_up_day   = vec3(SKY_DAY_R,   SKY_DAY_G,   SKY_DAY_B);   //Color of upper part of sky at noon
const vec3 sky_up_night = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B); //Color of upper part of sky at midnight

const vec3 end_sky_up   = vec3(0.2, 0, 0.3);  // Color of the upper sky in the end
const vec3 end_sky_down = vec3(0.05, 0, 0.1); // Color of the lower sky in the end

vec3 getSkyColor4(vec3 viewPos) {
    vec3  eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    float viewHeight   = clamp(eyePlayerPos.y / sqrt(dot(eyePlayerPos, eyePlayerPos)) * 0.9 + 0.1, 0, 1);
    
    //float sunset   =  pow( cos(worldTime / 24000. * TWO_PI * 2) * 0.5 + 0.5, 20 );  // Sunset curve (power adjusts the sunset length)

    vec3 sky_up = mix(sky_up_day, sky_up_night, daynight);
    return mix(fogColor, sky_up, viewHeight); //Get sky
}
vec3 getSkyColor4_gamma(vec3 viewPos) {
    vec3 color = getSkyColor4(viewPos);
    return pow(color, vec3(2.2));
}

vec3 getSkyColor5(vec3 viewPos, float rain) {

    #ifdef NETHER

        const vec3 nether_sky = vec3(1,0,0);
        return fogColor;

    #elif defined END 

        vec3  eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        float viewHeight   = clamp(eyePlayerPos.y / sqrt(dot(eyePlayerPos, eyePlayerPos)) * 0.9 + 0.1, 0, 1);

        return mix(end_sky_down, end_sky_up, viewHeight);

    #else

        vec3  eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        float viewHeight   = clamp(eyePlayerPos.y / sqrt(dot(eyePlayerPos, eyePlayerPos)) * 0.9 + 0.1, 0, 1);

        vec3 sky_up = mix(sky_up_day, sky_up_night, daynight);
        sky_up      = mix(sky_up, fogColor * 0.5, rain);
        return mix(fogColor, sky_up, viewHeight); //Get sky

    #endif

}
vec3 getSkyColor5_gamma(vec3 viewPos, float rain) {
    vec3 color = getSkyColor5(viewPos, rain);
    return pow(color, vec3(2.2));
}