// Appalachia in Fall — artwork by Max Miller.
// Inspired by Rainforest by Íñigo Quílez (2016).
// https://www.youtube.com/watch?v=BFld4EBO2RE

#define LOWQUALITY
#ifndef QUALITY_LOW
#define QUALITY_LOW 0
#define DEBUG_MODE 0
#define ENABLE_SIGNS 1
#define ENABLE_FOG 1
#define CAMERA_MOTION 0
#define CAMERA_ALT 0
#endif

//==========================================================================================
// general utilities
//==========================================================================================
#define ZERO (min(iFrame,0))

float sdEllipsoidY( in vec3 p, in vec2 r )
{
    float k0 = length(p/r.xyx);
    float k1 = length(p/(r.xyx*r.xyx));
    return k0*(k0-1.0)/k1;
}
float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// return smoothstep and its derivative
vec2 smoothstepd( float a, float b, float x)
{
    if( x<a ) return vec2( 0.0, 0.0 );
    if( x>b ) return vec2( 1.0, 0.0 );
    float ir = 1.0/(b-a);
    x = (x-a)*ir;
    return vec2( x*x*(3.0-2.0*x), 6.0*x*(1.0-x)*ir );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//==========================================================================================
// hashes (low quality, do NOT use in production)
//==========================================================================================

float hash1( vec2 p )
{
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float hash1( float n )
{
    return fract( n*17.0*fract( n*0.3183099 ) );
}

vec2 hash2( vec2 p )
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    float n = 111.0*p.x + 113.0*p.y;
    return fract(n*fract(k*n));
}

//==========================================================================================
// noises
//==========================================================================================

// value noise, and its analytical derivatives
vec4 noised( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    #if 1
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);
    #else
    vec3 u = w*w*(3.0-2.0*w);
    vec3 du = 6.0*w*(1.0-w);
    #endif

    float n = p.x + 317.0*p.y + 157.0*p.z;
    
    float a = hash1(n+0.0);
    float b = hash1(n+1.0);
    float c = hash1(n+317.0);
    float d = hash1(n+318.0);
    float e = hash1(n+157.0);
    float f = hash1(n+158.0);
    float g = hash1(n+474.0);
    float h = hash1(n+475.0);

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z),
                      2.0* du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                                      k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                                      k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    #if 1
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    #else
    vec3 u = w*w*(3.0-2.0*w);
    #endif
    

    float n = p.x + 317.0*p.y + 157.0*p.z;
    
    float a = hash1(n+0.0);
    float b = hash1(n+1.0);
    float c = hash1(n+317.0);
    float d = hash1(n+318.0);
    float e = hash1(n+157.0);
    float f = hash1(n+158.0);
    float g = hash1(n+474.0);
    float h = hash1(n+475.0);

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
}

vec3 noised( in vec2 x )
{
    vec2 p = floor(x);
    vec2 w = fract(x);
    #if 1
    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec2 du = 30.0*w*w*(w*(w-2.0)+1.0);
    #else
    vec2 u = w*w*(3.0-2.0*w);
    vec2 du = 6.0*w*(1.0-w);
    #endif
    
    float a = hash1(p+vec2(0,0));
    float b = hash1(p+vec2(1,0));
    float c = hash1(p+vec2(0,1));
    float d = hash1(p+vec2(1,1));

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k4 = a - b - c + d;

    return vec3( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k4*u.x*u.y),
                 2.0*du * vec2( k1 + k4*u.y,
                            k2 + k4*u.x ) );
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 w = fract(x);
    #if 1
    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    #else
    vec2 u = w*w*(3.0-2.0*w);
    #endif

    float a = hash1(p+vec2(0,0));
    float b = hash1(p+vec2(1,0));
    float c = hash1(p+vec2(0,1));
    float d = hash1(p+vec2(1,1));
    
    return -1.0+2.0*(a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y);
}

//==========================================================================================
// fbm constructions
//==========================================================================================

const mat3 m3  = mat3( 0.00,  0.80,  0.60,
                      -0.80,  0.36, -0.48,
                      -0.60, -0.48,  0.64 );
const mat3 m3i = mat3( 0.00, -0.80, -0.60,
                       0.80,  0.36, -0.48,
                       0.60, -0.48,  0.64 );
const mat2 m2 = mat2(  0.80,  0.60,
                      -0.60,  0.80 );
const mat2 m2i = mat2( 0.80, -0.60,
                       0.60,  0.80 );

//------------------------------------------------------------------------------------------

float fbm_4( in vec2 x )
{
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    for( int i=ZERO; i<4; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m2*x;
    }
    return a;
}

float fbm_4( in vec3 x )
{
    float f = 2.0;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for( int i=ZERO; i<4; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m3*x;
    }
    return a;
}

vec4 fbmd_7( in vec3 x )
{
    float f = 1.92;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    vec3  d = vec3(0.0);
    mat3  m = mat3(1.0,0.0,0.0,
                   0.0,1.0,0.0,
                   0.0,0.0,1.0);
    for( int i=ZERO; i<7; i++ )
    {
        vec4 n = noised(x);
        a += b*n.x;          // accumulate values
        d += b*m*n.yzw;      // accumulate derivatives
        b *= s;
        x = f*m3*x;
        m = f*m3i*m;
    }
    return vec4( a, d );
}

vec4 fbmd_8( in vec3 x )
{
    float f = 2.0;
    float s = 0.65;
    float a = 0.0;
    float b = 0.5;
    vec3  d = vec3(0.0);
    mat3  m = mat3(1.0,0.0,0.0,
                   0.0,1.0,0.0,
                   0.0,0.0,1.0);
    for( int i=ZERO; i<8; i++ )
    {
        vec4 n = noised(x);
        a += b*n.x;          // accumulate values
        if( i<4 )
        d += b*m*n.yzw;      // accumulate derivatives
        b *= s;
        x = f*m3*x;
        m = f*m3i*m;
    }
    return vec4( a, d );
}

