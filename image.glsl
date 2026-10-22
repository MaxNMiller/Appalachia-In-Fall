// Appalachia in Fall — artwork by Max Miller.
// Inspired by Rainforest by Íñigo Quílez (2016).
// https://www.youtube.com/watch?v=BFld4EBO2RE

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord/iResolution.xy;

    vec3 col = texture( iChannel0, p ).xyz;

    col *= 0.5 + 0.5*pow( 16.0*p.x*p.y*(1.0-p.x)*(1.0-p.y), 0.05 );
         
    fragColor = vec4( col, 1.0 );
}

