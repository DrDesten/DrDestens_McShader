vec4 unmodifiedClipPosition   = ftransform();
vec4 modifiedPlayerPosition   = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
float dist2                   = dot(modifiedPlayerPosition.xz, modifiedPlayerPosition.xz);
modifiedPlayerPosition.y    += sqrt( (WORLD_CURVE_RADIUS * WORLD_CURVE_RADIUS) - dist2 ) - WORLD_CURVE_RADIUS; // Faster version, doesn't work with negative radii
//modifiedPlayerPosition.y     += WORLD_CURVE_RADIUS * sqrt(1 - (dist2 / (WORLD_CURVE_RADIUS * WORLD_CURVE_RADIUS))) - WORLD_CURVE_RADIUS;
clipPos 	                 += gl_ProjectionMatrix * (gbufferModelView * modifiedPlayerPosition) - unmodifiedClipPosition;