float fbm_9( in vec2 x )
{
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    for( int i=ZERO; i<9; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m2*x;
    }
    
    return a;
}

vec3 fbmd_9( in vec2 x )
{
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    vec2  d = vec2(0.0);
    mat2  m = mat2(1.0,0.0,0.0,1.0);
    for( int i=ZERO; i<9; i++ )
    {
        vec3 n = noised(x);
        a += b*n.x;          // accumulate values
        d += b*m*n.yz;       // accumulate derivatives
        b *= s;
        x = f*m2*x;
        m = f*m2i*m;
    }

    return vec3( a, d );
}

//==========================================================================================
// specifics to the actual painting
//==========================================================================================

//------------------------------------------------------------------------------------------
// global
//------------------------------------------------------------------------------------------

// Scene uniforms. Reset history when changing the camera or preset.
uniform vec3 uEye,uTarget,uSun;
uniform float uFocal;
uniform vec4 uAir; // distance extinction, valley density, shaft, polluted sky mix
uniform vec4 uLight; // direct, ambient, exposure, warm scattering mix
uniform int uTowerCount;
#define kSunDir normalize(uSun)
const float kMaxTreeHeight = 10.0;
const float kMaxHeight = 840.0;

// Particulate haze.
vec3 fog(in vec3 col,float t)
{
    if(ENABLE_FOG==0)return col;
    float ext=exp(-t*0.00065*uAir.x);
    float luma=dot(col,vec3(0.2126,0.7152,0.0722));
    col=mix(vec3(luma),col,0.5+0.5*ext);
    return col*ext+(1.0-ext)*mix(vec3(0.15,0.18,0.20),vec3(0.23,0.205,0.15),uLight.w);
}
float pollutedLight(vec3 p)
{
    vec2 ceiling=p.xz+kSunDir.xz*(900.0-p.y)/kSunDir.y;
    float diffuse=0.18+0.45*smoothstep(-0.05,0.45,noise(ceiling*0.0027+vec2(2.3,0.5)));
    float shaft=exp(-pow((dot(ceiling,vec2(0.8,0.2))+850.0)/65.0,2.0));
    return mix(0.90,min(1.0,diffuse+0.8*shaft),uAir.z);
}
// Integrate particulate density to the surface depth.
vec3 valleyFog(vec3 col,vec3 ro,vec3 rd,float t)
{
    if(ENABLE_FOG==0)return col;
    col=fog(col,t);
    vec3 scatter=vec3(0);float trans=1.0;
    float end=min(t,2600.0);int steps=QUALITY_LOW==1?10:18;
    for(int i=0;i<18;i++){
        if(i>=steps)break;
        float a=float(i)/float(steps),b=float(i+1)/float(steps);
        float dt=end*(b*b-a*a);vec3 p=ro+rd*(end*(a*a+b*b)*0.5);
        float layer=exp(-pow((p.y-245.0)/58.0,2.0))*0.0027;
        layer+=exp(-pow((p.y-342.0)/32.0,2.0))*0.0017;
        layer+=exp(-pow((p.y-420.0)/46.0,2.0))*0.0009;
        float particulate=0.68+0.32*noise(p*vec3(0.006,0.016,0.004));
        float opacity=1.0-exp(-dt*layer*particulate*uAir.y);
        float light=pollutedLight(p);
        vec3 color=mix(vec3(0.095,0.092,0.077),mix(vec3(0.34,0.31,0.25),vec3(0.59,0.405,0.155),uLight.w),light);
        scatter+=trans*opacity*color;trans*=1.0-opacity;
    }
    return col*trans+scatter;
}

vec4 cloudsFbm( in vec3 pos )
{
    return fbmd_8(pos*0.0015+vec3(2.0,1.1,1.0)+0.07*vec3(iTime,0.5*iTime,-0.15*iTime));
}

vec4 cloudsMap( in vec3 pos, out float nnd )
{
    float d = abs(pos.y-900.0)-40.0;
    vec3 gra = vec3(0.0,sign(pos.y-900.0),0.0);
    
    vec4 n = cloudsFbm(pos);
    d += 400.0*n.x * (0.7+0.3*gra.y);
    
    if( d>0.0 ) return vec4(-d,0.0,0.0,0.0);
    
    nnd = -d;
    d = min(-d/100.0,0.25);

    
    return vec4( d, gra );
}

float cloudsShadowFlat( in vec3 ro, in vec3 rd )
{
    float t = (900.0-ro.y)/rd.y;
    if( t<0.0 ) return 1.0;
    vec3 pos = ro + rd*t;
    return cloudsFbm(pos).x;
}

float terrainShadow( in vec3 ro, in vec3 rd, in float mint );

