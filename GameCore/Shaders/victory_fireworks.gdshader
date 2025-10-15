shader_type canvas_item;

uniform float NUM_CONFETTI = 80.0;   // quantidade de confetes
uniform float GRAVITY = 1500.0;       // velocidade de queda
uniform float TIME_SCALE = 5.0;      // escala do tempo
uniform vec2 resolution = vec2(1024.0, 600.0);

// hash pseudoaleatório
vec2 hash2(float n) {
    return fract(vec2(sin(n*12.9898)*43758.5453, cos(n*78.233)*43758.5453));
}

// confete único
vec4 confete(vec2 frag_pos, float id, float t) {
    vec2 seed = hash2(id);

    // tempo de início aleatório
    float start = seed.x * 1.5;
    if (t < start) return vec4(0.0);

    float age = t - start;

    // posição inicial: topo da tela, fora da visão
    vec2 pos;
    pos.x = resolution.x * 0.5 + (seed.x - 0.5) * resolution.x * 0.6; // espalha horizontal
    pos.y = -10.0; // começa acima da tela

    // movimento horizontal oscilando levemente
    pos.x += sin(age * 3.0 + seed.y * 6.28) * 50.0;

    // movimento vertical com gravidade
    pos.y += age * GRAVITY;

    // some quando sair da tela
    if (pos.y > resolution.y) return vec4(0.0);

    // tamanho
    float size = 4.0 + seed.y * 6.0;

    // cores vibrantes
    vec3 color = vec3(
        0.5 + 0.5 * sin(seed.x * 12.0 + t * 5.0),
        0.5 + 0.5 * sin(seed.y * 24.0 + t * 3.0),
        0.5 + 0.5 * sin(seed.x * 36.0 + t * 7.0)
    );

    // renderiza quadradinho de confete
    vec2 diff = frag_pos * resolution - pos;
    float alpha = step(length(diff), size);

    return vec4(color, alpha);
}

void fragment() {
    vec2 frag_pos = SCREEN_UV; // UV normalizada
    float t = TIME * TIME_SCALE;

    vec4 col = vec4(0.0);
    for (float i = 0.0; i < NUM_CONFETTI; i += 1.0) {
        col += confete(frag_pos, i, t);
    }

    COLOR = vec4(col.rgb, col.a); // fundo transparente
}
