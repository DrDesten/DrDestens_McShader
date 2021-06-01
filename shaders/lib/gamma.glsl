#define GAMMA 2.2

vec3 invgamma(vec3 col) {
    return pow(col, vec3(1/GAMMA));
}

vec3 gamma(vec3 col) {
    return pow(col, vec3(GAMMA));
}