vec4 renderClouds( in vec3 ro, in vec3 rd, float tmin, float tmax, inout float resT, in vec2 px )
{
    vec4 sum = vec4(0.0);

    // Cloud bounds.
    float tl = ( 600.0-ro.y)/rd.y;
    float th = (1200.0-ro.y)/rd.y;
    if( tl>0.0 ) tmin = max( tmin, tl ); else return sum;
    if( th>0.0 ) tmax = min( tmax, th );
    if(tmin>=tmax)return sum;

    float t = tmin;

    float lastT = -1.0;
    float thickness = 0.0;
    for(int i=ZERO; i<(QUALITY_LOW==1?64:128); i++)
    {
        vec3  pos = ro + t*rd;
        float nnd;
        vec4  denGra = cloudsMap( pos, nnd );
        float den = denGra.x;
        float dt = max(0.2,(QUALITY_LOW==1?0.018:0.011)*t);

        if( den>0.001 )
        {
            float kk;
            cloudsMap( pos+kSunDir*70.0, kk );
            float sha = 1.0-smoothstep(-200.0,200.0,kk); sha *= 1.5;
            
            vec3 nor = normalize(denGra.yzw);
            float dif = clamp( 0.4+0.6*dot(nor,kSunDir), 0.0, 1.0 )*sha;
            float fre = clamp( 1.0+dot(nor,rd), 0.0, 1.0 )*sha;
            float occ = 0.2+0.7*max(1.0-kk/200.0,0.0) + 0.1*(1.0-den);
            // lighting
            vec3 lin  = vec3(0.0);
                 lin += vec3(0.40,0.43,0.44)*0.7*(0.5+0.5*nor.y)*occ;
                 lin += vec3(0.22,0.25,0.34)*1.0*(0.5-0.5*nor.y)*occ;
                 lin += vec3(1.00,0.74,0.37)*1.7*dif*occ + 0.1;

            // color
            vec3 col = vec3(0.8,0.8,0.8)*0.45;

            col *= lin;

            col = fog( col, t );

            // front to back blending
            float alp = clamp(den*0.5*0.125*dt,0.0,1.0);
            col.rgb *= alp;
            sum = sum + vec4(col,alp)*(1.0-sum.a);

            thickness += dt*den;
            if( lastT<0.0 ) lastT = t;
        }
        else
        {
            dt = abs(den)+0.2;

        }
        t += dt;
        if( sum.a>0.995 || t>tmax ) break;
    }

    if( lastT>0.0 ) resT = min(resT,lastT);

    
    
    // Glare is applied after cloud compositing.

    return clamp( sum, 0.0, 1.0 );
}

//------------------------------------------------------------------------------------------
// terrain
//------------------------------------------------------------------------------------------

// Appalachian ridge heightfield and analytic gradient.
vec3 ridgeField(vec2 p)
{
    vec3 w = noised(p*vec2(0.0012,0.0015)+vec2(6.2,3.7));
    vec2 dw = w.yz*vec2(0.0012,0.0015);
    float phase = p.y*0.010 + p.x*0.0038 + 1.8*w.x;
    vec2 dp = vec2(0.0038,0.010)+1.8*dw;
    float fold = sin(phase);
    float h = 235.0 + 72.0*fold;
    vec2 d = 72.0*cos(phase)*dp;
    vec3 n = noised(p*vec2(0.003,0.004)+vec2(8.1,2.3));
    h += 48.0*n.x; d += 48.0*n.yz*vec2(0.003,0.004);
    vec3 fine = noised(p*0.012+vec2(1.7,3.4));
    h += 9.0*fine.x; d += 9.0*fine.yz*0.012;
    // Broad valley and rising distant range. Analytic derivatives include both.
    float v = p.x*0.002 + 0.55*sin(p.y*0.002);
    float valley = exp(-v*v);
    h -= 30.0*valley;
    d += 60.0*v*valley*vec2(0.002,0.0011*cos(p.y*0.002));
    vec2 rise=smoothstepd(200.0,2400.0,-p.y);
    h += 310.0*rise.x; d.y -= 310.0*rise.y;
    return vec3(h,d);
}
vec2 terrainMap(in vec2 p) { return vec2(ridgeField(p).x,0.15); }
vec4 terrainMapD(in vec2 p)
{
    vec3 e=ridgeField(p);
    return vec4(e.x,normalize(vec3(-e.y,1.0,-e.z)));
}

vec3 terrainNormal( in vec2 pos )
{
#if 1
    return terrainMapD(pos).yzw;
#else
    vec2 e = vec2(0.03,0.0);
    return normalize( vec3(terrainMap(pos-e.xy).x - terrainMap(pos+e.xy).x,
                           2.0*e.x,
                           terrainMap(pos-e.yx).x - terrainMap(pos+e.yx).x ) );
#endif
}

float terrainShadow( in vec3 ro, in vec3 rd, in float mint )
{
    float res = 1.0;
    float t = mint;
#ifdef LOWQUALITY
    for( int i=ZERO; i<32; i++ )
    {
        vec3  pos = ro + t*rd;
        vec2  env = terrainMap( pos.xz );
        float hei = pos.y - env.x;
        res = min( res, 32.0*hei/t );
        if( res<0.0001 || pos.y>kMaxHeight ) break;
        t += clamp( hei, 2.0+t*0.1, 100.0 );
    }
#else
    for( int i=ZERO; i<128; i++ )
    {
        vec3  pos = ro + t*rd;
        vec2  env = terrainMap( pos.xz );
        float hei = pos.y - env.x;
        res = min( res, 32.0*hei/t );
        if( res<0.0001 || pos.y>kMaxHeight  ) break;
        t += clamp( hei, 0.5+t*0.05, 25.0 );
    }
#endif
    return clamp( res, 0.0, 1.0 );
}

vec2 raymarchTerrain( in vec3 ro, in vec3 rd, float tmin, float tmax )
{
    // bounding plane
    float tp = (kMaxHeight+kMaxTreeHeight-ro.y)/rd.y;
    if( tp>0.0 ) tmax = min( tmax, tp );
    
    // raymarch
    float dis, th;
    float t2 = -1.0;
    float t = tmin;
    float ot = t;
    float odis = 0.0;
    float odis2 = 0.0;
    for( int i=ZERO; i<400; i++ )
    {
        th = 0.001*t;

        vec3  pos = ro + t*rd;
        vec2  env = terrainMap( pos.xz );
        float hei = env.x;

        // tree envelope
        float dis2 = pos.y - (hei+kMaxTreeHeight*1.1);
        if( dis2<th )
        {
            if( t2<0.0 )
            {
                t2 = ot + (th-odis2)*(t-ot)/(dis2-odis2); // linear interpolation for better accuracy
            }
        }
        odis2 = dis2;
        
        // terrain
        dis = pos.y - hei;
        if( dis<th ) break;
        
        ot = t;
        odis = dis;
        t += dis*0.8*(1.0-0.75*env.y); // slow down in step areas
        if( t>tmax ) break;
    }

    if( t>tmax ) t = -1.0;
    else t = ot + (th-odis)*(t-ot)/(dis-odis); // linear interpolation for better accuracy
    
    return vec2(t,t2);
}

