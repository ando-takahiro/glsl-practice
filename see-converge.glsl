// Original author is 我無
// https://glslfan.com/?channel=-LScsXd7TDC0zkZ9cpzP

precision mediump float;

const float PI = 3.1415926;
const float EPS = 1e-4;
// #define saturate(x) clamp(x, 0.0, 1.0)

float dSphere(vec3 p, float r) {
  return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

vec3 opRep(vec3 p, vec3 c) {
  return mod(p, c) - 0.5 * c;
}

vec3 hsv(float h, float s, float v){
  vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
  return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

float dMenger(vec3 z0, vec3 offset, float scale) {
  vec4 z = vec4(z0, 1.0);
  for (int i = 0; i < 5; i++) {
    z = abs(z);
    if (z.x < z.y) z.xy = z.yx;
    if (z.x < z.z) z.xz = z.zx;
    if (z.y < z.z) z.yz = z.zy;
    
    z *= scale;
    z.xyz -= offset * (scale - 1.0);
    
    if (z.z < -0.5 * offset.z * (scale - 1.0)) {
      z.z += offset.z * (scale - 1.0);
    }
  }
  return length(max(abs(z.xyz) - vec3(1.0), 0.0)) / z.w;
}

mat2 rotate(float a) {
	float c = cos(a), s = sin(a);
	return mat2(c, s, -s, c);
}

float dScene(vec3 p) {
	// p -= vec3(0.5);
	// p = opRep(p, vec3(2.0));
	//p.xy *= rotate(3.0 * cos(time) * p.z);
	float t = 1.0 + sin(iTime);
	t *= 3.0;
	// float d = dMenger(p, vec3(0.6, 0.9, abs(sin(iTime))), 2.46);
	float d = dSphere(p, 0.5);
	// float d = sdBox(p, vec3(.5));
	return d;
}

float dBox(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return max(d.x, d.y);
}

float dTriangle(vec2 p, vec2 s) {
  return dBox(p, vec2(s.x - p.y * s.x / s.y, s.y));
}

float dTDFA(vec2 p) {
  vec2 s = vec2(0.1, 0.1);
  float d = dTriangle(p, s);
  d = min(d, dTriangle((p - vec2(0.25, 0.0)) * vec2(1.0, -1.0), s));
  d = min(d, dTriangle((p - vec2(-0.25, 0.0)) * vec2(1.0, -1.0), s));
  return d;
}

float dTDFB(vec2 p) {
  vec2 s = vec2(0.1, 0.1) * 0.4;
  float d = dTriangle((p - vec2(-0.07, 0.0)), s);
  d = min(d, dTriangle((p - vec2(0.3, -0.03)) * vec2(0.8, -0.8), s));
  return d;
}

void mainImage(out vec4 outColor, in vec2 fragCoord) {
  vec2 uv = (2.0 * fragCoord.xy - iResolution.xy) / min(iResolution.x, iResolution.y);
  float t = fract(iTime * 0.5);
  // let camera(=ro, ray origin) run 1.0 behind of the target
  vec3 ro = vec3(1.0, 1.0, t - 1.0);
  vec3 ta = vec3(0.0, 0.0, 0.0); // target

  vec3 fwd = normalize(ta - ro);
  vec3 right = cross(fwd, vec3(0, 1, 0));
  vec3 up = cross(right, fwd);
  vec3 rd = normalize(fwd + uv.x * right + uv.y * up);
    
  float distance = 0.0;
  vec3 p = ro;
  int step = 0;
  for (int i = 0; i < 100; i++) {
    step = i;
    float d = dScene(p);
    distance += d;
    p = ro + distance * rd;
    if (abs(d) < EPS) break;
  }

  // probably max converge count of this sphere would be 40
  int converge = 40;
  // show pixels that has fewer converge count than `converge`
  float v = float(step - converge) * 0.01;
  vec3 c;
  if (v >= .0) {
    // white/gray is outside(slower converge)
    c = vec3(v);
  } else {
    // red is inside(faster converge)
    v = 1.0;
    c = vec3(v, 0.0, 0.0);
  }
  // c += hsv(beat * 0.25 + 0.5 * p.z, 1.0, 1.0) * exp(-1.0 * fract(beat));
  // float fog = 1.0 - exp(-0.05 * pow(distance, 2.0));
  // c += vec3(0.2, 0.2, 1.0) * fog;
  
  // c = mix(c, vec3(0.0), 0.8 * saturate(-1000.0 * dTDFA(uv)));
  // c += vec3(1.0, 0.1, 0.1) * saturate(0.01 / saturate(dTDFB(uv)));
  
  outColor = vec4(c, 1.0);
}
