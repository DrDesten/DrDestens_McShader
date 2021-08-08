vec4 unmodifiedClipPosition   = ftransform();
vec4 modifiedPlayerPosition   = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
float dist2                   = dot(modifiedPlayerPosition.xz, modifiedPlayerPosition.xz);
float worldCurvatureRadius    = WORLD_CURVE_RADIUS + modifiedPlayerPosition.y + cameraPosition.y;
modifiedPlayerPosition.y     += sqrt( (worldCurvatureRadius * worldCurvatureRadius) - dist2 ) - worldCurvatureRadius; // Faster version, doesn't work with negative radii
//modifiedPlayerPosition.y     += worldCurvatureRadius * sqrt(1 - (dist2 / (worldCurvatureRadius * worldCurvatureRadius))) - worldCurvatureRadius;
clipPos 	                 += gl_ProjectionMatrix * (gbufferModelView * modifiedPlayerPosition) - unmodifiedClipPosition;