uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;


vec3 toView(vec3 clipspace) { // Clippos to viewpos
    vec4 tmp = gbufferProjectionInverse * vec4(clipspace, 1.0);
    return tmp.xyz / tmp.w;
}

vec3 toPlayer(vec3 viewspace) { // Viewpos to Playerfeetpos
    return mat3(gbufferModelViewInverse) * viewspace + gbufferModelViewInverse[3].xyz;
}
vec3 toPlayerEye(vec3 viewspace) { // Viewpos to Playerfeetpos
    return mat3(gbufferModelViewInverse) * viewspace;
}

vec3 toWorld(vec3 playerpos) { // Playerfeetpos to worldpos
    return playerpos + cameraPosition;
}


vec3 backToPlayer(vec3 worldpos) { // Worldpos to previous playerfeetpos
    return worldpos + cameraPosition;
}

vec3 backToView(vec3 playerpos) { // previous playerfeetpos to previous viewpos
    return mat3(gbufferModelView) * (playerpos - gbufferModelViewInverse[3].xyz);
}

vec3 backToClip(vec3 viewpos) { // previous viewpos to previous screen pos
    vec4 tmp = gbufferProjection * vec4(viewpos, 1.0);
    return tmp.xyz / tmp.w;
}

vec3 backToScreen(vec3 viewpos) { // previous viewpos to previous screen pos
    vec4 tmp = gbufferProjection * vec4(viewpos, 1.0);
    return (tmp.xyz / tmp.w) * 0.5 + 0.5;
}


vec3 toPrevPlayer(vec3 worldpos) { // Worldpos to previous playerfeetpos
    return worldpos - previousCameraPosition;
}

vec3 toPrevView(vec3 prevplayerpos) { // previous playerfeetpos to previous viewpos
    return mat3(gbufferPreviousModelView) * (prevplayerpos - gbufferModelViewInverse[3].xyz);
}

vec3 toPrevScreen(vec3 prevviewpos) { // previous viewpos to previous screen pos
    vec4 tmp = gbufferPreviousProjection * vec4(prevviewpos, 1.0);
    return (tmp.xyz / tmp.w) * 0.5 + 0.5;
}


vec3 previousReproject(vec3 clipPos) {
    // Project to World Space
    vec3 pos = toView(clipPos);
    pos      = toPlayer(pos);
    pos      = toWorld(pos);

    // Project to previous Screen Space
    pos      = toPrevPlayer(pos);
    pos      = toPrevView(pos);
    return     toPrevScreen(pos);
}

vec3 screenSpaceMovement(vec3 clipPos) {
    // Project to World Space
    vec3 pos = toView(clipPos);
    pos      = toPlayer(pos);
    pos      = toWorld(pos);

    // Project to previous Screen Space
    pos      = toPrevPlayer(pos);
    pos      = backToView(pos);
    return     backToScreen(pos);
}
vec3 screenSpaceMovement(vec3 clipPos, vec3 weight) {
    // Project to Player Space
    vec3 pos = toView(clipPos);
    pos      = toPlayer(pos);

    // Calculate World Space
    pos      += (cameraPosition - previousCameraPosition) * 1;

    // Project to previous Screen Space
    pos      = backToView(pos);
    return     backToScreen(pos);
}