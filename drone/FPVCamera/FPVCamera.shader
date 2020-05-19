shader_type spatial;
render_mode unshaded;

const float PI = 3.14159265358979323846;

uniform sampler2D Texture0;
uniform sampler2D Texture1;
uniform sampler2D Texture2;
uniform sampler2D Texture3;
uniform sampler2D Texture4;

uniform float hfov = 150.0;


vec3 latlon_to_ray(vec2 latlon) {
	float lat = latlon.x;
	float lon = latlon.y;
	return vec3(sin(lon) * cos(lat), sin(lat), -cos(lon) * cos(lat));
}

vec3 fisheye_inverse(vec2 p) {
	float r = sqrt(p.x * p.x + p.y * p.y);
	
	if (r > PI) {
		return vec3(0.0, 0.0, 0.0);
	}
	else {
		float theta = r;
		float s = sin(theta);
		return vec3(p.x / r * s, p.y / r * s, -cos(theta));
	}
}

vec2 fisheye_forward(vec2 latlon) {
	vec3 ray = latlon_to_ray(latlon);
	float theta = acos(-ray.z);
	float r = theta;
	float c = r / length(ray.xy);
	return vec2(ray.x * c, ray.y * c);
}

vec3 fisheye_ray(vec2 p) {
	float scale = fisheye_forward(vec2(0.0, radians(hfov) / 2.0)).x;
	return fisheye_inverse(p * scale);
}


void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	float view_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec2 uv = FRAGCOORD.xy / min(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y);
	vec3 pos = vec3(0.0, 0.0, 0.0);
	if (view_ratio > 1.0) {
		pos = fisheye_ray(vec2(uv.x - 0.5 * view_ratio, uv.y - 0.5));
	} else {
		pos = fisheye_ray(vec2(uv.x - 0.5, uv.y - 0.5 / view_ratio));
	}
	if (pos == vec3(0.0, 0.0, 0.0)) {
		ALBEDO = pos;
	} else {
		float ax = abs(pos.x);
		float ay = abs(pos.y);
		float az = abs(pos.z);
		
		if (pos.z <= 0.0) {
			if (az > ax && az > ay) {
				uv = vec2(0.5 * (vec2(pos.x / az, pos.y / az)) + 0.5);
				ALBEDO = texture(Texture0, uv).rgb;
			} else {
				if (ax > ay) {
					if (pos.x < 0.0) {
						uv = vec2(0.5 * (vec2(-pos.z / ax, pos.y / ax)) + 0.5);
						ALBEDO = texture(Texture1, uv).rgb;
					} else {
						uv = vec2(0.5 * (vec2(pos.z / ax, pos.y / ax)) + 0.5);
						ALBEDO = texture(Texture2, uv).rgb;
					}
				} else {
					if (pos.y < 0.0) {
						uv = vec2(0.5 * (vec2(pos.x / ay, -pos.z / ay)) + 0.5);
						ALBEDO = texture(Texture3, uv).rgb;
					} else {
						uv = vec2(0.5 * (vec2(pos.x / ay, pos.z / ay)) + 0.5);
						ALBEDO = texture(Texture4, uv).rgb;
					}
				}
			}
		} else {
			ALBEDO = vec3(0.0, 0.0, 0.0);
		}
	}
}