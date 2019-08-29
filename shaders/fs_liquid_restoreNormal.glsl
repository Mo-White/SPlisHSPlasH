# version 330 core

layout(location = 0) out vec4 normal_D;

in vec2 TexCoords;

uniform mat4 projection_matrix;

uniform sampler2D texDepth;

uniform float p_n;
uniform float p_t;
uniform float p_r;
uniform float s_w;
uniform float s_h;

float getZ(float x, float y) {
	return -texture(texDepth, vec2(x, y)).x;
}

float f_x, f_y, c_x, c_y, c_x2, c_y2;

void main() {

	vec2 imageDim = textureSize(texDepth, 0);
	vec2 texelSize = 1.0 / imageDim;
	
	float depth = -texture(texDepth,TexCoords).x;
	
	float ddxLeft   = depth - texture(texDepth, TexCoords - vec2(texelSize.x,0.0f)).r;
	float ddxRight  = texture(texDepth, TexCoords + vec2(texelSize.x,0.0f)).r - depth;
	float ddyTop    = texture(texDepth, TexCoords + vec2(0.0f,texelSize.y)).r - depth;
	float ddyBottom = depth - texture(texDepth, TexCoords - vec2(0.0f,texelSize.y)).r;
	float zdx = ddxLeft;
	float zdy = ddyTop;
	if(abs(ddxRight) < abs(ddxLeft))
		zdx = ddxRight;
	if(abs(ddyBottom) < abs(ddyTop))
		zdy = ddyBottom;
	
	float Fx = projection_matrix[0][0];
	float Fy = projection_matrix[1][1];
	
	float Cx = -2.0f/(imageDim.x * Fx);
	float Cy = -2.0f/(imageDim.y * Fy);

	vec3 normal = vec3(Cy * zdx, Cx * zdy, Cx * Cy * depth);
	
	
/*
	f_x = p_n / p_r;
	f_y = p_n / p_t;
	c_x = 2 / (s_w * f_x);
	c_y = 2 / (s_h * f_y);
	c_x2 = c_x * c_x;
	c_y2 = c_y * c_y;


	float x = TexCoords.x, y = TexCoords.y;
	float dx = 1 / s_w, dy = 1 / s_h;
	float z = getZ(x, y), z2 = z * z;
	float dzdx = getZ(x + dx, y) - z, dzdy = getZ(x, y+dy) - z;
	float dzdx2 = z - getZ(x - dx, y), dzdy2 = z - getZ(x, y - dy);
	
	if (abs(dzdx2) < abs(dzdx)) dzdx = dzdx2;
	if (abs(dzdy2) < abs(dzdy)) dzdy = dzdy2;

	vec3 normal = vec3(-c_y * dzdx, -c_x * dzdy, c_x*c_y*z);
	*/
	/* revert n.z to positive for debugging */
	normal.z = -normal.z;

	float d = length(normal);
	normal_D = vec4(normal / d, d);
}