//------------------------------------------------------------------------------------------
// trees
//------------------------------------------------------------------------------------------

// Clearings and haul roads.
float damageField(vec2 p)
{
    vec2 q=p-vec2(32.0,-290.0);q.x+=0.30*q.y+12.0*sin(q.y*0.028);
    float brokenEdge=0.16*noise(p*0.10)+0.07*noise(p*0.29);
    float pit=1.0-smoothstep(0.72,1.12,length(q/vec2(45,130))+brokenEdge);
    vec2 r=p-vec2(-200,-510);r.x-=0.6*r.y;
    pit=max(pit,1.0-smoothstep(0.75,1.1,length(r/vec2(65,100))));
    vec2 u=p-vec2(270,-650);u.x+=0.8*u.y;
    pit=max(pit,1.0-smoothstep(0.8,1.12,length(u/vec2(70,160))));
    float road=abs(p.x-(45.0+75.0*sin(p.y*0.007)+0.12*p.y));
    road=(1.0-smoothstep(4.0,10.0,road))*smoothstep(-1000.0,-850.0,p.y)*(1.0-smoothstep(-110.0,-60.0,p.y));
    return max(pit,road);
}

float treesMap( in vec3 p, in float rt, out float oHei, out float oMat, out float oDis )
{
    oHei = 1.0;
    oDis = 0.0;
    oMat = 0.0;
        
    float base = terrainMap(p.xz).x;
    float damage=damageField(p.xz);
    if(damage>0.68)return clamp(p.y-base,0.8,4.0);
    
    float bb = fbm_4(p.xz*0.075);

    float d = 20.0;
    vec2 n = floor( p.xz/4.0 );
    vec2 f = fract( p.xz/4.0 );
    for( int j=0; j<=1; j++ )
    for( int i=0; i<=1; i++ )
    {
        vec2  g = vec2( float(i), float(j) ) - step(f,vec2(0.5));
        vec2  o = hash2( n + g );
        vec2  v = hash2( n + g + vec2(13.1,71.7) );
        vec2  r = g - f + o;

        float height = kMaxTreeHeight * (0.4+0.8*v.x)*(1.0-0.5*damage);
        float width = 1.25 + 0.4*v.x + 0.45*v.y;

        if( bb<-0.18 ) width *= 0.65; else height *= 0.78;
        
        vec3  q = vec3(r.x*2.0,p.y-base-height*0.5,r.y*2.0);
        
        float k = sdEllipsoidY( q, vec2(width,0.5*height) );

        if( k<d )
        {
            d = k;
            oMat = 0.5*hash1(n+g+111.0);
            if( bb>0.0 ) oMat += 0.5;
            oHei = (p.y - base)/height;
            oHei *= 0.5 + 0.5*length(q) / width;
        }
    }

    // distort ellipsoids to make them look like trees (works only in the distance really)
    if( rt<1200.0 )
    {
        p.y -= 600.0;
        // Crown displacement with screen-space detail attenuation.

        float footprint = 2.0*rt/(iResolution.y*uFocal);
        float detail = 1.0-smoothstep(0.06,0.28,footprint);
        float lobes = fbm_4(p*(1.65+0.40*oMat));
        lobes=lobes*lobes;
        float fine = noise(p*3.0)*detail;
        float att = 1.0-smoothstep(300.0,1200.0,rt);
        d += (1.70*lobes+0.04*fine)*att;
        oDis = lobes*att;
    }
    
    return d;
}

float treesShadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.02;
#ifdef LOWQUALITY
    for( int i=ZERO; i<(QUALITY_LOW==1?24:64); i++ )
    {
        float kk1, kk2, kk3;
        vec3 pos = ro + rd*t;
        float h = treesMap( pos, t, kk1, kk2, kk3 );
        res = min( res, 32.0*h/t );
        t += h;
        if( res<0.001 || t>50.0 || pos.y>kMaxHeight+kMaxTreeHeight ) break;
    }
#else
    for( int i=ZERO; i<150; i++ )
    {
        float kk1, kk2, kk3;
        float h = treesMap( ro + rd*t, t, kk1, kk2, kk3 );
        res = min( res, 32.0*h/t );
        t += h;
        if( res<0.001 || t>120.0 ) break;
    }
#endif
    return clamp( res, 0.0, 1.0 );
}

vec3 treesNormal( in vec3 pos, in float t )
{
    float kk1, kk2, kk3;
#if 0
    const float eps = 0.005;
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*treesMap( pos + e.xyy, t, kk1, kk2, kk3 ) +
                      e.yyx*treesMap( pos + e.yyx, t, kk1, kk2, kk3 ) +
                      e.yxy*treesMap( pos + e.yxy, t, kk1, kk2, kk3 ) +
                      e.xxx*treesMap( pos + e.xxx, t, kk1, kk2, kk3 ) );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        float eps=clamp(0.45*t/(iResolution.y*uFocal),0.025,0.10);
        n += e*treesMap(pos+eps*e, t, kk1, kk2, kk3);
    }
    return normalize(n);
#endif
}

//------------------------------------------------------------------------------------------
// sky
//------------------------------------------------------------------------------------------

vec3 renderSky( in vec3 ro, in vec3 rd )
{
    // background sky

    vec3 col = mix(vec3(0.32,0.46,0.65),vec3(0.22,0.24,0.25),uAir.w) - rd.y*0.10;

    // clouds
    float t = (2500.0-ro.y)/rd.y;
    if( t>0.0 )
    {
        vec2 uv = (ro+t*rd).xz;
        float cl = fbm_9( uv*0.00104 );
        float dl = smoothstep(-0.2,0.6,cl);
        col = mix( col, vec3(1.0), 0.12*dl );
    }
    
    // sun glare
    float sun = clamp( dot(kSunDir,rd), 0.0, 1.0 );
    col += 0.2*vec3(1.0,0.6,0.3)*pow( sun, 32.0 );
    
    return col;
}

