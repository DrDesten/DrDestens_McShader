uniform int worldTime;

vec3 getSkyColor(vec3 viewPos) {
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
