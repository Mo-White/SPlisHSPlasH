#version 330 core
layout (location = 0) in vec3 aPos;

out vec3 TexCoords;

uniform mat4 modelview_matrix;
uniform mat4 projection_matrix;

void main()
{
    TexCoords = aPos;
	vec4 mv_pos = projection_matrix * modelview_matrix * vec4(aPos, 1.0);
    gl_Position = mv_pos.xyww;
}  