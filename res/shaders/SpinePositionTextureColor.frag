#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
    if(gl_FragColor.r > 0.01 && gl_FragColor.g > 0.01 && gl_FragColor.b > 0.01)
    {
        gl_FragColor.rgb += v_fragmentColor.rgb * 0.5;
    }
}
