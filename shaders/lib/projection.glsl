
float angle(vec2 v) {
    float ang = HALF_PI - atan(v.x / v.y);
    if(v.y < 0) {ang = ang + PI;}
    return ang;
}

vec2 toEqui(vec3 screenPos) {
    vec3  viewPos   = toView(screenPos * 2 - 1);
    vec3  playerPos = toPlayer(viewPos);
    playerPos       = normalize(playerPos); //normalize

    float lambda = angle(playerPos.xz) / TWO_PI;
    float theta  = playerPos.y * .5 + .5;

    return vec2(lambda, theta);
}
vec3 toEqui3(vec3 screenPos) {
    vec3  viewPos   = toView(screenPos * 2 - 1);
    vec3  playerPos = toPlayer(viewPos);
    float depth     = length(playerPos);
    playerPos       = playerPos / depth; //normalize

    float lambda = angle(playerPos.xz) / TWO_PI;
    float theta  = playerPos.y * .5 + .5;

    return vec3(lambda, theta, depth);
}
vec2 playerToEqui(vec3 playerPos) {
    playerPos       = normalize(playerPos); //normalize

    float lambda = angle(playerPos.xz) / TWO_PI;
    float theta  = playerPos.y * .5 + .5;

    return vec2(lambda, theta);
}
vec3 playerToEqui3(vec3 playerPos) {
    float depth     = length(playerPos);
    playerPos       = playerPos / depth; //normalize

    float lambda = angle(playerPos.xz) / TWO_PI;
    float theta  = playerPos.y * .5 + .5;

    return vec3(lambda, theta, depth);
}

vec3 fromEqui(vec2 equi) {
    // get the view direction XZ back (polar -> cartesian)
    float angleXZ   = equi.x * TWO_PI;
    vec2  viewDirXZ = vec2(cos(angleXZ), sin(angleXZ));

    // get the viewDirection Y back
    float viewDirY = equi.y * 2 - 1;

    // Stich them together
    // Y-Direction has been normalized with the entire playerPos vector, so we can use it as scaling reference
    float XZlength = sqrt(1 - sq(viewDirY)); //Solves s for {1 = x²s² + z²s² + y²}, xyz being viewDir components
    
    vec3 viewDirReconstruct = vec3(viewDirXZ.x * XZlength, viewDirY, viewDirXZ.y * XZlength);
    return viewDirReconstruct;
}
vec3 equiToPlayer(vec3 equi) {
    // get the view direction XZ back (polar -> cartesian)
    float angleXZ     = equi.x * TWO_PI;
    vec2  playerDirXZ = vec2(cos(angleXZ), sin(angleXZ));

    // get the viewDirection Y back
    float playerDirY = equi.y * 2 - 1;

    // Stich them together
    // Y-Direction has been normalized with the entire playerPos vector, so we can use it as scaling reference
    float XZlength = sqrt(1 - sq(playerDirY)); //Solves s for {1 = x²s² + z²s² + y²}, xyz being viewDir components
    
    vec3 viewDirReconstruct = vec3(playerDirXZ.x * XZlength, playerDirY, playerDirXZ.y * XZlength) * equi.z;
    return viewDirReconstruct;
}