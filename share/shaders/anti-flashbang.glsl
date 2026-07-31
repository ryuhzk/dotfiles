#version 300 es

// Anti-flashbang: dim the screen in proportion to how bright it currently is.
//
// A white page opening at night is painful because the jump in luminance is
// sudden and total. This shader estimates the average brightness of the whole
// screen each frame and scales the output down as that average rises. Dark
// content is left untouched, so it costs nothing when nothing is wrong.
//
// Applied through decoration:screen_shader. Hyprland supports one screen shader
// at a time; this replaces any other.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Samples per axis used to estimate screen brightness. The grid has to be dense
// enough to notice a bright window that covers only part of the screen, and
// sparse enough to stay cheap at every pixel.
const float kGridSteps = 8.0;

// Mean luminance at or below which nothing is dimmed at all.
const float kFloor = 0.10;

// Mean luminance at which dimming reaches its full strength.
const float kCeiling = 0.85;

// Strongest reduction applied, as a fraction of the original luminance.
// Raise toward 1.0 for a more aggressive effect.
const float kMaxDim = 0.55;

const vec3 kRec709 = vec3(0.2126, 0.7152, 0.0722);

float meanLuminance() {
    float total = 0.0;
    float cell = 1.0 / kGridSteps;

    // Sample at cell centers so the grid stays symmetric across the screen.
    for (float x = 0.5 * cell; x < 1.0; x += cell) {
        for (float y = 0.5 * cell; y < 1.0; y += cell) {
            total += dot(texture(tex, vec2(x, y)).rgb, kRec709);
        }
    }

    return total / (kGridSteps * kGridSteps);
}

void main() {
    vec4 pixel = texture(tex, v_texcoord);

    // smoothstep eases in and out of the dimming range, so brightness changes
    // near either threshold do not produce a visible step.
    float dim = kMaxDim * smoothstep(kFloor, kCeiling, meanLuminance());

    fragColor = vec4(pixel.rgb * (1.0 - dim), pixel.a);
}