//------------------------------------------------------------------------------------------
// main image making function
//------------------------------------------------------------------------------------------

// Tower data: x, z, panel height above terrain, panel width.
// Atlas order: Massey, Arch, Patriot, CONSOL, Murray, DuPont.

const int TOWER_COUNT=48;
uniform vec4 towerData[TOWER_COUNT];
const float towerYaw[TOWER_COUNT]=float[TOWER_COUNT](0.080,-0.080,-0.180,0.160,-0.140,-0.250,0.286,-0.019,0.475,0.170,-0.136,0.118,-0.187,-0.493,0.002,-0.304,0.190,0.125,-0.181,0.314,0.008,0.502,0.197,-0.349,0.146,-0.160,-0.466,0.029,-0.037,0.458,0.152,-0.154,0.341,-0.205,-0.510,-0.016,-0.322,0.173,0.107,-0.198,0.296,-0.010,0.485,-0.061,-0.366,0.128,-0.178,-0.483);
const int towerBrand[TOWER_COUNT]=int[TOWER_COUNT](0,1,2,3,4,5,2,1,0,5,4,3,2,1,0,5,4,3,2,1,0,5,4,3,2,1,0,5,4,3,2,1,0,5,4,3,2,1,0,5,4,3,2,1,0,5,4,3);

vec3 signIdColor(int id){return 0.4+0.5*cos(vec3(0,2,4)+float(id)*1.3);}
// Slab intersection with face normal. Handles parallel rays without NaNs.
float hitBox(vec3 ro,vec3 rd,vec3 halfSize,out vec3 normal)
{
    vec3 inv=sign(rd)/max(abs(rd),vec3(1e-7));
    vec3 a=(-halfSize-ro)*inv,b=(halfSize-ro)*inv;
    vec3 lo=min(a,b),hi=max(a,b);
    float tn=max(lo.x,max(lo.y,lo.z)),tf=min(hi.x,min(hi.y,hi.z));
    normal=-sign(rd)*step(lo.yzx,lo.xyz)*step(lo.zxy,lo.xyz);
    return tf>=max(tn,0.0)?max(tn,0.0):-1.0;
}
void boxCandidate(vec3 ro,vec3 rd,vec3 c,vec3 size,inout float best,inout vec3 norm)
{
    vec3 n;float t=hitBox(ro-c,rd,size,n);
    if(t>0.0&&t<best){best=t;norm=n;}
}
// Intersect a rectangular steel beam.
void beamCandidate(vec3 ro,vec3 rd,vec3 a,vec3 b,float radius,inout float best,inout vec3 normal)
{
    vec3 y=normalize(b-a),x=normalize(cross(y,abs(y.z)<0.9?vec3(0,0,1):vec3(1,0,0))),z=cross(x,y);
    mat3 m=mat3(x,y,z);vec3 n;
    float t=hitBox(transpose(m)*(ro-(a+b)*0.5),transpose(m)*rd,vec3(radius,length(b-a)*0.5,radius),n);
    if(t>0.0&&t<best){best=t;normal=m*n;}
}
float raySigns(vec3 ro,vec3 rd,float limit,out vec3 normal,out vec2 uv,out int id,out int material)
{
    float best=limit;id=-1;material=0;
    #if ENABLE_SIGNS
    for(int j=0;j<TOWER_COUNT;j++)
    {
        if(j>=uTowerCount)break;
        vec4 d=towerData[j];float h=d.z,w=d.w*0.5,ph=d.w*0.25;
        // Horizontal ray/cylinder rejection avoids evaluating terrain for most instances.
        float along=max(0.0,dot(d.xy-ro.xz,rd.xz)/max(dot(rd.xz,rd.xz),0.00001));
        if(along>best+d.w || length(ro.xz+rd.xz*along-d.xy)>d.w*0.62+7.0)continue;
        vec3 origin=vec3(d.x,terrainMap(d.xy).x,d.y);
        float c=cos(towerYaw[j]),s=sin(towerYaw[j]);
        mat3 rot=mat3(c,0,-s,0,1,0,s,0,c);
        vec3 r=transpose(rot)*(ro-origin),v=transpose(rot)*rd,n;
        float bound=hitBox(r-vec3(0,(h+ph-48.0)*0.5,0),v,vec3(w+2.0,(h+ph+48.0)*0.5+2.0,6.0),n);
        if(bound<0.0||bound>best)continue;
        float before=best;
        float panel=hitBox(r-vec3(0,h,0),v,vec3(w,ph,0.65),n);
        if(panel>0.0&&panel<best){
            best=panel;normal=rot*n;id=j;
            vec3 p=r+v*panel;
            uv=p.xy-vec2(0,h);uv=uv/vec2(2.0*w,2.0*ph)+0.5;
            material=n.z>0.5?1:0;
        }
        float steel=best;vec3 sn=vec3(0,1,0);
        // Panel rim and backing.
        for(int side=0;side<2;side++){
            float sg=float(side)*2.0-1.0;
            boxCandidate(r,v,vec3(sg*w,h,0.85),vec3(0.55,ph+0.6,0.35),steel,sn);
            boxCandidate(r,v,vec3(0,h+sg*ph,0.85),vec3(w+0.55,0.55,0.35),steel,sn);
        }
        float legW=w*0.80,top=h-ph,base=-12.0;
        float rad=max(0.22,d.w*0.009);
        // Sample terrain beneath each footing.
        for(int k=0;k<4;k++){
            float x=(k%2==0?-1.0:1.0)*legW,z=(k<2?-1.0:1.0)*3.5;
            vec3 footXZ=origin+rot*vec3(x,0,z);
            float foot=terrainMap(footXZ.xz).x-origin.y-0.7;
            beamCandidate(r,v,vec3(x,foot,z),vec3(x*0.95,top,z),rad,steel,sn);
            boxCandidate(r,v,vec3(x,foot+0.3,z),vec3(rad*3.0,0.9,rad*3.0),steel,sn);
        }
        // LOD removes rear cross braces, keeps all main legs and front silhouettes.
        int levels=length(origin-ro)>650.0?3:5;
        for(int k=0;k<5;k++){
            if(k>=levels)break;
            float y0=mix(base,top,float(k)/float(levels)),y1=mix(base,top,float(k+1)/float(levels));
            for(int side=0;side<2;side++){
                if(side==0&&(QUALITY_LOW==1||length(origin-ro)>600.0))continue;
                float z=(side==0?-1.0:1.0)*3.5;
                beamCandidate(r,v,vec3(-legW,y0,z),vec3(legW,y1,z),rad*0.50,steel,sn);
                beamCandidate(r,v,vec3(legW,y0,z),vec3(-legW,y1,z),rad*0.50,steel,sn);
                beamCandidate(r,v,vec3(-legW,y1,z),vec3(legW,y1,z),rad*0.65,steel,sn);
            }
            for(int side=0;side<2;side++){
                float x=(side==0?-1.0:1.0)*legW;
                beamCandidate(r,v,vec3(x,y0,-3.5),vec3(x,y1,3.5),rad*0.5,steel,sn);
            }
        }
        if(steel<best){best=steel;normal=rot*sn;id=j;material=0;}
    }
    #endif
    return best;
}
// Panel shadow rays: horizontal rejection precedes terrain and box evaluation.
// Foliage supplies its own soft crown shadows; subpixel lattice shadows are omitted.
float towerShadow(vec3 ro,vec3 rd)
{
    #if ENABLE_SIGNS
    for(int j=0;j<TOWER_COUNT;j++){
        if(j>=uTowerCount)break;
        vec4 d=towerData[j];
        float along=max(0.0,dot(d.xy-ro.xz,rd.xz)/max(dot(rd.xz,rd.xz),0.00001));
        if(length(ro.xz+rd.xz*along-d.xy)>d.w*0.55+2.0)continue;
        vec3 origin=vec3(d.x,terrainMap(d.xy).x+d.z,d.y);
        float c=cos(towerYaw[j]),s=sin(towerYaw[j]);
        mat3 inv=transpose(mat3(c,0,-s,0,1,0,s,0,c));
        vec3 n;
        float t=hitBox(inv*(ro-origin),inv*rd,vec3(d.w*0.5,d.w*0.25,0.65),n);
        if(t>0.05)return 0.0;
    }
    #endif
    return 1.0;
}

