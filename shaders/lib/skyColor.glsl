uniform int  worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 fogColor;

/*
// Thanks BuilderbOy ;)
float ang = fract(worldTime / 24000.0 - 0.25);
ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0); // * 6.28318530717959; //0-2pi, rolls over from 2pi to 0 at noon.
*/

vec3 getSkyColor4(vec3 viewPos) {
    vec3  eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    float viewHeight   = clamp(eyePlayerPos.y / sqrt(dot(eyePlayerPos, eyePlayerPos)) * 0.9 + 0.1, 0, 1);
    
    float daynight = -sin(worldTime / 24000. * TWO_PI) * 0.5 + 0.5;                  // Smooth day-to-night transition curve
    //float sunset   =  pow( cos(worldTime / 24000. * TWO_PI * 2) * 0.5 + 0.5, 20 );  // Sunset curve (power adjusts the sunset length)

    //Day
    const vec3 sky_up_day   = vec3(0.1, 0.35, 1.0); //Color of upper part of sky
    //Night
    const vec3 sky_up_night = vec3(0.1, 0.13, 0.25); //Color of upper part of sky
    
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

    #else

        vec3  eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        float viewHeight   = clamp(eyePlayerPos.y / sqrt(dot(eyePlayerPos, eyePlayerPos)) * 0.9 + 0.1, 0, 1);
        
        float daynight = -sin(worldTime / 24000. * TWO_PI) * 0.5 + 0.5;                  // Smooth day-to-night transition curve
        //float sunset   =  pow( cos(worldTime / 24000. * TWO_PI * 2) * 0.5 + 0.5, 20 );  // Sunset curve (power adjusts the sunset length)

        //Day
        const vec3 sky_up_day   = vec3(0.1, 0.35, 1.0); //Color of upper part of sky
        //Night
        const vec3 sky_up_night = vec3(0.1, 0.13, 0.25); //Color of upper part of sky
        
        vec3 sky_up = mix(sky_up_day, sky_up_night, daynight);
        sky_up      = mix(sky_up, fogColor * 0.5, rain);
        return mix(fogColor, sky_up, viewHeight); //Get sky

    #endif

}
vec3 getSkyColor5_gamma(vec3 viewPos, float rain) {
    vec3 color = getSkyColor5(viewPos, rain);
    return pow(color, vec3(2.2));
}