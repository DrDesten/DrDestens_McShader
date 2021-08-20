//requires: uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

vec3 lightPosition() {
    return (worldTime > 13500 && worldTime < 22500) ? moonPosition : sunPosition;
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
float G_Phong(vec3 normal, vec3 view, vec3 light) {
    return clamp(dot(normal, light), 0, 1) * clamp(dot(normal, view), 0, 1);
}

// Fresnel function (Schlick)
float Fresnel(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
vec3 Fresnel(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec4 CookTorrance(vec3 albedo, vec3 N, vec3 V, vec3 L, float roughness, vec3 f0, float specular) {
    vec3 H = normalize(V + L);
    float NdotH = clamp(dot(N, H), 0, 1);

    float radiance = 5;

    float k = sq(roughness + 1) / 8;

    float D = NDF_GGX(NdotH, roughness);
    float G = G_Smith(N, V, L, k);
    //float G = G_Phong(N, V, L);
    vec3  F = Fresnel(NdotH, f0);

    vec3 kS = F;
    vec3 kD = 1 - kS;
    //kD *= 1 - metallic;

    vec3  zaehl = D * G * F;
    float nenn  = 4 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
    vec3  spec  = zaehl / max(nenn, 0.001) * specular;
    spec        = min(spec, 5);

    vec3  BRDF  = (kD * albedo / PI + spec) * radiance * max(dot(N, L), 0.0);
    
    float reflectiveness = Fresnel(dot(N, V), (f0.r + f0.g + f0.b) * 0.33333333333);

    return vec4(BRDF, reflectiveness);
}

vec3 simpleSubsurface(vec3 albedo, vec3 N, vec3 V, vec3 L, float subsurface) {
    float through = clamp(dot(V, L), 0, 1);
    through       = pow(through, 5);
    float diff    = clamp(-dot(N, L), 0, 1);

    float subsurf = (diff + through) * subsurface * 0.25;

    return subsurf * albedo;
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

PBRout PBRMaterial(MaterialInfo tex, vec3 default_render_color, vec2 lmcoord, mat3 tbn, vec3 viewpos, vec3 ambient) {
    
    vec4  origColor  = tex.color;
    vec4  color      = tex.color;

    // Specular Blending Factor (Removes specular highlights in occluded areas)
    float specBlend  = clamp(mix( -1.5, 1, lmcoord.y ), 0, 1); 
    // Total BRDF brightness
    float brightness = pow(lmcoord.y, 4) * tex.AO;

	vec3 lightPos	 = lightPosition();

    vec3  normalMap  = tex.normal;
	vec3  normal     = normalize(tbn * normalMap);

	float AO 		 = tex.AO;
    #ifdef HEIGHT_AO
		AO          *= tex.height;
	#endif

	float roughness  = tex.roughness;
	vec3  f0 		 = tex.f0;

    float subsurf    = tex.subsurface;
    float porosity   = tex.porosity;

	float emission   = tex.emission;

    vec3  lightDir   = normalize(lightPos);
    vec3  viewDir    = normalize(-viewpos);

    // Get PBR Material
	vec4 BRDF		 = CookTorrance(color.rgb, normal, viewDir, lightDir, roughness, f0, specBlend);
    BRDF.rgb        *= (lightPos == sunPosition ? 1.0 : 0.3) * brightness; //Reduce brightness at night and according to minecrafts abient light
    BRDF.rgb        += simpleSubsurface(color.rgb, normal, viewDir, lightDir, subsurf * brightness);

    // Emission and Ambient Light
	BRDF.rgb 		+= origColor.rgb * emission * 2;
    BRDF.rgb        += origColor.rgb * ambient  * AO;

	// Blend between normal MC rendering and PBR rendering
	color.rgb 	     = mix(default_render_color, BRDF.rgb, PBR_BLEND);
	BRDF.a 	    	 = mix(0, BRDF.a, PBR_BLEND);
	
	float reflectiveness = BRDF.a * max(1 - 2 * roughness, 0);

    color.rgb = max(color.rgb, 0); // Prevent Negative values

	PBRout Material  = PBRout(color, normal, reflectiveness);
	return Material;

}


float DynamicLight(vec2 lmcoord) {
    return lmcoord.x * lmcoord.x;
}