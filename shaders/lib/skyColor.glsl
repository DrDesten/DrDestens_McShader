uniform int  worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 fogColor;

/*
// Thanks BuilderbOy ;)
float ang = fract(worldTime / 24000.0 - 0.25);
ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0); // * 6.28318530717959; //0-2pi, rolls over from 2pi to 0 at noon.
*/

vec3 getSkyColor1(vec3 viewPos) {
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vec3 dir = normalize(eyePlayerPos); //Get view direction in world space (chech ;position in bot channel to understand what eyePlayerPos is
    dir.y = max(dir.y, 0);

    float daynight;
    float mixfac;

    vec3 sky_up;
    vec3 sky_down;
    float sky_bias;

    //Day
    const vec3 sky_up_day = vec3(0.1, 0.4, 1.0); //Color of upper part of sky
    const vec3 sky_down_day = vec3(0.55, 0.7, 1.0); //Color of bottom part of sky
    const float sky_bias_day = 0;

    //Night
    const vec3 sky_up_night = vec3(0.075, 0.075, 0.15); //Color of upper part of sky
    const vec3 sky_down_night = vec3(0.075, 0.1, 0.2); //Color of bottom part of sky
    const float sky_bias_night = 0;
    
    // Afternoon / Morning
    const vec3 sky_up_afternoon = vec3(0.1, 0.2, 0.5); //Color of upper part of sky
    const vec3 sky_down_afternoon = vec3(0.7, 0.3, 0.2); //Color of bottom part of sky
    const float sky_bias_afternoon = 0.4;



    if (worldTime < 12000) { // Day
        sky_up   = sky_up_day;
        sky_down = sky_down_day;
        sky_bias = sky_bias_day;
    } else if (worldTime > 13500 && worldTime < 22500) { // Night
        sky_up   = sky_up_night;
        sky_down = sky_down_night;
        sky_bias = sky_bias_night;
    }

    // Right now I have adressed all values from 0 to 12000 and from 13500 to 22500
    // Next up,the intermediates

    if (worldTime >= 12000 && worldTime <= 13500) { // Day to Night
        mixfac = map(worldTime, 12000, 13500, 0, 1);

        sky_up   = mix(sky_up_day,   sky_up_night,   mixfac);
        sky_down = mix(sky_down_day, sky_down_night, mixfac);
        sky_bias = mix(sky_bias_day, sky_bias_night, mixfac);

    } else if (worldTime >= 22500) { // Night to Day
        mixfac = map(worldTime, 22500, 24000, 1, 0);

        sky_up   = mix(sky_up_day,   sky_up_night,   mixfac);
        sky_down = mix(sky_down_day, sky_down_night, mixfac);
        sky_bias = mix(sky_bias_day, sky_bias_night, mixfac);
    }

    /*if (worldTime >= 12000 && worldTime <= 13500) { // Night to Day
        sky_up   = sky_up_afternoon;
        sky_down = sky_down_afternoon;
        sky_bias = sky_bias_afternoon;
    } else if (worldTime >= 22500) { // Day to Night
        sky_up   = sky_up_afternoon;
        sky_down = sky_down_afternoon;
        sky_bias = sky_bias_afternoon;
    }*/

    return mix(sky_down, sky_up, dir.y + sky_bias); //Get sky
}

