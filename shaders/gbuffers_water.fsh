uniform int worldTime;
//uniform vec2 atlasSizeInverse;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/generatePBR.glsl"

uniform float frameTimeCounter;

in float id;

in vec2 coord;
in vec2 lmcoord;
in vec3 worldPos;
in vec3 viewDir;

in vec4 glcolor;
in mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

vec2 worley(vec2 coord, float size, int complexity, float time) {
    vec2 uv  = coord;
    
    // Calculate Grid UVs (Also center at (0,0))
    vec2 guv = fract(uv * size) - .5;
    vec2 gid = floor(uv * size);
    
    float md1 = 1e3;
    float md2 = 2e3;
    
    // Check neighboring Grid cells
    for (int x = -complexity; x <= complexity; x++) {
        for (int y = -complexity; y <= complexity; y++) {
        
            vec2 offset = vec2(x, y);
            
            // Get the id of current cell (pixel cell + offset by for loop)
            vec2 id    = gid + offset;
            // Get the uv difference to that cell (offset has to be subtracted)
            vec2 relUV = guv - offset;
            
            // Get Random Point (adjust to range (-.5, .5))
            vec2 p     = N22(id) - .5;
            p          = vec2(sin(time * p.x), cos(time * p.y)) * .5;
            
            // Calculate Distance bewtween point and relative UVs)
            vec2 tmp   = p - relUV;
            float d    = dot(tmp, tmp);
            
            
            if (md1 > d) {
                md2 = md1;
                md1 = d;
            } else if (md2 > d) {
                md2 = d;
            }
        }
    }

    return vec2(md1, md2);
}
float voronoi(vec2 coord, float size, int complexity, float time) {
    vec2 uv  = coord;
    
    // Calculate Grid UVs (Also center at (0,0))
    vec2 guv = fract(uv * size) - .5;
    vec2 gid = floor(uv * size);
    
    float md1 = 1e3;
    float md2 = 2e3;
    
    float minDistance = 1e3;

    // Check neighboring Grid cells
    for (int x = -complexity; x <= complexity; x++) {
        for (int y = -complexity; y <= complexity; y++) {
        
            vec2 offset = vec2(x, y);
            
            // Get the id of current cell (pixel cell + offset by for loop)
            vec2 id    = gid + offset;
            // Get the uv difference to that cell (offset has to be subtracted)
            vec2 relUV = guv - offset;
            
            // Get Random Point (adjust to range (-.5, .5))
            vec2 p     = N22(id) - .5;
            p          = vec2(sin(time * p.x), cos(time * p.y)) * .5;
            
            // Calculate Distance bewtween point and relative UVs)
            vec2 tmp   = p - relUV;
            float d    = dot(tmp, tmp);
            
            // Select the smallest distance
            
            float h     = smoothstep( 0.0, 2.0, 0.5 + (minDistance-d) * 1.);
            minDistance = mix( minDistance, d, h ); // distance
            
        }
    }

    return 1 - minDistance;
}

vec3 noiseNormals(vec2 coord, float strength) {
    vec2  e = vec2(0.01, 0);
    float C = fbm(coord,        2);
    float R = fbm(coord + e.xy, 2);
    float B = fbm(coord + e.yx, 2);

    vec3 n  = vec3(R-C, B-C, e.x);
    n.xy   *= strength;
    return normalize(n);
}

vec3 waveNormals(vec2 coord, float strength) {
    float t = frameTimeCounter * 5;

    vec2 nCoord = coord * 5;

    vec2  e = vec2(0.01, 0);
    float C = voronoi(coord,        .5, 2, t) + fbm(nCoord,        1);
    float R = voronoi(coord + e.xy, .5, 2, t) + fbm(nCoord + e.xy, 1);
    float B = voronoi(coord + e.yx, .5, 2, t) + fbm(nCoord + e.yx, 1);

    vec3 n  = vec3(R-C, B-C, e.x);
    n.xy   *= strength;
    return normalize(n);
}

/* DRAWBUFFERS:0123 */

void main(){
    vec3  normal = tbn[2];
	vec4  albedo = texture2D(texture, coord, 0) * vec4(glcolor.rgb, 1);

    discard;
    
    gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(lmcoord, vec2(1));
	gl_FragData[3] = vec4(codeID(id), vec3(1));
}