uniform float daynight;
uniform float sunset;

uniform vec3 fogColor;

/* // My original values
const vec3 sky_up_day   = vec3(0.1, 0.35, 1.0);  //Color of upper part of sky at noon
const vec3 sky_up_night = vec3(0.1, 0.13, 0.25); //Color of upper part of sky at midnight
const vec3 end_sky_up   = vec3(0.2, 0, 0.3);  // Color of the upper sky in the end
const vec3 end_sky_down = vec3(0.05, 0, 0.1); // Color of the lower sky in the end
*/

const vec3 sky_up_day   = vec3(SKY_DAY_R,   SKY_DAY_G,   SKY_DAY_B);   //Color of upper part of sky at noon
const vec3 sky_up_night = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B); //Color of upper part of sky at midnight

const vec3 sunset_color = vec3(SKY_SUNSET_R, SKY_SUNSET_G, SKY_SUNSET_B);

const vec3 end_sky_up   = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B);  // Color of the upper sky in the end
const vec3 end_sky_down = vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B); // Color of the lower sky in the end

vec3 getSkyColor5(vec3 viewPos, float rain) {

    #ifdef NETHER

        return fogColor;

    #elif defined END 

        vec3  playerEyePos = mat3(gbufferModelViewInverse) * viewPos;
        float viewHeight   = clamp(playerEyePos.y / sqrt(dot(playerEyePos, playerEyePos)) * 0.55 + 0.45, 0, 1);

        float offset       = noise(vec2(atan(abs(playerEyePos.z / playerEyePos.x))) * PI);
        offset            *= 1 - sq(viewHeight * 2 - 1);
        offset             = offset * 0.1 - 0.05;
        viewHeight         = saturate(viewHeight + offset);

        return mix(end_sky_down, end_sky_up, viewHeight);

    #else

        vec3  playerEyePos = mat3(gbufferModelViewInverse) * viewPos;
        float viewHeight   = clamp(playerEyePos.y / sqrt(dot(playerEyePos, playerEyePos)) * 0.9 + 0.1, 0, 1);

        vec3 sky_up = mix(sky_up_day, sky_up_night, daynight);
        sky_up      = mix(sky_up, fogColor * 0.5, rain);

        vec3 sky_down = mix(fogColor, sunset_color, sunset);
        sky_down      = mix(sky_down, fogColor, rain);
        return mix(sky_down, sky_up, viewHeight); //Get sky

    #endif

}
vec3 getSkyColor5_gamma(vec3 viewPos, float rain) {
    vec3 color = getSkyColor5(viewPos, rain);
    return pow(color, vec3(GAMMA));
}


vec3 getFogColor(vec3 viewPos, float rain, int eyeWater) {
    if (eyeWater == 0) {
        return getSkyColor5(viewPos, rain);
    } else if (eyeWater == 1) {
        return fogColor * 0.25;
    } else {
        return fogColor;
    }
}
vec3 getFogColor_gamma(vec3 viewPos, float rain, int eyeWater) {
    return pow(getFogColor(viewPos, rain, eyeWater), vec3(GAMMA));
}