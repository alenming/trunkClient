#ifdef GL_ES
precision lowp float;
#endif

uniform float u_modTime;

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
    if(gl_FragColor.a >= 0.8)
    {
        vec3 hsvcolor = rgb2hsv(gl_FragColor.rgb);
        hsvcolor.x = mod(u_modTime * 0.25 + hsvcolor.x, 360.0);
        gl_FragColor.rgb = hsv2rgb(hsvcolor);
    }
}
