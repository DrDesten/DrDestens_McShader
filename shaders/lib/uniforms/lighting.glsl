#ifndef INCLUDE_LIGHTING_GLSL
#define INCLUDE_LIGHTING_GLSL

uniform float nightVision;
uniform float darknessFactor;
uniform int   isEyeInWater;

uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;

uniform float daynight;
uniform float sunset;
uniform float customLightmapBlend;
uniform float lightBrightness;
uniform vec3  lightPosition;

uniform vec3  fogColor;
uniform vec3  sunDir;

#endif