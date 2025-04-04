#version 140

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;
uniform lowp sampler2D mask_texture;

// Константа для ширины растушевки
const float EDGE_SOFTNESS = 0.5;

void main()
{
    // Получаем значение из маски для текущей позиции пикселя
    lowp vec4 mask = texture(mask_texture, var_texcoord0.xy);
    
    // Используем smoothstep для более плавного перехода
    float transition = smoothstep(0.5 - EDGE_SOFTNESS, 0.5 + EDGE_SOFTNESS, mask.a);
    
    if (transition > 0.99) {
        // Для полной прозрачности (глубоко внутри спотлайта)
        out_fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        // Применяем затемнение с плавным переходом
        out_fragColor = var_color;
        out_fragColor.a = var_color.a * (1.0 - transition);
    }
}