shader_type canvas_item;

uniform vec4 color : source_color;
uniform bool enabled;

void fragment() {
    if (enabled) {
        float diff = COLOR.r - ((COLOR.g + COLOR.b) / 2.0);
        COLOR = vec4((
			(COLOR.g + COLOR.b) / 2.0)
			+ (color.r * diff),
			COLOR.g + (color.g * diff),
			COLOR.b + (color.b * diff),
			COLOR.a);
    }
}
