#define GAMMA 2.2

vec3 invgamma(inout vec3 col) {
    col = pow(col, vec3(1/GAMMA));
    return col;
}

vec3 gamma(inout vec3 col) {
    col = pow(col, vec3(GAMMA));
    return col;
}