vec3 shadeSign(vec3 ro,vec3 rd,float t,vec3 n,vec2 uv,int id,int material)
{
    vec3 pos=ro+rd*t;
    float shadow=terrainShadow(pos+kSunDir*0.15,kSunDir,0.2)*towerShadow(pos+kSunDir*0.2,kSunDir);
    float dif=max(dot(n,kSunDir),0.0);
    vec3 light=uLight.y*vec3(0.52,0.48,0.36)*(0.80+0.20*n.y)+uLight.x*vec3(1.6,1.20,0.78)*dif*shadow*pollutedLight(pos);
    vec3 albedo=vec3(0.075,0.060,0.048);
    if(material==1){
        // Atlas is uploaded flipY=true. Half-texel tile inset avoids neighbor bleed.
        int brand=towerBrand[id];
        vec2 cell=vec2(float(brand%3),float(1-brand/3));
        vec2 sampleUV=(cell+clamp(uv,vec2(0.001),vec2(0.999)))/vec2(3,2);
        vec3 srgb=texture(iChannel1,sampleUV).rgb;
        albedo=mix(srgb/12.92,pow((srgb+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),srgb));
        float edge=min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y));
        float rust=(1.0-smoothstep(0.008,0.15,edge))*(0.5+0.5*noise(vec2(uv.x*130.0,uv.y*25.0)));
        albedo=mix(albedo,vec3(0.17,0.055,0.018),(0.65+0.25*hash1(float(id)))*rust);
        // Panel fasteners.
        vec2 bolt=abs(uv-0.5)-vec2(0.47,0.44);
        albedo*=1.0-0.65*(1.0-smoothstep(0.005,0.011,length(bolt)));
    }else{
        albedo=mix(albedo,vec3(0.18,0.055,0.016),smoothstep(-0.2,0.55,noise(pos*0.4+float(id))));
        albedo*=0.55+0.45*noise(pos*0.8);
    }
    vec3 col=albedo*light;
    col+=vec3(0.65,0.45,0.25)*pow(max(dot(reflect(rd,n),kSunDir),0.0),24.0)*0.22;
    if(DEBUG_MODE==4)col=signIdColor(id);
    if(DEBUG_MODE==5)col=vec3(t/1500.0);
    return valleyFog(col,ro,rd,t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if(DEBUG_MODE==6){
        vec2 x=(fragCoord/iResolution.xy-0.5)*6000.0;
        vec3 e=ridgeField(x);float eps=0.25;
        vec2 numerical=vec2(ridgeField(x+vec2(eps,0)).x-ridgeField(x-vec2(eps,0)).x,
                            ridgeField(x+vec2(0,eps)).x-ridgeField(x-vec2(0,eps)).x)/(2.0*eps);
        fragColor=vec4(vec3(length(numerical-e.yz)*100.0),1);return;
    }
    vec2 o = hash2( vec2(iFrame,1) ) - 0.5;
    
    vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/ iResolution.y;
    
    //----------------------------------
    // setup
    //----------------------------------

    // camera
    float time = iTime;
    vec3 ro = uEye;
    vec3 ta = uTarget;

    
    ro += float(CAMERA_ALT)*vec3(6.0,12.0,0.0);
    ta += float(CAMERA_ALT)*vec3(6.0,12.0,0.0);
    ro.x -= float(CAMERA_MOTION)*8.0*sin(0.08*time);
    ta.x -= float(CAMERA_MOTION)*8.6*sin(0.08*time);

    // ray
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = ca * normalize( vec3(p,uFocal));

    float resT = 7000.0;

    //----------------------------------
    // sky
    //----------------------------------

    vec3 col = renderSky( ro, rd );

    //----------------------------------
    // raycast terrain and tree envelope
    //----------------------------------
    {
    const float tmax = 7000.0;
    int   obj = 0;
    vec2 t = raymarchTerrain( ro, rd, 15.0, tmax );
    if( t.x>0.0 )
    {
        resT = t.x;
        obj = 1;
    }

    //----------------------------------
    // raycast trees, if needed
    //----------------------------------
    float hei, mid, displa;
    
    if( t.y>0.0 && DEBUG_MODE!=7 && DEBUG_MODE!=10 )
    {
        float tf = t.y;
        float tfMax = (t.x>0.0)?t.x:tmax;
        for(int i=ZERO; i<64; i++)
        {
            vec3  pos = ro + tf*rd;
            float dis = treesMap( pos, tf, hei, mid, displa);
            if( dis<(0.000125*tf) ) break;
            tf += dis;
            if( tf>tfMax ) break;
        }
        if( tf<tfMax )
        {
            resT = tf;
            obj = 2;
        }
    }

    //----------------------------------
    // shade
    //----------------------------------
    if( obj>0 )
    {
        vec3 pos  = ro + resT*rd;
        vec3 epos = pos + vec3(0.0,4.8,0.0);

        float sha1  = terrainShadow( pos+vec3(0,0.02,0), kSunDir, 0.02 );
        sha1 *= towerShadow(pos+kSunDir*0.2,kSunDir)*pollutedLight(pos);

        sha1 *= smoothstep(-0.325,-0.075,cloudsShadowFlat(epos, kSunDir));
        
        #ifndef LOWQUALITY
        float sha2  = treesShadow( pos+vec3(0,0.02,0), kSunDir );
        #endif

        vec3 tnor = terrainNormal( pos.xz );
        vec3 nor;
        
        vec3 speC = vec3(1.0);
        //----------------------------------
        // terrain
        //----------------------------------
        if( obj==1 )
        {
            // bump map
            nor = normalize( tnor + 0.8*(1.0-abs(tnor.y))*0.8*fbmd_7( (pos-vec3(0,600,0))*0.15*vec3(1.0,0.2,1.0) ).yzw );

            col = vec3(0.18,0.12,0.10)*.85;

            col = 1.0*mix( col, vec3(0.1,0.1,0.0)*0.2, smoothstep(0.7,0.9,nor.y) );
            float damage=damageField(pos.xz);
            float bench=0.88+0.12*smoothstep(0.12,0.35,fract(pos.y*0.19));
            float grain=0.72+0.20*noise(pos*0.85)+0.08*noise(pos*3.0);
            float rills=0.80+0.20*abs(sin(pos.x*0.48+2.0*noise(pos.xz*0.09)));
            vec3 spoil=mix(vec3(0.17,0.10,0.045),vec3(0.36,0.23,0.11),0.5+0.5*noise(pos.xz*0.14))*bench*grain*rills;
            nor=normalize(nor+damage*0.22*fbmd_7(pos*0.35).yzw);
            col=mix(col,spoil,damage);
            float dif = clamp( dot( nor, kSunDir), 0.0, 1.0 );
            dif *= sha1;
            #ifndef LOWQUALITY
            dif *= sha2;
            #endif

            float bac = clamp( dot(normalize(vec3(-kSunDir.x,0.0,-kSunDir.z)),nor), 0.0, 1.0 );
            float foc = 0.55+0.45*clamp(pos.y/500.0,0.0,1.0);
            float dom = clamp( 0.5 + 0.5*nor.y, 0.0, 1.0 );
            vec3  lin  = 1.0*0.2*mix(0.1*vec3(0.1,0.2,0.1),vec3(0.7,0.9,1.5)*3.0,dom)*foc;
                  lin += 1.0*8.5*vec3(1.0,0.9,0.8)*dif;
                  lin += 1.0*0.27*vec3(1.1,1.0,0.9)*bac*foc;
            speC = (1.0-damage)*vec3(4.0)*dif*smoothstep(20.0,0.0,abs(pos.y/2.0-310.0)-20.0);
            lin=mix(lin,vec3(0.38,0.30,0.19)+vec3(2.4,1.8,0.8)*dif,damage);

            col *= lin;
        }
        //----------------------------------
        // trees
        //----------------------------------
        else //if( obj==2 )
        {
            vec3 gnor = treesNormal( pos, resT );
            
            nor = normalize( gnor + 2.0*tnor );

            // --- lighting ---
            vec3  ref = reflect(rd,nor);
            float occ = clamp(hei,0.0,1.0) * pow(clamp(1.0-1.65*displa,0.25,1.0),2.0);
            float dif = clamp( 0.1 + 0.9*dot( nor, kSunDir), 0.0, 1.0 );
            dif *= sha1;
            if( dif>0.0001 )
            {
                float a = clamp( 0.5+0.5*dot(tnor,kSunDir), 0.0, 1.0);
                a = a*a;
                a *= occ;
                a *= 0.6;
                a *= smoothstep(60.0,200.0,resT);
                // tree shadows with fake transmission
                #ifdef LOWQUALITY
                float sha2  = treesShadow( pos+kSunDir*0.1, kSunDir );
                #endif
                dif *= a+(1.0-a)*sha2;
            }
            float dom = clamp( 0.5 + 0.5*nor.y, 0.0, 1.0 );
            float bac = clamp( 0.5+0.5*dot(normalize(vec3(-kSunDir.x,0.0,-kSunDir.z)),nor), 0.0, 1.0 );
            float fre = clamp(1.0+dot(nor,rd),0.0,1.0);

            // --- lights ---
            vec3 lin  = 6.1*uLight.x*mix(vec3(1.14,1.0,0.73),vec3(1.15,0.88,0.46),uLight.w)*dif*occ*(2.5-1.5*smoothstep(0.0,120.0,resT));
                 lin += 0.65*uLight.y*mix(0.1*vec3(0.1,0.2,0.0),vec3(0.52,0.53,0.47),dom*occ);
                 lin += 0.07*vec3(1.0,1.0,0.9)*bac*occ;
                 lin += 1.10*vec3(0.9,1.0,0.8)*pow(fre,5.0)*occ*(1.0-smoothstep(100.0,200.0,resT));
            speC = dif*vec3(1.0,1.1,1.5)*1.2;

            // --- material ---
            float region = 0.5+0.5*fbm_4(pos.xz*0.018);
            float species = clamp(0.45*mid+1.8*(region-0.3)+0.00015*pos.y+0.1*tnor.x,0.0,1.0);
            vec3 gold=vec3(0.40,0.22,0.028), copper=vec3(0.38,0.105,0.012);
            vec3 red=vec3(0.26,0.035,0.012), green=vec3(0.045,0.095,0.025);
            col = mix(green,gold,smoothstep(0.25,0.31,species));
            col = mix(col,copper,smoothstep(0.49,0.55,species));
            col = mix(col,red,smoothstep(0.77,0.83,species));
            col *= 0.89+0.11*noise(pos*0.45);
            float unhealthy=max(damageField(pos.xz)*0.65,0.30*smoothstep(-0.2,0.3,noise(pos.xz*0.007)));
            col=mix(col,vec3(dot(col,vec3(0.25,0.6,0.15)))*vec3(0.8,0.7,0.46),unhealthy);
            if(DEBUG_MODE==3) { lin=vec3(1.8); }
            col *= lin;
        }

        // spec
        vec3  ref = reflect(rd,nor);
        float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
        float spe = 3.0*pow( clamp(dot(ref,kSunDir),0.0, 1.0), 9.0 )*(0.05+0.95*pow(fre,5.0));
        col += 0.28*spe*speC;

        if(DEBUG_MODE==1) col=tnor*0.5+0.5;
        if(DEBUG_MODE==2) col=vec3(resT/3500.0);
        col = valleyFog(col,ro,rd,resT);
    }
    }

    vec3 signNormal;vec2 signUV;int signId,signMaterial;
    float signT=raySigns(ro,rd,DEBUG_MODE==9?7000.0:resT,signNormal,signUV,signId,signMaterial);
    if(signId>=0){resT=signT;col=shadeSign(ro,rd,resT,signNormal,signUV,signId,signMaterial);}

    float isCloud = 0.0;
    //----------------------------------
    // clouds
    //----------------------------------
    {
        vec4 res = renderClouds( ro, rd, 0.0, resT, resT, fragCoord );
        col = col*(1.0-res.w) + res.xyz;
        isCloud = res.w;
    }

    //----------------------------------
    // final
    //----------------------------------
    
    // sun glare
    float sun = clamp( dot(kSunDir,rd), 0.0, 1.0 );
    col += 0.12*vec3(0.8,0.4,0.2)*pow( sun, 4.0 );
 

    // gamma

    col = pow( clamp(col*1.03*uLight.z-0.025,0.0,1.0), vec3(0.4545) );

    // contrast
    col = col*col*(3.0-2.0*col);
    
    // color grade
    col = pow( col, vec3(1.0,0.92,1.0) );   // soft green
    col *= mix(vec3(1.0,0.99,0.97),vec3(1.02,0.98,0.85),uAir.w);            // tint red
    col.z = col.z+0.025;                      // bias blue
    
    //------------------------------------------
    // reproject from previous frame and average
    //------------------------------------------

    if(DEBUG_MODE>=8){fragColor=vec4(signId>=0?vec3(float(towerBrand[signId]+1)/6.0,signMaterial==1?1.0:0.0,float(signId+1)/float(TOWER_COUNT)):vec3(0),resT);return;}

    mat3x4 oldCam = mat3x4( texelFetch(iChannel0,ivec2(0,0), 0),
                            texelFetch(iChannel0,ivec2(1,0), 0),
                            texelFetch(iChannel0,ivec2(2,0), 0) );
    
    // world space
    vec4 wpos = vec4(ro + rd*resT,1.0);
    // camera space
    vec3 cpos = (wpos*oldCam); // note inverse multiply
    // ndc space
    vec2 npos = uFocal * cpos.xy / cpos.z;
    // screen space
    vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);
    // undo dither
    spos -= o/iResolution.xy;
    // raster space
    vec2 rpos = spos * iResolution.xy;
    
    if( rpos.y<1.0 && rpos.x<3.0 )
    {
    }
    else
    {
        vec4 history=textureLod(iChannel0,spos,0.0);
        float expected=length(cpos);
        bool valid=iFrame>0 && all(greaterThan(spos,vec2(0.0))) && all(lessThan(spos,vec2(1.0)))
                    && abs(history.a-expected)<max(0.65,expected*0.006);
        vec3 ocol=valid?history.rgb:col;
        col=mix(ocol,col,max(0.16+0.74*isCloud,float(CAMERA_MOTION)*0.32));
    }

    //----------------------------------
    ivec2 ip = ivec2(fragCoord);
    if( ip.y==0 && ip.x<=2 )
    {
        fragColor = vec4( ca[ip.x], -dot(ca[ip.x],ro) );
    }
    else
    {
        fragColor = vec4( col, resT );
    }
}
