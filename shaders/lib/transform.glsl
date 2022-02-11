uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

float fovScale = gbufferProjection[1][1] * 0.7299270073;

vec3 toView(vec3 clippos) { // Clippos to viewpos
    return unprojectPerspectiveMAD(clippos, gbufferProjectionInverse);
}

vec3 toPlayer(vec3 viewspace) { // Viewpos to Playerfeetpos
    return mat3(gbufferModelViewInverse) * viewspace + gbufferModelViewInverse[3].xyz;
}
vec3 toPlayerEye(vec3 viewspace) { // Viewpos to Playereyepos
    return mat3(gbufferModelViewInverse) * viewspace;
}
vec3 playerEyeToFeet(vec3 playereye) {
    return playereye + gbufferModelViewInverse[3].xyz;
}

vec3 toWorld(vec3 playerpos) { // Playerfeetpos to worldpos
    return playerpos + cameraPosition;
}


vec3 backToPlayer(vec3 worldpos) { // Worldpos to playerfeetpos
    return worldpos - cameraPosition;
}

vec3 backToView(vec3 playerpos) { // playerfeetpos to viewpos
    return mat3(gbufferModelView) * (playerpos - gbufferModelViewInverse[3].xyz);
}
vec3 eyeToView(vec3 playereye) {
    return mat3(gbufferModelView) * playereye;
}

vec3 backToClip(vec3 viewpos) { // viewpos to clip pos
    return projectPerspectiveMAD(viewpos, gbufferProjection);
}

vec4 backToClipW(vec3 viewpos) { // viewpos to clip pos
    vec4 tmp = projectHomogeneousMAD(viewpos, gbufferProjection);
    return vec4(tmp.xyz / tmp.w, tmp.w);
}

vec3 backToScreen(vec3 viewpos) { // viewpos to screen pos
    return projectPerspectiveMAD(viewpos, gbufferProjection) * 0.5 + 0.5;
}


vec3 toPrevPlayer(vec3 worldpos) { // Worldpos to previous playerfeetpos
    return worldpos - previousCameraPosition;
}

vec3 toPrevView(vec3 prevplayerpos) { // previous playerfeetpos to previous viewpos
    return mat3(gbufferPreviousModelView) * prevplayerpos + gbufferPreviousModelView[3].xyz;
}
vec3 eyeToPrevView(vec3 prevplayereye) { // previous playereyepos to previous viewpos
    return mat3(gbufferPreviousModelView) * prevplayereye;
}

vec3 toPrevClip(vec3 prevviewpos) { // previous viewpos to previous screen pos
    return projectPerspectiveMAD(prevviewpos, gbufferPreviousProjection);
}
vec3 toPrevScreen(vec3 prevviewpos) { // previous viewpos to previous screen pos
    return projectPerspectiveMAD(prevviewpos, gbufferPreviousProjection) * 0.5 + 0.5;
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
vec3 previousReprojectClip(vec3 clipPos) {
    // Project to World Space
    vec3 pos = toView(clipPos);
    pos      = toPlayer(pos);
    pos      = toWorld(pos);

    // Project to previous Screen Space
    pos      = toPrevPlayer(pos);
    pos      = toPrevView(pos);
    return     toPrevClip(pos);
}

vec3 reprojectTAA(vec3 screenPos) {
    if (screenPos.z < 0.56) return screenPos;

    // Project to World Space
    vec3 pos = toView(screenPos * 2 - 1);
    pos      = toPlayer(pos);
    pos      = toWorld(pos);

    // Project to previous Screen Space
    pos      = toPrevPlayer(pos);
    pos      = toPrevView(pos);
    return     toPrevScreen(pos);
}

vec2 motionBlur(vec3 screenPos) {
    if (screenPos.z < 0.56) return vec2(0);
    
    vec3 prevScreenPos = toPrevScreen(toPrevView(toPrevPlayer(toWorld(toPlayer(toView(screenPos * 2 - 1))))));
    vec2 motionVector  = screenPos.xy - prevScreenPos.xy;
    motionVector      /= length(motionVector) + 0.5; //Basically Reinhard Tonemapping (but on motion blur lol)
	
    return motionVector * (0.1 * MOTION_BLUR_STRENGTH);
}
