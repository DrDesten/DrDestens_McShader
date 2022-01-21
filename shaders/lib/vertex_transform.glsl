uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

vec3 getNormal() {
    return normalize(gl_NormalMatrix * gl_Normal);
}

vec2 getCoord() {
    return mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;
}

vec2 getLmCoord() {
    return gl_MultiTexCoord1.xy * (1./256);
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
vec3 viewToClip(vec3 viewPos) {
    return mat3(gl_ProjectionMatrix) * viewPos + gl_ProjectionMatrix[3].xyz;
}
vec4 viewToClip(vec4 viewPos) {
    return gl_ProjectionMatrix * viewPos;
}
vec3 toPlayer(vec3 viewPos) {
    return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
}
vec4 toPlayer(vec4 viewPos) {
    return gbufferModelViewInverse * viewPos;
}



vec3 getPlayer() {
    return mat3(gbufferModelViewInverse) * getView() + gbufferModelViewInverse[3].xyz;
}
vec4 getPlayer4() {
    return gbufferModelViewInverse * getView4();
}
vec3 playerToView(vec3 playerPos) {
    return transformMAD(playerPos, gbufferModelView);
}
vec4 playerToView(vec4 playerPos) {
    return gbufferModelView * playerPos;
}
vec4 playerToClip(vec4 playerPos) {
    return projectHomogeneousMAD(transformMAD(playerPos.xyz, gbufferModelView), gl_ProjectionMatrix);
}
/* vec4 playerToClip(vec4 playerPos) {
    return gl_ProjectionMatrix * (gbufferModelView * playerPos);
} */



vec3 getWorld() {
    return getPlayer() + cameraPosition;
}
vec4 worldToClip(vec3 worldPos) {
    return playerToClip(vec4(worldPos - cameraPosition, 1));
}


float getID(vec4 entityAttribute) {
    return entityAttribute.x - 1000;
}
float getID(int entityId) {
    return float(entityId - 1000);
}