Shader "Custom/test"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

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

            float circle(in float2 pos)
            {
                
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
                
                //float c = (noise(IN.pos.xz * float2(12,1) + _Time.yy* -float2(1,1.2)) - .7) * (noise((IN.pos.xy * float2(12 ,5)) + _Time.yy * -float2(-.1,5.2)) - .6) - IN.pos.y;
                float c = noise(IN.uv.xy);
                //c = IN.uv.xy;
                half4 color = half4(c,c,c,1);
                return color;
            }
            ENDHLSL
        }
    }
}
