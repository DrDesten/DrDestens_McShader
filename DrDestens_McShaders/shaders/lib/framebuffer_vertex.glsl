
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

/* Long code
vec4 vertPos  = gl_Vertex;
vec4 viewPos  = gl_ModelViewMatrix * vertPos;
vec4 playerPos = gbufferModelViewInverse * viewPos; 
*/
vec4 vertexPlayer() {
    return gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
}

vec4 vertexWorldToClip(vec4 vertex) {
    return gl_ProjectionMatrix * (gbufferModelView * vertex);
}







////////////////////////////////////////////////////////////////////////
// Randomization and Dither Patterns

const float PHI = 1.61803398874989484820459;
float randf_01(vec2 xy){
    xy = fract(xy);
    return fract(dot(xy, xy * PHI) * 324975.689);
}

float rand_01(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
float rand_11(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) * 2 - 1;
}
