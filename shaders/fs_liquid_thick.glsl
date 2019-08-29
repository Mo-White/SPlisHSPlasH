#version 330 core

uniform float radius;
uniform mat4 projection_matrix;

out vec4 fragColor;

void main(){	
	vec3 normal;
	normal.xy = gl_PointCoord * 2.0 - vec2(1.0);
	float mag = dot(normal.xy, normal.xy);
	if(mag > 1.0) discard;
	normal.z = sqrt(1.0 - mag);
	fragColor = vec4(normal.z*0.005, 0.0, 0.0, 1.0);
}