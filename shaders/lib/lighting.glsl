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
vec3 specularBRDF(vec3 color, vec3 normal, vec3 viewPos, vec3 lightVector, float roughness, float F0) {
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

    return max(radiance, 0);
}

// Cook-Torrance Specular BRDF (Metallic)
vec3 specularBRDF(vec3 color, vec3 normal, vec3 viewPos, vec3 lightVector, float roughness, vec3 F0) {
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
}
