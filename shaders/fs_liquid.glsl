#version 330 core
out vec4 FragColor;

in vec2 TexCoords;

uniform vec4 liquidColor;
uniform mat4 modelview_matrix;
uniform mat4 projection_matrix;
uniform mat4 InvView_matrix;
uniform mat4 InvProject_matrix;

uniform sampler2D texDepth;
uniform sampler2D texThick;
uniform sampler2D backgroundTex;
uniform float depthFalloff;

vec3 uvToEye(vec2 coord, float z)
{
	vec2 pos = coord * 2.0f - 1.0f;
	vec4 clipPos = vec4(pos, z, 1.0f);
	vec4 viewPos = InvProject_matrix * clipPos;
	return viewPos.xyz / viewPos.w;
}

vec3 lightDirection = vec3(1.0f, 0.5f, 0.5f);
vec3 ambient = vec3(0.05f);
vec3 diff = vec3(0.6f);
vec3 spec = vec3(0.6f);

void main()
{
	float depth = texture(texDepth,TexCoords).r;
	if(depth > 0.99f || depth < -0.99f)
	{
		FragColor = texture(backgroundTex, TexCoords);
		return;
	}
/*	// -----------------reconstruct normal----------------------------
	vec2 depthTexelSize = 1.0 / textureSize(texDepth, 0);
	// calculate eye space position.
	vec3 eyeSpacePos = uvToEye(TexCoords, depth);
	// finite difference.
	vec3 ddxLeft   = eyeSpacePos - uvToEye(TexCoords - vec2(depthTexelSize.x,0.0f),
					texture(texDepth, TexCoords - vec2(depthTexelSize.x,0.0f)).r);
	vec3 ddxRight  = uvToEye(TexCoords + vec2(depthTexelSize.x,0.0f),
					texture(texDepth, TexCoords + vec2(depthTexelSize.x,0.0f)).r) - eyeSpacePos;
	vec3 ddyTop    = uvToEye(TexCoords + vec2(0.0f,depthTexelSize.y),
					texture(texDepth, TexCoords + vec2(0.0f,depthTexelSize.y)).r) - eyeSpacePos;
	vec3 ddyBottom = eyeSpacePos - uvToEye(TexCoords - vec2(0.0f,depthTexelSize.y),
					texture(texDepth, TexCoords - vec2(0.0f,depthTexelSize.y)).r);
	vec3 dx = ddxLeft;
	vec3 dy = ddyTop;
	if(abs(ddxRight.z) < abs(ddxLeft.z))
		dx = ddxRight;
	if(abs(ddyBottom.z) < abs(ddyTop.z))
		dy = ddyBottom;
	vec3 normal = normalize(cross(dx, dy));
	vec3 worldPos = (InvView_matrix * vec4(eyeSpacePos, 1.0f)).xyz;
*/
// -----------------reconstruct normal----------------------------

	vec2 imageDim = textureSize(texDepth, 0);
	vec2 texelSize = 1.0 / imageDim;
	
	vec3 eyeSpacePos = uvToEye(TexCoords, depth);
	/*
	// central differences.
	float depthRight = texture(texDepth, TexCoords + vec2(texelSize.x, 0)).r;
	float depthLeft = texture(texDepth, TexCoords - vec2(texelSize.x, 0)).r;
	float zdx = 0.5f * (depthRight - depthLeft);
	if(depthRight == 0.0f || depthLeft == 0.0f)
		zdx = 0.0f;
	
	float depthUp = texture(texDepth, TexCoords + vec2(0, texelSize.y)).r;
	float depthDown = texture(texDepth, TexCoords - vec2(0, texelSize.y)).r;
	float zdy = 0.5f * (depthUp - depthDown);
	if(depthUp == 0.0f || depthDown == 0.0f)
		zdy = 0.0f;
	*/
	/************/
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
	
	
	/************/
/*
	//float depthFalloff = 0.001f;
	if(abs(depth - depthRight) > depthFalloff || abs(depth - depthLeft) > depthFalloff)
		zdx = 0.0f;
	if(abs(depth - depthDown) > depthFalloff || abs(depth - depthUp) > depthFalloff)
		zdy = 0.0f;
*/
	float Fx = projection_matrix[0][0];
	float Fy = projection_matrix[1][1];
	
	float Cx = -2.0f/(imageDim.x * Fx);
	float Cy = -2.0f/(imageDim.y * Fy);

	vec3 normal = normalize(vec3(Cy * zdx, Cx * zdy, Cx * Cy * depth));
	vec3 worldPos = (InvView_matrix * vec4(eyeSpacePos, 1.0f)).xyz;

	// -----------------refracted----------------------------
	vec2 texScale = vec2(0.75, 1.0);		// ???.
	float refractScale = 1.33 * 0.025;	// index.
	refractScale *= smoothstep(0.1, 0.4, worldPos.y);
	vec2 refractCoord = TexCoords + normal.xy * refractScale * texScale;
	float thickness = max(texture(texThick, TexCoords).r, 0.3f);
	vec3 transmission = exp(-(vec3(1.0f) - liquidColor.xyz) * thickness);
	//vec3 backgroundColor = vec3(0.4f,0.4f,0.4f);
	vec3 refractedColor = texture(backgroundTex, refractCoord).xyz * transmission;
	//vec3 refractedColor = backgroundColor * transmission;

	// -----------------Phong lighting----------------------------
	vec3 viewDir = -normalize(eyeSpacePos);
	vec3 lightDir = normalize((modelview_matrix * vec4(lightDirection, 0.0f)).xyz);
	vec3 halfVec = normalize(viewDir + lightDir);
	vec3 specular = vec3(spec * pow(max(dot(halfVec, normal), 0.0f), 400.0f));
	vec3 diffuse = liquidColor.xyz * max(dot(lightDir, normal), 0.0f) * diff * liquidColor.w;
	
	// -----------------Merge all effect----------------------------
	//FragColor.rgb = diffuse + specular + refractedColor;
	//FragColor.a = 1.0f;
	vec3 finalColor = diffuse + specular + refractedColor;
	//FragColor = vec4(finalColor,1.0f);
	FragColor = vec4(vec3(depth),1.0f);
	//FragColor = vec4(normal,1.0);
	//FragColor = vec4(thickness,0.0,0.0,1.0);
	//FragColor = vec4(0.0,1.0,0.0,1.0);

	// gamma correction.
	// glow map.
	//float brightness = dot(FragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
	//brightColor = vec4(FragColor.rgb * brightness * brightness, 1.0f);
	
    //FragColor = vec4(col, 1.0);
} 