uniform float normalizedTime;
uniform float customStarBlend;

float starVoronoi(vec2 coord, float maxDeviation) {
    vec2 guv = fract(coord) - 0.5;
    vec2 gid = floor(coord);
	vec2 p   = (rand2(gid) - 0.5) * maxDeviation; // Get Point in grid cell
	float d  = sqmag(p-guv);                    // Get distance to that point
    return d;
}
vec2 starVoronoi_getCoord(vec2 coord, float maxDeviation) {
    vec2 gid = floor(coord);
	vec2 p   = (rand2(gid) - 0.5) * maxDeviation; // Get Point in grid cell
    return p + gid + 0.5;
}

float shootingStar(vec2 coord, vec2 dir, float thickness, float slope) {
	dir    *= 0.9;
	vec2 pa = coord + (dir * 0.5);
    float t = saturate(dot(pa, dir) * ( 1. / dot(dir,dir) ) );
    float d = sqmag(dir * -t + pa);
    return saturate((thickness - d) * slope + 1) * t;
}

vec4 getStars(vec3 playerPos, vec3 playerDir) {
    float starMask = smoothstep(-0.2, 1, playerDir.y); 
    if (customStarBlend < 1e-6 || starMask == 0) return vec4(vec3(1), 0);

    // STARS
    const mat2 skyRot = MAT2_ROT(sunPathRotation * (PI/180.), 1);
    vec3  skyDir      = vec3(playerDir.x, skyRot * playerDir.yz);
    skyDir            = vec3(mat2Rot(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
    vec2  skyCoord    = octahedralEncode(skyDir);

    vec2  vinput    = skyCoord * STAR_DENSITY;
    vec2  vcoord    = starVoronoi_getCoord(vinput, 0.9);
    vec3  vdir      = octahedralDecode(vcoord / STAR_DENSITY);
    float starNoise = sqmag(skyDir - vdir) * 75;

    float stars     = fstep(starNoise, (STAR_SIZE * 1e-4 * STAR_DENSITY), 5e3);
    stars          *= fstep(noise(skyCoord * 10), STAR_COVERAGE, 2);
    stars          *= starMask;

#ifdef SHOOTING_STARS

    // SHOOTING STARS //
    vec2 shootingStarCoord = normalize(playerPos * vec3(1,2,1)).xz * shooting_stars_length;

    const vec2 lineDir = vec2(sin(SHOOTING_STARS_ANGLE * TWO_PI), cos(SHOOTING_STARS_ANGLE * TWO_PI));
    shootingStarCoord -= frameTimeCounter * vec2(lineDir * 2 * SHOOTING_STARS_SPEED);
    vec2  gridID       = floor(shootingStarCoord);
    vec2  gridUV       = fract(shootingStarCoord) - 0.5;
    
    float shootingStars = shootingStar(gridUV, lineDir, (9e-8 * shooting_stars_thickness), (5e5 / shooting_stars_thickness));
    shootingStars      *= fstep(shooting_stars_density, rand(gridID));

    float shootingStarMask = saturate(playerDir.y * 2 - 0.3);
    shootingStars         *= shootingStarMask;

    stars = saturate(stars + shootingStars);

#endif

    return vec4(vec3(1), stars * customStarBlend);
}