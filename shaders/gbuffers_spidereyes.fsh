uniform sampler2D texture;

varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;

	color *= 2;

	gl_FragData[0] = color; //gcolor
}