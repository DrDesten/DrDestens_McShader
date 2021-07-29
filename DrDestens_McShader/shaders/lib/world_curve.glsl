vec4 worldCurvePlayerPosition = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
worldCurvePlayerPosition.y   += 1 - sqrt(1 + dot(worldCurvePlayerPosition.xz * WORLD_CURVE_AMOUNT, worldCurvePlayerPosition.xz * WORLD_CURVE_AMOUNT));
clipPos 	                 += gl_ProjectionMatrix * (gbufferModelView * worldCurvePlayerPosition);