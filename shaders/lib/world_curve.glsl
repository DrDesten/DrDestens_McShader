vec4 unmodifiedClipPosition   = ftransform();
vec4 modifiedPlayerPosition   = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
modifiedPlayerPosition.y     += 1 - sqrt(1 + dot(modifiedPlayerPosition.xz * WORLD_CURVE_AMOUNT, modifiedPlayerPosition.xz * WORLD_CURVE_AMOUNT));
clipPos 	                 += gl_ProjectionMatrix * (gbufferModelView * modifiedPlayerPosition) - unmodifiedClipPosition;