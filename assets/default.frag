#version 330 core

uniform sampler2D texture;
uniform sampler2D caustics;
uniform vec4 color;
uniform vec3 lightDir = normalize(vec3(0.35, 1.0, 0.35));
uniform float time;

uniform vec4 fogColor = vec4(0.15, 0.55, 0.84, 1.0);
uniform float fogStart = 0.5;
uniform float fogEnd = 20.0;

in vec2 texCoords;
in vec3 normal;
in float viewDist;
in vec3 worldPos;

out vec4 fragColor;

void main() {
  vec2 causticSample =
      worldPos.xz * 0.1 +
      vec2(sin(worldPos.x + time), sin(worldPos.z + time)) * 0.05;
  // Apply caustics only to upward pointing faces
  float pointsUp = max(dot(normal, vec3(0, 1, 0)), 0.0);
  float nDotL = max(dot(lightDir, normal), 0.0);
  vec3 caustics = texture2D(caustics, causticSample).rgb * 0.1 * nDotL;
  vec4 base =
      clamp(color, vec4(0.0), vec4(1.0)) * texture2D(texture, texCoords);
  float ambientLight = 0.3;
  vec4 color = vec4(base.rgb * ambientLight + base.rgb * nDotL + caustics, 1.0);
  float fogBlend = clamp(viewDist / (fogEnd - fogStart), 0.0, 1.0);
  fragColor = mix(color, fogColor, fogBlend);
}
