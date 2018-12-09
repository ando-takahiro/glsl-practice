
const int maxConverge = 100;
const float epsilon = 1E-4;

float dSphere(vec3 p, float r) {
  return length(p) - r;
}

float dScene(vec3 p) {
  return dSphere(p, 0.5);
}

void mainImage(out vec4 outColor, in vec2 fragCoord) {
  vec2 s = (2. * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);

  vec3 ro = vec3(0.0, 0.0, -1.0);
  vec3 ta = vec3(0.0, 0.0, 0.0);

  vec3 fwd = normalize(ta - ro);
  vec3 up = vec3(0.0, 1.0, 0.0);
  vec3 right = cross(fwd, up);
  up = cross(right, fwd);
  vec3 rd = normalize(fwd + s.x * right - s.y * up);

  vec3 p = ro;
  int i;
  for (i = 0; i < maxConverge; i++) {
    float d = dScene(p);
    p += rd * d;
    if (abs(d) <= epsilon) {
      break;
    }
  }

  float cv = float(i) / float(maxConverge);

  outColor = vec4(cv, cv, cv, 1.0);
}