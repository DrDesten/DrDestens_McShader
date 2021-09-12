//requires: uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float lightBrightness;

vec3 lightPosition() {
    return (worldTime > 13000 && worldTime < 22500) ? moonPosition : sunPosition;
}
vec3 lightPosition(out bool daynight) {
    daynight = !(worldTime > 13000 && worldTime < 22500);
    return daynight ? sunPosition : moonPosition;
}

float NDF_GGX(float NdotH, float alpha) {
    float a2     = alpha * alpha;
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
float G_Smith(float NdotL, float NdotV, float k) {
    float lightObstrction = GO_SchlickGGX(NdotL, k);
    float viewObstruction = GO_SchlickGGX(NdotV, k);
    return lightObstrction * viewObstruction;
}
float G_Phong(float NdotL, float NdotV, float k) {
    return NdotL * NdotV;
}

// Fresnel function (Schlick)
float Fresnel(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
vec3 Fresnel(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec4 CookTorrance(vec3 albedo, vec3 N, vec3 V, vec3 L, float roughness, vec3 f0, float specular) {
    vec3  H     = normalize(V + L);
    float NdotH = clamp(dot(N, H), 0, 1);
    float NdotL = clamp(dot(N, L), 0, 1);
    float NdotV = clamp(dot(N, V), 0, 1);

    float radiance = 5;

    float k = sq(roughness + 1) / 8;

    float D = NDF_GGX(NdotH, roughness);
    float G = G_Smith(NdotL, NdotV, k);
    vec3  F = Fresnel(NdotH, f0);

    vec3 kS = F;
    vec3 kD = 1 - kS;
    //kD *= 1 - metallic;

    vec3  zaehl = D * G * F;
    float nenn  = 4 * NdotV * NdotL;
    vec3  spec  = zaehl / max(nenn, 0.001) * specular;
    spec        = min(spec, 5);

    vec3  BRDF  = (kD * albedo / PI + spec) * radiance * NdotL;
    
    float reflectiveness = Fresnel(NdotV, (f0.r + f0.g + f0.b) * 0.33333333333) /* / (spec.g + 1) */;

    return vec4(BRDF, reflectiveness);
}
vec4 CookTorrance_diffonly(vec3 albedo, vec3 N, vec3 V, vec3 L, float roughness, vec3 f0, float specular) {
    float NdotL = clamp(dot(N, L), 0, 1);
    float NdotV = clamp(dot(N, V), 0, 1);

    float radiance = 5;
    vec3  BRDF     = (albedo / PI) * radiance * NdotL;
    
    float reflectiveness = Fresnel(NdotV, (f0.r + f0.g + f0.b) * 0.33333333333);

    return vec4(BRDF, reflectiveness);
}

vec3 simpleSubsurface(vec3 albedo, vec3 N, vec3 V, vec3 L, float subsurface) {
    float through = clamp(dot(-V, L), 0, 1);
    through       = pow(through, 15);
    float diff    = clamp(-dot(N, L), 0, 1) * 0.5;

    float subsurf = (diff + through) * subsurface * 0.5;

    return subsurf * albedo;
}
vec3 simpleSubsurface2(vec3 albedo, vec3 N, vec3 V, vec3 L, float subsurface) {
    float diffExpand = dot(N, L);
    diffExpand      *= diffExpand;
    diffExpand       = diffExpand * 0.15 + 0.1;

    float through = clamp(dot(-V, L), 0, 1);
    through       = pow(through, 10) * 0.75;

    return (diffExpand + through) * subsurface * albedo;
}

// TBN MATRIX CALCULATION ///////////////////////////////////////////////////////////////
mat3 cotangentFrame( vec3 N, vec3 p, vec2 coord ) {

    // http://www.thetenthplanet.de/archives/1180 by Christian Schüler
    // Constructs the TBN (Tangent-Binomial-Normal) Matrix without Tangent

    // get edge vectors of the pixel triangle 
    vec3 dp1  = dFdx( p );
    vec3 dp2  = dFdy( p );
    vec2 duv1 = dFdx( coord );
    vec2 duv2 = dFdy( coord );

    // solve the linear system 
    vec3 dp2perp = cross( dp2, N );
    vec3 dp1perp = cross( N, dp1 );
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;   
    
    // construct a scale-invariant frame 
    float invmax = 1 / sqrt( max( dot(T,T), dot(B,B) ) );

    return mat3( T * invmax, B * invmax, N );

}

vec3 nkTof0(vec3 n, vec3 k) {
    //      (n - 1)² + k²
    // f0 = -------------
    //      (n + 1)² + k²
    vec3 k2 = k*k;
    return (sq(n - 1) + k2) / (sq(n + 1) + k2);
}






// FULL PBR MATERIAL FUNCTION ///////////////////////////////////////////////////////////////

struct PBRout {
	vec4  color;
	vec3  normal;
	float reflectiveness;
};

PBRout PBRMaterial(MaterialInfo tex, vec3 default_render_color, vec2 lmcoord, mat3 tbn, vec3 viewpos, vec3 ambient) {
    
	vec3  lightPos	 = lightPosition();
    vec4  color      = tex.color;

    // Specular Blending Factor (Removes specular highlights in occluded areas)
    float specBlend  = clamp(mix( -1.5, 1, lmcoord.y ), 0, 1); 
    // Total BRDF brightness
    float brightness = sq(sq(lmcoord.y)) * tex.AO * lightBrightness;

    vec3  normalMap  = tex.normal;
	vec3  normal     = normalize(tbn * normalMap);

	float AO 		 = tex.AO;
    #ifdef HEIGHT_AO
		AO          *= sq(tex.height);
	#endif

	float roughness  = tex.roughness;
	vec3  f0 		 = tex.f0;

    float subsurf    = tex.subsurface;
    float porosity   = tex.porosity;

	float emission   = tex.emission * 4;

    vec3  lightDir   = normalize(lightPos);
    vec3  viewDir    = normalize(-viewpos);

    // Get PBR Material
    #ifdef OVERWORLD
	 vec4 BRDF		 = CookTorrance(color.rgb, normal, viewDir, lightDir, roughness, f0, specBlend);
    #else
	 vec4 BRDF	     = CookTorrance_diffonly(color.rgb, normal, viewDir, lightDir, roughness, f0, specBlend);
    #endif

    BRDF.rgb        *= brightness; //Reduce brightness at night and according to minecrafts abient light
    
    #ifdef SUBSURAFCE_SCATTERING
     if (subsurf >= 0.1) {
        vec3 SSSc   = simpleSubsurface2(color.rgb, normal, viewDir, lightDir, subsurf) * brightness;
        BRDF.rgb   += SSSc;
     }
    #endif

    // Emission and Ambient Light
	BRDF.rgb 		 += color.rgb * ((ambient * AO * PBR_AMBIENT_LIGHT_MULTIPLIER) + emission);

	// Blend between normal MC rendering and PBR rendering
	color.rgb 	     = mix(default_render_color, BRDF.rgb, PBR_BLEND);
	BRDF.a 	    	 = mix(0, BRDF.a, PBR_BLEND);
	
	float reflectiveness = BRDF.a * clamp(0.9 - 2 * (roughness + emission), 0, 1);

    color.rgb = max(color.rgb, 0); // Prevent Negative values

	PBRout Material  = PBRout(color, normal, reflectiveness);
	return Material;

}


float DynamicLight(vec2 lmcoord) {
    return lmcoord.x * lmcoord.x;
}