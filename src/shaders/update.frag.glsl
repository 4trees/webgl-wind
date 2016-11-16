precision mediump float;

uniform sampler2D u_wind;
uniform vec2 u_wind_tex_scale;
uniform float u_wind_tex_size;
uniform sampler2D u_particles;

varying vec2 v_position;

vec2 encode(const float value) {
    float v = value * 255.0 * 255.0;
    return vec2(mod(v, 255.0), floor(v / 255.0)) / 255.0;
}
float decode(const vec2 channels) {
    return dot(channels, vec2(255.0, 255.0 * 255.0)) / (255.0 * 255.0);
}
highp float rand(vec2 co) {
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt = dot(co.xy, vec2(a,b));
    highp float sn = mod(dt, 3.14);
    return fract(sin(sn) * c);
}

vec2 lookup_wind(vec2 uv) {
    // manual bilinear filtering below for smoothness
    float px = 1.0 / u_wind_tex_size;
    vec2 vc = (floor(uv * u_wind_tex_scale)) * px;
    vec2 f = fract(uv * u_wind_tex_scale);
    vec2 tl = texture2D(u_wind, vc).rg;
    vec2 tr = texture2D(u_wind, vc + vec2(px, 0)).rg;
    vec2 bl = texture2D(u_wind, vc + vec2(0, px)).rg;
    vec2 br = texture2D(u_wind, vc + vec2(px, px)).rg;
    // return texture2D(u_wind, uv * u_wind_tex_scale / u_wind_tex_size).rg; // hardware filtering
    return mix(mix(tl, tr, f.x), mix(bl, br, f.x), f.y);
}
void main() {
    vec4 particle_sample = texture2D(u_particles, v_position);
    vec2 particle_pos = vec2(decode(particle_sample.rg), decode(particle_sample.ba));

    vec2 seed = particle_pos + v_position;
    if (rand(seed) < 0.98) {
        vec2 speed = (lookup_wind(particle_pos) * 67.0) - 30.0;
        particle_pos = mod(1.0 + particle_pos + speed * 0.0001, 1.0);
    } else {
        particle_pos = vec2(rand(seed * 2.0), rand(seed * 3.0));
    }

    gl_FragColor = vec4(encode(particle_pos.x), encode(particle_pos.y));
}
