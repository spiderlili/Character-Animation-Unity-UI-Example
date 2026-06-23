Shader "Custom/GreenScreenChromaKey"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _MaskColor("Base Color", Color) = (0, 1, 0, 1)
        _MaskRange("Mask Hue Range", Float) = 0.21
        _MaskFuzziness("Mask Fuzziness", Float) = 0.43
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
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

            float4 ColorMask(float3 In, float3 MaskColor, float Range, float Fuzziness)
            {
                float Distance = distance(MaskColor, In);
                return saturate(1 - (Distance - Range) / max(Fuzziness, 1e-5));
            }
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                half4 _MaskColor;
                half _MaskRange, _MaskFuzziness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                const half4 chromaKeyColor = ColorMask(color.rgb, _MaskColor, _MaskRange, _MaskFuzziness);
                const half chromaKeyAlpha = 1 - chromaKeyColor;
                color.a = chromaKeyAlpha;
                return color;
            }
            ENDHLSL
        }
    }
}
