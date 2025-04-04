#version 140

in mediump vec2 var_texcoord0;
out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;
uniform fs_uniforms {
    mediump vec4 tint;
};

void main()
{
    // Берём альфу из текстуры
    mediump float tex_alpha = texture(texture_sampler, var_texcoord0).a;

    // Цвет из tint, умножаем на альфу для premultiplied alpha
    mediump vec3 color = tint.rgb * tex_alpha;

    // Собираем итоговый цвет: premultiplied (color = RGB×A, alpha = A)
    out_fragColor = vec4(color, tex_alpha);
}
