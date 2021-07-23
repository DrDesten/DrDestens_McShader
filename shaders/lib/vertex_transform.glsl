uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

attribute vec4 at_tangent;

vec3 getNormal() {
    return normalize(gl_NormalMatrix * gl_Normal);
}

vec2 getCoord() {
    return (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

vec2 getLmCoord() {
    return (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}

mat3 getTBN() {
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent = normalize(gl_NormalMatrix * (at_tangent.xyz / at_tangent.w));
	return mat3(tangent, cross(tangent, normal), normal);
}

vec3 getView() {
    return (gl_ModelViewMatrix * gl_Vertex).xyz;
}
vec4 getView4() {
    return gl_ModelViewMatrix * gl_Vertex;
}

vec4 getPlayer() {
    return gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
}


vec4 toPlayer(vec4 viewPos) {
    return gbufferModelViewInverse * viewPos;
}

vec4 worldToClip(vec4 worldPos) {
    return gl_ProjectionMatrix * (gbufferModelView * worldPos);
}