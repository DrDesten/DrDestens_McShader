//requires: uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

vec3 lightPosition() {
    return (worldTime > 13500 && worldTime < 22500) ? moonPosition : sunPosition;
}

float NDF_GGX(vec3 normal, vec3 halfway, float alpha) {
    float a2     = alpha * alpha;
    float NdotH  = clamp(dot(normal, halfway), 0, 1);
    float NdotH2 = NdotH * NdotH;
    
    float nenner = NdotH2 * (a2 - 1) + 1;
    nenner       = PI * nenner * nenner;

    return a2 / nenner;
}

float GO_SchlickGGX(float dot_product, float k) {
	return dot_product / (dot_product * (1-k) + k);
}
float G_Smith(vec3 normal, vec3 view, vec3 light, float k) {
    float NdotV           = clamp(dot(normal, view), 0, 1);
    float viewObstruction = GO_SchlickGGX(NdotV, k);

    float NdotL           = clamp(dot(normal, light), 0, 1);
    float lightObstrction = GO_SchlickGGX(NdotL, k);
	
    return lightObstrction * viewObstruction;
}

// Fresnel function (Schlick)
float F(float NormalDotView, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - NormalDotView, 5.0);
}
vec3 F(float NormalDotView, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - NormalDotView, 5.0);
}


/*     // Cook-Torrance Specular BRDF
    vec4 specularBRDF(vec3 color, vec3 normal, vec3 viewPos, vec3 lightVector, float roughness, float F0) {
        const float PI = 3.14159265359;

        vec3  viewDir             = -normalize(viewPos);
        float NormDistribution    = D(normal, normalize(viewDir + normalize(lightVector)), roughness);
        float GeometryObstruction = G(normal, viewDir, lightVector, roughness);
        float Fresnel             = F(dot(normal, viewDir), F0);

        float zaehler  = NormDistribution * GeometryObstruction * Fresnel;
        float nenner   = 4.0 * max(dot(normal, viewDir), 0.0) * max(dot(normal, normalize(lightVector)), 0.0);
        float specular = zaehler / max(nenner, 0.01);

        vec3  kS = vec3(0); // Specular Energy
        vec3  kD = vec3(1) - kS;  // Diffuse Energy

        float NdotL    = max(dot(normal, normalize(lightVector)), 0.0);
        vec3  radiance = (kD * color / PI + specular) * (NdotL);

        return vec4(max(radiance, 0), Fresnel);
    }

    // Cook-Torrance Specular BRDF (Metallic)
    vec4 specularBRDF(vec3 color, vec3 normal, vec3 viewPos, vec3 lightVector, float roughness, vec3 F0) {
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

        return vec4(max(radiance, 0), sum(Fresnel) * .3333333);
    }
*/

vec4 CookTorrance(vec3 albedo, vec3 normal, vec3 viewPos, vec3 light, float roughness, vec3 f0, float specular) {
    vec3 V = normalize(-viewPos);
    vec3 L = normalize(light);
    vec3 H = normalize(V + L);

    float radiance = 3;

    float k = sq(roughness + 1) / 8;

    float D = NDF_GGX(normal, H, roughness);
    float G = G_Smith(normal, V, L, k);
    vec3  F = F(max(dot(H, V), 0), f0);

    vec3 kS = F;
    vec3 kD = 1 - kS;
    //kD *= 1 - metallic;

    vec3  zaehl = D * G * F;
    float nenn  = 4 * max(dot(normal, V), 0.0) * max(dot(normal, L), 0.0);
    vec3  spec  = zaehl / max(nenn, 0.001) * specular;
    spec        = min(spec, 1);

    vec3  BRDF  = (kD * albedo / PI + spec) * radiance * max(dot(normal, L), 0.0);

    return vec4(BRDF, F);
}



// TBN MATRIX CALCULATION ///////////////////////////////////////////////////////////////
mat3 cotangentFrame( vec3 N, vec3 p, vec2 coord ) {

    // http://www.thetenthplanet.de/archives/1180 by Christian Schüler
    // Constructs the TBN (Tangent-Binomial-Normal) Matrix without Tangent

    // get edge vectors of the pixel triangle 
    vec3 dp1 = dFdx( p );
    vec3 dp2 = dFdy( p );
    vec2 duv1 = dFdx( coord );
    vec2 duv2 = dFdy( coord );

    // solve the linear system 
    vec3 dp2perp = cross( dp2, N );
    vec3 dp1perp = cross( N, dp1 );
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;   
    
    // construct a scale-invariant frame 
    float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );

    return mat3( T * invmax, B * invmax, N );

}