vec3 getSkyColor2(vec3 viewPos) {
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vec3 dir = normalize(eyePlayerPos); //Get view direction in world space (chech ;position in bot channel to understand what eyePlayerPos is
    dir.y = max(dir.y, 0);

    float daynight;
    float mixfac;
    vec3 sky_up;
    vec3 sky_down;
    float sky_bias;

    //Day
    const vec3 sky_up_day = vec3(0.1, 0.4, 1.0); //Color of upper part of sky
    const vec3 sky_down_day = vec3(0.55, 0.7, 1.0); //Color of bottom part of sky
    const float sky_bias_day = 0;

    //Night
    const vec3 sky_up_night = vec3(0.1, 0.1, 0.2); //Color of upper part of sky
    const vec3 sky_down_night = vec3(0.2, 0.3, 0.5); //Color of bottom part of sky
    const float sky_bias_night = 0;
    
    // Afternoon / Morning
    const vec3 sky_up_noon = vec3(0.1, 0.2, 0.5); //Color of upper part of sky
    const vec3 sky_down_noon = vec3(0.7, 0.3, 0.2); //Color of bottom part of sky
    const float sky_bias_noon = 0.4;

    // Setting daynight
    if (worldTime > 7000 && worldTime < 19000) {
        daynight = map(worldTime, 7000, 19000, 1, 0);
    } else if (worldTime <= 7000) {
        daynight = map(worldTime, -1000, 7000, 0.5, 1);
    } else {
        daynight = map(worldTime, 19000, 23000, 0, 0.5);
    }

    if (daynight >= .52) { // Day
        sky_up   = sky_up_day;
        sky_down = sky_down_day;
        sky_bias = sky_bias_day;

    } else if (daynight <= .48) { // Night
        sky_up   = sky_up_night;
        sky_down = sky_down_night;
        sky_bias = sky_bias_night;

    } else if (daynight >= .5) { // Inbetween
        mixfac = map(daynight, .52, .5, 0, 1);

        sky_up   = mix(sky_up_day,   sky_up_noon,   mixfac);
        sky_down = mix(sky_down_day, sky_down_noon, mixfac);
        sky_bias = mix(sky_bias_day, sky_bias_noon, mixfac);
        //return vec3(0);
        
    } else { // Inbetween
        mixfac = map(daynight, .48, .5, 0, 1);

        sky_up   = mix(sky_up_night,   sky_up_noon,   mixfac);
        sky_down = mix(sky_down_night, sky_down_noon, mixfac);
        sky_bias = mix(sky_bias_night, sky_bias_noon, mixfac);

        //return vec3(0);
    }

    return mix(sky_down, sky_up, dir.y + sky_bias); //Get sky
}

vec3 getSkyColor3(vec3 viewPos) {
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vec3 dir = normalize(eyePlayerPos);
    dir.y = max(dir.y, 0);
    
    float ang = fract(worldTime / 24000.0 - 0.25);
    ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0); // * 6.28318530717959; //0-2pi, rolls over from 2pi to 0 at noon.

    float daynight;
    float mixfac;
    vec3 sky_up;
    vec3 sky_down;
    float sky_bias;

    //Day
    const vec3 sky_up_day = vec3(0.1, 0.4, 1.0); //Color of upper part of sky
    const vec3 sky_down_day = vec3(0.55, 0.7, 1.0); //Color of bottom part of sky
    const float sky_bias_day = 0;

    //Night
    const vec3 sky_up_night = vec3(0.1, 0.1, 0.2); //Color of upper part of sky
    const vec3 sky_down_night = vec3(0.2, 0.3, 0.5); //Color of bottom part of sky
    const float sky_bias_night = 0;
    
    // Afternoon / Morning
    const vec3 sky_up_noon = vec3(0.1, 0.2, 0.5); //Color of upper part of sky
    const vec3 sky_down_noon = vec3(0.7, 0.3, 0.2); //Color of bottom part of sky
    const float sky_bias_noon = 0.4;


    if (ang > .8 || ang < .2) { // Day
        sky_up   = sky_up_day;
        sky_down = sky_down_day;
        sky_bias = sky_bias_day;

    } else if (ang < .7 && ang > .3) { // Night
        sky_up   = sky_up_night;
        sky_down = sky_down_night;
        sky_bias = sky_bias_night;

    } else if (ang > .7) { // Inbetween (night-day)
        mixfac = (ang - .7) * 10;
        
        sky_up   = mix(sky_up_night,   sky_up_day,   mixfac);
        sky_down = mix(sky_down_night, sky_down_day, mixfac);
        sky_bias = mix(sky_bias_night, sky_bias_day, mixfac);
        //sky_up = vec3(1,0,0);

    } else if (ang < .3) { // Inbetween (day-night)
        mixfac = (ang - .2) * 10;

        sky_up   = mix(sky_up_day,   sky_up_night,   mixfac);
        sky_down = mix(sky_down_day, sky_down_night, mixfac);
        sky_bias = mix(sky_bias_day, sky_bias_night, mixfac);

    }

    return mix(fogColor, sky_up, dir.y + sky_bias); //Get sky
}

vec3 getSkyColor4(vec3 viewPos) {
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vec3 dir = normalize(eyePlayerPos);
    dir.y    = clamp(dir.y, 0, 1);
    
    float mixfac = cos((worldTime / 24000. + 0.25) * TWO_PI) * 0.5 + 0.5;

    //Day
    const vec3 sky_up_day   = vec3(0.1, 0.4, 1.0); //Color of upper part of sky
    //Night
    const vec3 sky_up_night = vec3(0.1, 0.1, 0.2); //Color of upper part of sky
    
    vec3 sky_up = mix(sky_up_day, sky_up_night, mixfac);
    return mix(fogColor, sky_up, dir.y); //Get sky
}