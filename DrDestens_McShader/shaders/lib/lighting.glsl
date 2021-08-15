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
float G_Phong(vec3 normal, vec3 view, vec3 light) {
    return clamp(dot(normal, light), 0, 1) * clamp(dot(normal, view), 0, 1);
}

// Fresnel function (Schlick)
float F(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
vec3 F(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec4 CookTorrance(vec3 albedo, vec3 normal, vec3 viewPos, vec3 light, float roughness, vec3 f0, float specular) {
    vec3 V = normalize(-viewPos);
    vec3 L = normalize(light);
    vec3 H = normalize(V + L);

    float radiance = 5;

    float k = sq(roughness + 1) / 8;

    float D = NDF_GGX(normal, H, roughness);
    float G = G_Smith(normal, V, L, k);
    //float G = G_Phong(normal, V, L);
    vec3  F = F(clamp(dot(H, V), 0, 1), f0);

    vec3 kS = F;
    vec3 kD = 1 - kS;
    //kD *= 1 - metallic;

    vec3  zaehl = D * G * F;
    float nenn  = 4 * max(dot(normal, V), 0.0) * max(dot(normal, L), 0.0);
    vec3  spec  = zaehl / max(nenn, 0.001) * specular;
    spec        = min(spec, 5);

    vec3  BRDF  = (kD * albedo / PI + spec) * radiance * max(dot(normal, L), 0.0);
    //BRDF = vec3(G);

    return vec4(BRDF, (F.r + F.g + F.b) * 0.33333);
}

vec3 simpleSubsurface(vec3 albedo, vec3 normal, vec3 view, vec3 light, float subsurface) {
    float diff    = dot(normal, normalize(light));
    float subsurf = clamp(-diff, 0, 1) * subsurface;
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

PBRout PBRMaterial(MaterialInfo tex, vec2 lmcoord, mat3 tbn, vec3 viewpos, vec3 ambient) {
    
    vec4  origColor  = tex.color;
    vec4  color      = tex.color;

    // Specular Blending Factor (Removes specular highlights in occluded areas)
    float specBlend  = clamp(mix( -1.5, 1, lmcoord.y ), 0, 1); 

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

    // Get PBR Material
	vec4 BRDF		 = CookTorrance(color.rgb, normal, viewpos, lightPos, roughness, f0, specBlend) * (lightPos == sunPosition ? 1.0 : 0.3) * lmcoord.y; //Reduce brightness at night and according to minecrafts abient light
    BRDF.rgb        += simpleSubsurface(color.rgb, normal, viewpos, lightPos, subsurf * sum(ambient));

    // Emission and Ambient Light
    BRDF.rgb        *= AO;
	BRDF.rgb 		+= origColor.rgb * emission * 2;
    BRDF.rgb        += origColor.rgb * ambient  * AO;

	// Blend between normal MC rendering and PBR rendering
    float blend      = PBR_BLEND_MIN;
	color.rgb 	     = mix(color.rgb, BRDF.rgb, blend);
	BRDF.a 	    	 = mix(0, BRDF.a, blend);
	
	float reflectiveness = BRDF.a * max(1 - 2 * roughness, 0);

    color.rgb = max(color.rgb, 0); // Prevent Negative values


	PBRout Material  = PBRout(color, normal, reflectiveness);
	return Material;

}


float DynamicLight(vec2 lmcoord) {
    return lmcoord.x * lmcoord.x;
}