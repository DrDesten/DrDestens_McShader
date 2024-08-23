#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"

#ifdef PBR
#include "/lib/pbr/pbr.glsl"
#include "/lib/pbr/read.glsl"
#include "/lib/pbr/ambient.glsl"
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
#include "/lib/sky.glsl"

uniform float normalizedTime;
uniform float customStarBlend;
uniform float frameTimeCounter;
uniform vec3 sunDir;

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

//////////////////////////////////////////////////////////////////////////////
//                     SKY RENDERING
//////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
    float depth     = getDepth(coord);
    vec3  screenPos = vec3(coord, depth);
    vec3  color     = getAlbedo(coord);
    
    if (depth == 1) { // SKY

#ifdef OVERWORLD

        vec3 viewPos   = toView(screenPos * 2 - 1);
        vec3 viewDir   = normalize(viewPos);
        vec3 playerPos = toPlayer(viewPos);
        vec3 playerDir = normalize(playerPos);

        vec3  skyGradient = getSky(playerPos);
        float starMask    = smoothstep(-0.2, 1, playerDir.y); 

		if (customStarBlend > 1e-6 && starMask > 0) {

			// STARS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
			// SHOOTING STARS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

			// mix: <color> with <starcolor>, depending on <is there a star?> and <is it night?> and <is it blocked by sun or moon?>
			skyGradient = mix(skyGradient, vec3(1), stars * customStarBlend * saturate(abs(dot(viewDir, sunDir)) * -200 + 199));
		}

		color += skyGradient;
#else
        color = getSky(toPlayerEye(toView(screenPos * 2 - 1)));
#endif

    } else { // NO SKY

#ifdef PBR

        MaterialTexture material = getPBR(ivec2(gl_FragCoord.xy));

        color *= getAmbientLight(material.lightmap, material.ao);

#endif

    }
    
    FragOut0 = vec4(color, 1.0);
}