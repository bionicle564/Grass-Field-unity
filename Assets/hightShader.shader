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

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float2 meh = TRANSFORM_TEX(IN.uv, _HightMap);
                OUT.pos = float4(meh.xy,0,1);


                float newHight = SAMPLE_TEXTURE2D_LOD(_HightMap, sampler_HightMap, meh, 0).r;
                newHight *= _HightStr;
                OUT.pos.y = newHight;
                IN.positionOS.y = newHight;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D_LOD(_HightMap, sampler_HightMap, IN.uv, 0) * _BaseColor;
                //half4 color = IN.pos;
                return color;
            }
            ENDHLSL
        }
    }
}
