// Modeling - 2026.09.06
// Eric Galin

// Ray: origin and direction
struct Ray {
  vec3 o;// Origin
  vec3 d;// Direction
};

// Material: just a color and a specular exponent
struct Mat {
  vec3 a; // Ambient color
  float s; // Specular exponent
};

vec3 Point(Ray ray, float t) {
  return ray.o + ray.d * t;
}

// Rotation matrix around z axis
// a : Angle
mat3 Rz(float a) {
  float sa = sin(a);
  float ca = cos(a);
  return mat3(ca, sa, 0., -sa, ca, 0., 0., 0., 1.);
}

// Camera: compute the ray
//   o, t : Origin and target points
//   m, p : Mouse position and pixel coordinates
Ray CreateRay(vec3 o, vec3 t, vec2 m, vec2 p) {
  // Rotate ray origin according to mouse x position
  vec3 r = Rz(2.0 * 3.14 * m.x) * o;

  // Orthonormal frame from target point
  vec3 w = normalize(t - r);
  vec3 u = normalize(cross(w, vec3(0., 0., 1.)));
  vec3 v = normalize(cross(u, w));
  vec3 d = normalize(p.x * u + p.y * v + 4.0 * w); // 4.0 = distance between eye and camera plane : increase to get narrower focus
  return Ray(r, d);
}

// Primitives

// Sphere
//    p : point
// c, r : center and radius
float Sphere(vec3 p, vec3 c, float r) {
  return length(p - c) - r;
}

// Union
// a, b : field function of left and right sub-trees
float Union(float a, float b) {
  return min(a, b);
}

// Constrction of object
// p : point
float object(vec3 p) {
  float v = Union(Sphere(p, vec3(3., 0., -1.), 2.), Sphere(p, vec3(3., 0., 5.), 3.0));

  v = Union(v, Sphere(p, vec3(0., 0., -37.), 34.));

  return v;
}

const int Steps = 200;// Number of steps
const float Epsilon = .01;// Marching epsilon

// Object normal
// p : point
vec3 ObjectNormal(vec3 p) {
  vec3 n;
  float v = object(p);
  n.x = object(vec3(p.x + Epsilon, p.y, p.z)) - v;
  n.y = object(vec3(p.x, p.y + Epsilon, p.z)) - v;
  n.z = object(vec3(p.x, p.y, p.z + Epsilon)) - v;
  return normalize(n);
}

// Trace ray using ray marching
// ray : ray 
//   d : Maximum distance
//   h : hit
//   s : Number of steps
bool SphereTrace(Ray ray, float d, out float t, out int s) {
  // Start at the origin
  t = 0.;

  for(int i = 0; i < Steps; i++) {
    s = i;
    vec3 p = Point(ray, t);
    float v = object(p);
    // Hit object
    if(v < 0.) {
      return true;
    }
    // Move along ray
    t += max(Epsilon, v);
    // Escape marched too far away
    if(t > d) {
      return false;
    }
  }
  return false;
}

// Lighting

// Background color
// d : Ray direction
vec3 background(vec3 d) {
  return mix(vec3(.45, .55, .99), vec3(.65, .69, .99), d.z * .5 + .5);
}

// Shadowing
// ray : The ray
float Shadow(Ray ray) {
  int s;
  float t;
  if(SphereTrace(ray, 100., t, s)) {
    return 0.;
  }
  return 1.;
}

// Get material at a given point
// p : Point.
Mat GetMaterial(vec3 p) {
  return Mat(vec3(0.34, 0.37, 0.49), 35.0);
}

// Shading and lighting
// p, n: Point and normal of the surface at this point
// e : Eye direction
vec3 Shade(vec3 p, vec3 n, vec3 e) {
  // Use a point light
  const vec3 lp = vec3(5., 10., 30.);

  // Light direction to point light
  vec3 l = normalize(lp - p);

  // Get material
  Mat m = GetMaterial(p);

  // Shadow computation
  float shadow = Shadow(Ray(p + Epsilon * n, l));

  // Phong diffuse
  vec3 diffuse = .35 * clamp(dot(n, l), 0., 1.) * vec3(1., 1., 1.);

  // Specular
  vec3 r = reflect(e, n);
  vec3 specular = .15 * pow(clamp(dot(r, l), 0., 1.), m.s) * vec3(1., 1., 1.);
  vec3 c = m.a + shadow * (diffuse + specular);
  return c;
}

// Shading according to the number of steps in sphere tracing
// n : Number of steps
vec3 ShadeSteps(int n) {
  float t = float(n) / (float(Steps - 1));
  return .5 + mix(vec3(.05, .05, .5), vec3(.65, .39, .65), t);
}

// Picture in picture
// pixel : Pixel
vec2 PixeltoCamera(in vec2 pixel) {
  // Pixel coordinates
  return (-iResolution.xy + 2. * pixel) / iResolution.y;
}

// Image
void mainImage(out vec4 color, in vec2 pxy) {
  // Pixel to camera coordinates
  vec2 pixel = PixeltoCamera(pxy);

  // Mouse
  vec2 m = iMouse.xy / iResolution.xy;

  // Create ray from camera position and target point
  Ray ray = CreateRay(vec3(40., 0., 20.), vec3(0., 0., 2.), m, pixel);

   // Shade background
  vec3 rgb = background(ray.d);

  // Trace ray: check if hit and number of steps
  int s;
  float t;

  if(SphereTrace(ray, 100., t, s)) {
    // Position
    vec3 p = Point(ray, t);

    // Compute normal
    vec3 n = ObjectNormal(p);

    // Shade object with light
    rgb = Shade(p, n, ray.d);
  }

  // Uncomment this line to shade image with false colors representing the number of steps
  //rgb = ShadeSteps(s);

  color = vec4(rgb, 1.);
}
