Shader "Custom/test"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        
    }

    SubShader
    {
        
        Cull off
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            HLSLPROGRAM
            #pragma target 3.0
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                float4 pos : COLOR;
                
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

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

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                //OUT.positionHCS = TransformObjectToHClip((IN.positionOS.xyz + (IN.normal.xyz * random(IN.uv.xy) * _SinTime.w * .001)));
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.pos.xyz = IN.positionOS.xyz;
                OUT.normal =  IN.normal;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            
            half4 frag(Varyings IN) : SV_Target
            {
                
                //half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                //half4 color = half4(IN.positionHCS.xyz, 0);
                //half4 color = half4(IN.normal.xyz, 0);
                
                float2 bladePos = float2(.2,.55);
                float2 bladePos2 = float2(.7,.55);
                float2 c = 0;

                float2 p = IN.uv.xy;
                p -= bladePos;

                p = mul(rotate2d(-.3), p);
                
                //p *= float2(-10,-.5);
                //float c = (noise(IN.pos.xz * float2(12,1) + _Time.yy* -float2(1,1.2)) - .7) * (noise((IN.pos.xy * float2(12 ,5)) + _Time.yy * -float2(-.1,5.2)) - .6) - IN.pos.y;
                //c = p;
                
                c +=  smoothstep(0.01,-.02,sdGrassBlade2d(p));

                p = IN.uv.xy;
                p-= bladePos2;
                p = mul(rotate2d(-.3), p);


                c +=  smoothstep(0.01,-.02,sdGrassBlade2d(p));

                for(int i=0;i<10;i++)
                {
                    float2 bldPos = random2(bladePos + float2(i,i));
                    p = IN.uv.xy;
                    p-= bldPos;
                    p = mul(rotate2d(-.3), p);

                    c +=  smoothstep(0.01,-.02,sdGrassBlade2d(p));

                }

                float base = 1-sdCircle((IN.uv.xy * float2(1,1.5)) + float2(-.5,.7), .3);

                base = smoothstep(.2,.3,base);
                c += base;

                float alpha = step(.2, c);

                if (alpha < 1)
                {
                    discard;
                }
                //c +=  sdGrassBlade2d(p + float2(.5,.5));
                //c = IN.uv.xy;

                c = smoothstep(.2, 1, c);

                half4 color = half4(c.x,c.y,0,1);
                return color;
            }
            ENDHLSL
        }

        
    }
}
