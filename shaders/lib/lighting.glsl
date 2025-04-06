#include "uniforms/lighting.glsl"

float NDF_GGX(float NdotH, float alpha) {
    float a2     = alpha * alpha;
    float NdotH2 = NdotH * NdotH;
    
    float div = NdotH2 * (a2 - 1) + 1;
    div       = PI * div * div;

    return a2 / div;
}

float GO_SchlickGGX(float dot_product, float k) {
	return dot_product / (dot_product * (1-k) + k);
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

vec3 CookTorrance(vec3 albedo, vec3 N, vec3 V, vec3 L, float roughness, vec3 f0, float specular) {
    vec3  H     = normalize(V + L);
    float NdotH = saturate(dot(N, H));
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));

    float radiance = 7;

    float k = sq(roughness + 1) / 8;

    float D = NDF_GGX(NdotH, roughness);
    float G = G_Smith(NdotL, NdotV, k);
    vec3  F = Fresnel(NdotH, f0);

    vec3 kS = F;
    vec3 kD = 1 - kS;
    //kD *= 1 - metallic;

    vec3  num   = D * G * F;
    float div   = 4 * NdotV * NdotL;
    vec3  spec  = num / max(div, 0.01) * specular;
    spec        = min(spec, 5);

    vec3  BRDF  = (kD * albedo / PI + spec) * radiance * NdotL;
    return BRDF;
}
vec3 CookTorrance_diffonly(vec3 albedo, vec3 N, vec3 V, vec3 L, float roughness, vec3 f0, float specular) {
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));

    float radiance = 5;
    vec3  BRDF     = (albedo / PI) * radiance * NdotL;

    return (BRDF);
}

vec3 simpleSubsurface(vec3 albedo, vec3 N, vec3 V, vec3 L, float subsurface) {
    float through = saturate(dot(-V, L));
    through       = pow(through, 15);
    float diff    = saturate(-dot(N, L)) * 0.5;

    float subsurf = (diff + through) * subsurface * 0.5;

    return subsurf * albedo;
}
vec3 simpleSubsurface2(vec3 albedo, vec3 N, vec3 V, vec3 L, float subsurface) {
    float diffExpand = dot(N, L);
    diffExpand      *= diffExpand;
    diffExpand       = diffExpand * 0.2 + 0.1;

    float through = saturate(dot(-V, L));
    through       = pow(through, 7);

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
};

PBRout PBRMaterial(MaterialInfo tex, vec3 default_render_color, vec2 lmcoord, mat3 tbn, vec3 viewpos, vec3 ambient) {
    
	vec3  lightPos	 = lightPosition;
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
	 vec3 BRDF		 = CookTorrance(color.rgb, normal, viewDir, lightDir, roughness, f0, specBlend);
    #else
	 vec3 BRDF	     = CookTorrance_diffonly(color.rgb, normal, viewDir, lightDir, roughness, f0, specBlend);
    #endif

    BRDF.rgb        *= brightness; //Reduce brightness at night and according to minecrafts abient light
    
    #ifdef SUBSURAFCE_SCATTERING
     if (subsurf >= 0.1) {
        vec3 SSSc   = simpleSubsurface2(color.rgb, normal, viewDir, lightDir, subsurf) * brightness;
        BRDF.rgb   += SSSc;
     }
    #endif

    // Emission and Ambient Light
	BRDF.rgb 		+= color.rgb * ((ambient * AO * PBR_AMBIENT_LIGHT_MULTIPLIER) + emission);
    //BRDF.rgb = ambient;

	// Blend between normal MC rendering and PBR rendering
	color.rgb 	     = mix(default_render_color, BRDF.rgb, PBR_BLEND);

    color.rgb = max(color.rgb, 0); // Prevent Negative values

	PBRout Material  = PBRout(color, normal);
	return Material;

}