// FULL PBR MATERIAL FUNCTION ///////////////////////////////////////////////////////////////

struct PBRout {
	vec4 color;
	vec3 normal;
	float reflectiveness;
};

/* PBRout PBRMaterial(vec2 coord, vec2 lmcoord, vec4 color, mat3 tbn, vec3 viewpos) {
    vec4 origColor   = color;

	vec3 lightPos	 = lightPosition();

	vec4 normalTex	 = NormalTex(coord);
	vec4 specularTex = SpecularTex(coord);

	#ifdef HEIGHT_AO
		float height = extractHeight(normalTex, specularTex);
		color.rgb   *= height;
	#endif

	vec3  normal     = normalize(tbn * extractNormal(normalTex, specularTex));
	float AO 		 = extractAO(normalTex, specularTex);

	float roughness  = extractRoughness(normalTex, specularTex);
	float f0 		 = extractF0(normalTex, specularTex);
	if (f0 > 229.5/255) { f0 = 1;}
	float emission   = extractEmission(normalTex, specularTex);

	color.rgb 		*= AO;
	vec4 BRDF		 = CookTorrance(color.rgb, normal, viewpos, lightPos, roughness, vec3(f0)) * (float(lightPos == sunPosition) * 0.9 + 0.1); //Reduce brightness at night
	BRDF.rgb 		+= origColor.rgb * emission * 2;

	// Blend between normal MC rendering and PHYSICALLY_BASED rendering
	    //float blend      = clamp(f0 + PBR_BLEND_MIN, 0, PBR_BLEND_MAX);
    float blend      = PBR_BLEND_MIN;
    float lmblend    = clamp((lmcoord.y - .1) * 10, 0, 1); // No sunlight underground

	color.rgb 	     = mix(color.rgb, BRDF.rgb, blend * lmblend);
	BRDF.a 	    	 = mix(0, BRDF.a, blend);
	
	float reflectiveness = BRDF.a * max(1 - 2 * roughness, 0);
    #ifdef PBR_REFLECTION_REALISM
    if (f0 == 1) {
        reflectiveness = 1;
        color          = origColor;
        color.rgb     += clamp(BRDF.rgb - 1, 0, 1) * lmblend;
    }    
    #endif
    

	PBRout Material  = PBRout(color, normal, reflectiveness);
	return Material;
    
} */

PBRout PBRMaterial(vec2 coord, vec2 lmcoord, vec4 color, mat3 tbn, vec3 viewpos, vec3 ambient) {
    
    vec4  origColor  = color;

    float sunBright  = lmcoord.y; // Specular Blending Factor
    sunBright        = clamp(mix(-1.5,1,sunBright), 0, 1);

	vec3 lightPos	 = lightPosition();
	vec4 normalTex	 = NormalTex(coord);
	vec4 specularTex = SpecularTex(coord);

    vec3  normal_map = extractNormal(normalTex, specularTex);
	vec3  normal     = normalize(tbn * normal_map);

	float AO 		 = extractAO(normalTex, specularTex);
    #ifdef HEIGHT_AO
		float height = extractHeight(normalTex, specularTex);
		AO          *= height;
	#endif

	float roughness  = extractRoughness(normalTex, specularTex);
	vec3  f0 		 = vec3(extractF0(normalTex, specularTex));
	if (f0.x > 229.5/255) { f0 = origColor.rgb;}

	float emission   = extractEmission(normalTex, specularTex);

    // Get PBR Material
	vec4 BRDF		 = CookTorrance(color.rgb, normal, viewpos, lightPos, roughness, f0, sunBright) * (lightPos == sunPosition ? 1.0 : 0.3) * lmcoord.y; //Reduce brightness at night and according to minecrafts abient light

    // Emission and Ambient Light
	BRDF.rgb 		+= origColor.rgb * emission * 2;
    BRDF.rgb        += origColor.rgb * ambient  * AO;

	// Blend between normal MC rendering and PHYSICALLY_BASED rendering
    float blend      = PBR_BLEND_MIN;
	color.rgb 	     = mix(color.rgb, BRDF.rgb, blend);
	BRDF.a 	    	 = mix(0, BRDF.a, blend);
	
	float reflectiveness = BRDF.a * max(1 - 2 * roughness, 0);

    color.rgb = max(color.rgb, 0); // Preventing Negative values

	PBRout Material  = PBRout(color, normal, reflectiveness);
	return Material;

}


float DynamicLight(vec2 lmcoord) {
    return lmcoord.x * lmcoord.x;
}