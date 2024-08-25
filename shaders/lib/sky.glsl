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


const vec3 sun_color = vec3(GODRAY_SUN_R, GODRAY_SUN_G, GODRAY_SUN_B);
const vec3 moon_color = vec3(GODRAY_MOON_R, GODRAY_MOON_G, GODRAY_MOON_B);

const vec3 sky_up_day   = vec3(SKY_DAY_R,   SKY_DAY_G,   SKY_DAY_B);   //Color of upper part of sky at noon
const vec3 sky_up_night = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B); //Color of upper part of sky at midnight

const vec3 sunset_color = vec3(SKY_SUNSET_R, SKY_SUNSET_G, SKY_SUNSET_B);

const vec3 end_sky_up   = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B);  // Color of the upper sky in the end
const vec3 end_sky_down = vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B); // Color of the lower sky in the end

vec3 skyBaseGradient(vec3 playerDir, vec4 colorParameter) {
    const float softmaxFactor = 2;
    const float softmaxCorrection = exp2(-softmaxFactor) + 1;

    float softmax    = 1 / ( exp2(softmaxFactor * -playerDir.y) + 1 );
    float softheight = softmax * softmaxCorrection * playerDir.y;

    vec3  baseColor = exp2( -abs(softheight + colorParameter.a) / colorParameter.rgb );
    float sunsetMix = exp2( -abs(softheight) * 4 ) * sunset;

    return mix(baseColor, sunset_color, sunsetMix);
}

vec3 getSky(vec3 playerEyePos) {

    vec3 color;

    #if defined NETHER

        color = fogColor;

    #elif defined END 

        float viewHeight = playerEyePos.y * inversesqrt(sqmag(playerEyePos));

        float offset     = noise(vec2(abs(atan(playerEyePos.z, playerEyePos.x))) * 4.4) - 0.5;
        offset          *= sq(1 - sq(viewHeight)) * 0.25;
        viewHeight       = saturate(viewHeight * 0.5 + 0.5 + offset);

        color = mix(end_sky_down, end_sky_up, viewHeight);

    #else

        vec3 playerDir = normalize(playerEyePos);

        const vec4 noon     = vec4(.2, .32, .6, 0);
        const vec4 midnight = vec4(.2, .24, .3, 1.5);

        float baseColorMixFactor  = smoothstep(0, 1, daynight);
        float baseOffsetMixFactor = smoothstep(0, 1, baseColorMixFactor);
        vec4  baseColorMix        = vec4(
            mix(noon.rgb, midnight.rgb, baseColorMixFactor),
            mix(noon.a, midnight.a, baseOffsetMixFactor)
        );

        vec3 baseGradient = skyBaseGradient(playerDir, baseColorMix);
        vec3 rainGradient = mix(fogColor, fogColor * 0.5, saturate(playerDir.y * .75 + 0.25));

        color = mix(baseGradient, rainGradient, rainStrength);
        
        #ifdef CAVE_FOG
        color = mix(vec3(CAVE_FOG_BRIGHTNESS), color, saturate(eyeBrightnessSmooth.y * (5./240))); // Get sky
        #endif

    #endif

    return pow(color, vec3(GAMMA));

}

vec3 getFog(vec3 playerEyePos) {
    if (isEyeInWater == 0)      return getSky(playerEyePos);
    else if (isEyeInWater == 1) return pow(fogColor * 0.25, vec3(GAMMA));
    else                        return pow(fogColor, vec3(GAMMA));
}

vec3 getGodrayColor() {
    if (daynight < 0.5) return mix(sun_color, sunset_color * 2, sunset) * (1 - rainStrength);
    return moon_color * (1 - rainStrength);
}