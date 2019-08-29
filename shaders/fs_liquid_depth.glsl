#version 330 core

uniform float radius;
uniform mat4 projection_matrix;
//out vec4 FragColor;
in vec3 eyeSpacePos;
//layout(location = 0) out vec4 FragColor;
void main(){	
	vec3 normal;
	normal.xy = gl_PointCoord* 2.0 - vec2(1.0);
	float mag = dot(normal.xy, normal.xy);
	if(mag > 1.0) discard;
	normal.z = sqrt(1.0 - mag);

	vec4 pixelEyePos = vec4(eyeSpacePos + normal * radius, 1.0f);
	vec4 pixelClipPos = projection_matrix * pixelEyePos;
	float ndcZ = pixelClipPos.z / pixelClipPos.w;
	gl_FragDepth = ndcZ;
	/*
	vec3 eye = eyeSpacePos + vec3(0.0, 0.0, radius * normal.z);
	float depth = (projection_matrix[2][2] * eye.z + projection_matrix[3][2])
        / (projection_matrix[2][3] * eye.z + projection_matrix[3][3]);

    gl_FragDepth = (depth + 1.0) / 2.0;*/
	//FragColor = vec4(vec3(gl_FragDepth),1.0);
	//FragColor = vec4(vec3(ndcZ),1.0);
}