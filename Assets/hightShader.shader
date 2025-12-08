Shader "Custom/hightShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _HightMap("Hight map", 2D) = "black"
        _HightStr("Hight Stregnth", Float) = 1
    }

    SubShader
    {
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
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float4 pos : COLOR;
                float2 uv : TEXCOORD0;
            };

            

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            TEXTURE2D(_HightMap);
            SAMPLER(sampler_HightMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _HightStr;
                float4 _HightMap_ST;
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

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float2 meh = TRANSFORM_TEX(IN.uv, _HightMap);
                OUT.pos = float4(meh.xy,0,1);


                float newHight = SAMPLE_TEXTURE2D_LOD(_HightMap, sampler_HightMap, meh, 0).r;
                newHight *= _HightStr;
                IN.positionOS.y = newHight;
                OUT.pos.xyz = IN.positionOS.xyz;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D_LOD(_HightMap, sampler_HightMap, IN.uv, 0) * _BaseColor;

                float cloudShadow = noise((IN.pos.xz * -300 * .01) + _Time.w * .055);

                color *= cloudShadow;
                //half4 color = IN.pos;
                return color;
            }
            ENDHLSL
        }
    }
}
