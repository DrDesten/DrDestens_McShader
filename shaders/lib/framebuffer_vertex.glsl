
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

