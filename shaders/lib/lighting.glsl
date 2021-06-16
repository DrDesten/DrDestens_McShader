//#define PBR

#define PBR_BLEND_MIN 0.25 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define PBR_BLEND_MAX 0.85 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

#define HEIGHT_AO

//requires: uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

vec3 lightPosition() {
    if (worldTime > 13500 && worldTime < 22500) { // Night
        return moonPosition;
    } else { //Day
        return sunPosition;
    }
}


vec3 halfway(vec3 viewPos, vec3 lightPos) {
    return normalize(viewPos + lightPos);
}


// Normal distribution function (GGXTR)
float D(vec3 normal, vec3 halfway, float roughness) {
    float a      = roughness;// * roughness;
    float a2     = a * a;
    float NdotH  = max(dot(normal, halfway), 0.0);
    float NdotH2 = NdotH * NdotH;
    
    float nenner = NdotH2 * (a2 - 1) + 1;
    nenner       = PI * nenner * nenner;

    return a2 / nenner;
}
// Geometry Obstruction function (Schlick-GGX)
float GSchlickGGX(float NdotV, float roughness) {
    // Convert roughness to alpha and then k
    float alpha = (roughness + 1.0);
    float k = (alpha*alpha) / 8.0;

    float nenner = NdotV * (1.0 - k) + k;
    return NdotV / nenner;
}
float G(vec3 normal, vec3 viewVector, vec3 lightVector, float roughness) {
    float NdotV           = max(dot(normal, viewVector), 0);
    float viewObstruction = GSchlickGGX(NdotV, roughness);

    float NdotL           = max(dot(normal, lightVector), 0);
    float lightObstrction = GSchlickGGX(NdotL, roughness);
	
    return lightObstrction * viewObstruction;
}
// Fresnel function (Schlick)
float F(float NormalDotView, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - NormalDotView, 5.0);
}
vec3 F(float NormalDotView, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - NormalDotView, 5.0);
}

// Combined DGF Function for PBR lighting
float DGF(vec3 normal, vec3 viewDir, vec3 lightVector, float roughness, float F0) {
    float NormDistribution    = D(normal, normalize(viewDir + normalize(lightVector)), roughness);
    float GeometryObstruction = G(normal, viewDir, lightVector, roughness);
    float Fresnel             = F(dot(normal, viewDir), F0);

    return NormDistribution * GeometryObstruction * Fresnel;
}


// Cook-Torrance Specular BRDF
vec4 specularBRDF(vec3 color, vec3 normal, vec3 viewPos, vec3 lightVector, float roughness, float F0) {
    const float PI = 3.14159265359;

    vec3  viewDir             = -normalize(viewPos);
    float NormDistribution    = D(normal, normalize(viewDir + normalize(lightVector)), roughness);
    float GeometryObstruction = G(normal, viewDir, lightVector, roughness);
    float Fresnel             = F(dot(normal, viewDir), F0);

    float zaehler  = NormDistribution * GeometryObstruction * Fresnel;
    float nenner   = 4.0 * max(dot(normal, viewDir), 0.0) * max(dot(normal, normalize(lightVector)), 0.0);
    float specular = zaehler / max(nenner, 0.01);

    vec3  kS = vec3(Fresnel); // Specular Energy
    vec3  kD = vec3(1) - kS;  // Diffuse Energy

    float NdotL    = max(dot(normal, normalize(lightVector)), 0.0);
    vec3  radiance = (kD * color / PI + specular) * NdotL;

    return vec4(max(radiance, 0), Fresnel);
}

// Cook-Torrance Specular BRDF (Metallic)
/* vec3 specularBRDF(vec3 color, vec3 normal, vec3 viewPos, vec3 lightVector, float roughness, vec3 F0) {
    const float PI = 3.14159265359;

    vec3  viewDir             = -normalize(viewPos);
    float NormDistribution    = D(normal, normalize(viewDir + normalize(lightVector)), roughness);
    float GeometryObstruction = G(normal, viewDir, lightVector, roughness);
    vec3  Fresnel             = F(dot(normal, viewDir), F0);

    vec3  zaehler  = NormDistribution * GeometryObstruction * Fresnel;
    float nenner   = 4.0 * max(dot(normal, viewDir), 0.0) * max(dot(normal, normalize(lightVector)), 0.0);
    vec3  specular = zaehler / max(nenner, 0.01);

    vec3  kS = Fresnel; // Specular Energy
    vec3  kD = vec3(1) - kS;  // Diffuse Energy

    float NdotL    = max(dot(normal, normalize(lightVector)), 0.0);
    vec3  radiance = (kD * (color / PI) + specular) * NdotL;

    return max(radiance, 0);
} */
