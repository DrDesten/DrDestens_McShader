uniform float daynight;
uniform float sunset;
uniform vec3  fogColor;
uniform int   isEyeInWater;

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


vec3 getSky(vec3 playerEyePos) {

    vec3 color;

    #ifdef NETHER

        color = fogColor;

    #elif defined END 

        float viewHeight = playerEyePos.y * inversesqrt(sqmag(playerEyePos));

        float offset     = noise(vec2(abs(atan(playerEyePos.z, playerEyePos.x))) * 4.4) - 0.5;
        offset          *= sq(1 - sq(viewHeight)) * 0.25;
        viewHeight       = saturate(viewHeight * 0.5 + 0.5 + offset);

        color = mix(end_sky_down, end_sky_up, viewHeight);

    #else

        float viewHeight = saturate(playerEyePos.y * inversesqrt(sqmag(playerEyePos)));

        vec3 sky_up = mix(sky_up_day, sky_up_night, daynight);
        sky_up      = mix(sky_up, fogColor * 0.5, rainStrength);

        vec3 sky_down = mix(fogColor, sunset_color, sunset);
        sky_down      = mix(sky_down, fogColor, rainStrength);
        
        color = mix(sky_down, sky_up, viewHeight); // Get sky

        //color = vec3(sunset);

    #endif

    return pow(color, vec3(GAMMA));

}

vec3 getFog(vec3 playerEyePos) {
    if (isEyeInWater == 0)      return getSky(playerEyePos);
    else if (isEyeInWater == 1) return pow(fogColor * 0.25, vec3(GAMMA));
    else                        return pow(fogColor, vec3(GAMMA));
}