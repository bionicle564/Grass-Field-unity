Shader "Custom/test"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _Seed("Seed", Vector) = (1,1,1,1)
    }

    SubShader
    {
        
        Cull off
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



            struct GrassData
            {
                float4 position;
            };

            StructuredBuffer<GrassData> _GrassBuffer;


            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                float4 pos : COLOR;
                half3 lightAmount : TEXCOORD2;
                nointerpolation uint index : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);


            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Position)
            UNITY_INSTANCING_BUFFER_END(Props)


            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END
            
            float random (float2 st) {
                return frac(sin(dot(st.xy,
                float2(12.9898,78.233)))
                * 43758.5453123);
            }

            float2 random2( float2 p ) {
                return frac(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453);
            }

            float noise (in float2 st) {
                float2 i = floor(st);
                float2 f = frac(st);

                // Four corners in 2D of a tile
                float a = random(i);
                float b = random(i + float2(1.0, 0.0));
                float c = random(i + float2(0.0, 1.0));
                float d = random(i + float2(1.0, 1.0));

                // Smooth Interpolation

                // Cubic Hermine Curve.  Same as SmoothStep()
                float2 u = f*f*(3.0-2.0*f);
                // u = smoothstep(0.,1.,f);

                // Mix 4 coorners percentages
                return lerp(a, b, u.x) +
                (c - a)* u.y * (1.0 - u.x) +
                (d - b) * u.x * u.y;
            }

            float circle(in float2 pos, in float radius)
            {
                return step(length(pos) - radius, 0);
            }

            float opSubtraction( float d1, float d2 ) { return max(d1,-d2); }


            float sdCircle(float2 p, float r)
            {
                return length(p) - r;
            }

            float sdGrassBlade2d(float2 p)
            {
                float dist = sdCircle(p - float2(1.7, -1.3), 2.0);
                dist = opSubtraction(dist, sdCircle(p - float2(1.7, -1.0), 1.8));
                dist = opSubtraction(dist, p.y + 1.0);
                dist = opSubtraction(dist, -p.x + 1.7);
                return dist;
            }

            float2x2 rotate2d(float _angle)
            {
                return float2x2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
            }

            float2x2 scale(float2 _scale)
            {
                return float2x2(_scale.x,0.0,
                0.0,_scale.y);
            }

            float4 RotateAroundYInDegrees (float4 vertex, float degrees) {
                float alpha = degrees * 3.14 / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(mul(m, vertex.xz), vertex.yw).xzyw;
            }

            Varyings vert(Attributes IN,uint instanceID : SV_InstanceID)
            {
                Varyings OUT;
                OUT.index = instanceID;
                UNITY_SETUP_INSTANCE_ID(IN);

                //float offset = UNITY_VERTEX_INPUT_INSTANCE_ID;

                GrassData data = _GrassBuffer[instanceID];

                float3 viewDir = GetViewForwardDir();
                float3 viewPos = GetCameraPositionWS();
                float inFrontOfCam = dot(viewPos, data.position.xyz - viewPos);

                if (inFrontOfCam < 0){
                    //should be gone
                }


                float randomHeight = noise(data.position.xz * float2(40.10-data.position.y,40.10+data.position.y) * .01);
                randomHeight*=3;
                float randomRot = noise(data.position.xz);

                float wind = random(data.position.xz);

                IN.positionOS = RotateAroundYInDegrees(IN.positionOS, 45.f);
                IN.normal = normalize(RotateAroundYInDegrees(IN.normal, 45.f));

                //random rotation
                randomRot *= 360;
                
                IN.positionOS = RotateAroundYInDegrees(IN.positionOS, randomRot);
                IN.normal = RotateAroundYInDegrees(IN.normal, randomRot);

                static const float2 directions[2] = {
                    float2(1,0),
                    float2(1,1)
                };


                if(IN.positionOS .y > 0){
                    for(int i=0;i<2;i++){
                        float2 dir = normalize(directions[i]); // wave direction (any vector on XZ)
                        float frequency = 1.0;                    // how many waves fit per unit
                        float amplitude = .3 + (i/2.f);                    // wave height
                        float steepness = 1.0;                    // how sharp the crests are
                        float speed = .5;                        // how fast the wave moves

                        // Get vertex position in XZ
                        float2 posXZ = IN.positionOS.xz * 1.5;

                        // Compute wave phase
                        float wavePhase = dot(dir, posXZ) * frequency + _Time.y * speed;

                        // Gerstner displacement
                        float waveHeight = sin(wavePhase) * amplitude;
                        float2 waveOffset = dir * cos(wavePhase) * amplitude * steepness;

                        // Apply displacements
                        IN.positionOS.xz += (waveOffset ) * IN.positionOS.y;
                        //IN.positionOS.x += ( _SinTime.w);
                    }
                    
                    IN.positionOS.y *= ((randomHeight));
                }

                
                float faceDot = dot(viewDir, IN.normal.xyz);
                // - means front face
                // + means back face
                
                faceDot *= 10;
                faceDot = faceDot / abs(faceDot);
                
                Light light = GetMainLight();

                
                IN.normal.xyz = -IN.normal.xyz * faceDot;
                

                OUT.lightAmount = LightingLambert(light.color, light.direction, IN.normal);


                //OUT.positionHCS = TransformObjectToHClip((IN.positionOS.xyz + (IN.normal.xyz * random(IN.uv.xy) * _SinTime.w * .001)));
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz + data.position);

                VertexPositionInputs posData = GetVertexPositionInputs(IN.positionOS.xyz + data.position.xyz); 
                OUT.pos.xyz = posData.positionWS;

                VertexNormalInputs normData = GetVertexNormalInputs(IN.positionOS + data.position.xyz);
                OUT.normal.xyz = IN.normal.xyz;
                
                //OUT.normal.x = randomHeight;


                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            
            half4 frag(Varyings IN) : SV_Target
            {
                GrassData data = _GrassBuffer[IN.index];
                
                float4 _Seed;
                
                float2 bladePos = float2(.0,.55);
                float2 bladePos2 = float2(.7,.55);
                float2 c = 0;

                float2 p;

                for(int i=0;i<20;i++)
                {
                    float n = noise(float2(-i,i+10));
                    //n = min(n, .1);
                    n-=1.5;

                    float2 bldPos = random2(bladePos + float2(n,0));
                    p = IN.uv.xy;
                    p-= bldPos;
                    
                    float uvSpace = mul(scale(float2(1,1)),IN.uv.xy);
                    
                    p = mul(rotate2d(-.3 + (noise(bldPos))), p);
                    
                    p = mul(scale(float2(1 - (2* (i%2)),1)),p); // flip every other blade

                    c +=  smoothstep(0.01,-.04,sdGrassBlade2d(p));

                }

                //green base
                float base = 1-sdCircle((IN.uv.xy * float2(1,1.5)) + float2(-.5,.7), .3);

                base = smoothstep(.2,.3,base);
                c += base;

                float alpha = step(.7, c);

                if (alpha < 1)
                {
                    discard;
                }
                //c +=  sdGrassBlade2d(p + float2(.5,.5));
                //c = IN.uv.xy;


                // get the lighter tones inside the grassblade
                float highlights = smoothstep(.2, 10.1, c);
                highlights -= base;
                highlights = smoothstep(0.0, 1, highlights);
                highlights*=10;

                c = smoothstep(.2, 1.1, c);

                //c = highlights; // testing 
                float preDis = data.position.y;

                preDis -= .1;
                

                //half4 color = half4(highlights,c.y,0,1);
                half4 color = half4(highlights,c.y,0,1);

                half4 color2 = half4(.1,.09,0,1);

                color += color2 * step(.9,preDis);

                color *=.55;

                float brightness = .3;


                brightness += IN.lightAmount.x;
                //brightness = smoothstep(.3, 1, brightness);

                color *= brightness;
                float o = IN.normal.x;
                o = smoothstep(0,3,o);
                //color.xyz = float3(o,o,o);
                //color.xyz = IN.normal.xyz;
                return color;
            }
            ENDHLSL
        }

        
    }
}
