Shader "UnlitShadows/UnlitShadowReciever"
{
    Properties
    {
        [Header(Color)] [Space]
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BaseTexture("Base Texture", 2D) = "white" {}
        [Header(Shadows)] [Space]
        _ShadowOpacity("Shadow Opacity", Range(0, 1)) = 0.5
        [Header(Alpha)] [Space]
        _AlphaClip("Alpha Clip", Range(0, 1)) = 0.5
        _AlphaMask("Alpha Mask", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        ZWrite On
        ZTest LEqual

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;            
            float4 _BaseTexture_ST;
            float _ShadowOpacity;
            float _AlphaClip;
            float4 _AlphaMask_ST;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            TEXTURE2D(_AlphaMask);
            SAMPLER(sampler_AlphaMask);

            struct appdata {
                float4 positionOS : POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f{
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 positionWS: TEXCOORD1;
                float2 uvAlpha: TEXCOORD2;
            };

            v2f vert(appdata i)
            {
                v2f o = (v2f)0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
                o.uvAlpha = TRANSFORM_TEX(i.uv, _AlphaMask);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            float4 frag(v2f i) : SV_TARGET
            { 
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);

                Light mainLight = GetMainLight(shadowCoord);

                
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv) * _BaseColor;

                float shadowMask = 1 - mainLight.shadowAttenuation;
                float4 shadowColor = float4(baseColor.xyz * (1 - _ShadowOpacity), 1);

                float4 finalColor = lerp(baseColor, shadowColor, shadowMask);

                float alphaMask = SAMPLE_TEXTURE2D(_AlphaMask, sampler_AlphaMask, i.uvAlpha).r * baseColor.a;

                if(alphaMask < _AlphaClip)
                   discard;

                return finalColor;
            }

            ENDHLSL
        }

        Pass {
            Tags {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask R

            HLSLPROGRAM

                #pragma vertex depthOnlyVert
                #pragma fragment depthOnlyFrag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;            
                float4 _BaseTexture_ST;
                float _ShadowOpacity;
                float _AlphaClip;
                float4 _AlphaMask_ST;
                float3 _LightDirection;
                float3 _LightPosition;
                CBUFFER_END
                
                TEXTURE2D(_BaseTexture);
                SAMPLER(sampler_BaseTexture);

                TEXTURE2D(_AlphaMask);
                SAMPLER(sampler_AlphaMask);

                struct appdata{
                    float4 positionOS : POSITION;
                    float2 uv: TEXCOORD0;
                };

                struct v2f{
                    float4 positionCS : SV_POSITION;
                    float2 uv: TEXCOORD0;
                    float2 uvAlpha: TEXCOORD1;
                };

                v2f depthOnlyVert(appdata i)
                {
                    v2f o = (v2f)0;
                    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                    o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
                    o.uvAlpha = TRANSFORM_TEX(i.uv, _AlphaMask);
                    return o;
                }

                float depthOnlyFrag(v2f i): SV_TARGET
                {
                    float alphaMask = SAMPLE_TEXTURE2D(_AlphaMask, sampler_AlphaMask, i.uvAlpha).r * SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv).a;

                    if(alphaMask < _AlphaClip)
                        discard;

                    return i.positionCS.z;
                }

            ENDHLSL
        }

        Pass {
            Tags {
                "LightMode" = "DepthNormals"
            }

            ZWrite On

            HLSLPROGRAM
                #pragma vertex depthNormalsVert
                #pragma fragment depthNormalsFrag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;            
                float4 _BaseTexture_ST;
                float _ShadowOpacity;
                float _AlphaClip;
                float4 _AlphaMask_ST;
                float3 _LightDirection;
                float3 _LightPosition;
                CBUFFER_END
                
                TEXTURE2D(_BaseTexture);
                SAMPLER(sampler_BaseTexture);

                TEXTURE2D(_AlphaMask);
                SAMPLER(sampler_AlphaMask);

                struct appdata{
                    float4 positionOS : POSITION;
                    float2 uv: TEXCOORD0;
                    float3 normalOS : NORMAL;
                };

                struct v2f{
                    float4 positionCS : SV_POSITION;
                    float3 normalWS : TEXCOORD0;
                    float2 uv: TEXCOORD1;
                    float2 uvAlpha: TEXCOORD2;
                };

                v2f depthNormalsVert(appdata i)
                {
                    v2f o = (v2f)0;
                    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                    o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                    o.normalWS = NormalizeNormalPerVertex(o.normalWS);
                    o.uv = TRANSFORM_TEX(i.uv, _BaseTexture);
                    o.uvAlpha = TRANSFORM_TEX(i.uv, _AlphaMask);
                    return o;
                }

                float4 depthNormalsFrag(v2f i): SV_TARGET
                {
                    float alphaMask = SAMPLE_TEXTURE2D(_AlphaMask, sampler_AlphaMask, i.uvAlpha).r * SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv).a;

                    if(alphaMask < _AlphaClip)
                        discard;

                    float3 normalWS = NormalizeNormalPerPixel(i.normalWS);
                    return float4(normalWS, 0.0f);
                }

            ENDHLSL
        }
    }    
}
