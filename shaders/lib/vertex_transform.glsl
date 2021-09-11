uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

vec3 getNormal() {
    return normalize(gl_NormalMatrix * gl_Normal);
}

vec2 getCoord() {
    return mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;
}

vec2 getLmCoord() {
    return mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.xy + gl_TextureMatrix[1][3].xy;
}

mat3 getTBN(vec4 tangentAttribute) {
	vec3 normal  = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent = normalize(gl_NormalMatrix * (tangentAttribute.xyz / tangentAttribute.w));
	return mat3(tangent, cross(tangent, normal), normal);
}

vec3 getView() {
    return mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
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

vec4 playerToClip(vec4 playerPos) {
    return gl_ProjectionMatrix * (gbufferModelView * playerPos);
}