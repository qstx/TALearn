Shader "Plpeline/PBR"
{
    Properties
    {
         _BaseMap("Albedo", 2D) = "white" {}
         _BumpMap("Normal Map", 2D) = "bump" {}
         _BaseColor("Color", Color) = (1,1,1,1)
         _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
         _GlossScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
         _MetallicGlossMap("Metallic", 2D) = "white" {}
         _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
         _OcclusionMap("Occlusion", 2D) = "white" {}
         [HDR] _EmissionColor("Color", Color) = (0,0,0)
         _EmissionMap("Emission", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel" = "4.5"}


        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        //���hlsl��Ҫ�Լ�ʵ��
        #include "BRDFCommon.hlsl"

        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);

        float4 _BaseMap_TexelSize;

        TEXTURE2D(_BumpMap);
        SAMPLER(sampler_BumpMap);

        TEXTURE2D(_EmissionMap);
        SAMPLER(sampler_EmissionMap);

        TEXTURE2D(_MetallicGlossMap);
        SAMPLER(sampler_MetallicGlossMap);

        TEXTURE2D(_OcclusionMap);
        SAMPLER(sampler_OcclusionMap);

        float _Metallic;
        float _GlossScale;
        float4 _BaseColor;
        float4 _EmissionColor;
        float _OcclusionStrength;
        struct Attributes
        {
            float4 positionOS   : POSITION;
            float3 normalOS     : NORMAL;
            float4 tangentOS    : TANGENT;
            float2 texcoord     : TEXCOORD0;
        };

        struct Varyings
        {
            float2 uv                      : TEXCOORD0;
            float3 normalWS                 : TEXCOORD1;
            float4 tangentWS                : TEXCOORD2;
            float3 positionWS              : TEXCOORD3;
            float4 positionCS               : SV_POSITION;
        };

        Varyings PBRVertex(Attributes input)
        {
            Varyings output = (Varyings)0;
            float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            float sgn = input.tangentOS.w* GetOddNegativeScale();
            float4 tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz).xyz, sgn);
            output.normalWS = normalWS;
            output.tangentWS = tangentWS;
            output.positionWS = TransformObjectToWorld(input.positionOS);
            output.positionCS = TransformWorldToHClip(output.positionWS);
            output.uv = input.texcoord;
            return output;
        }

        float4 PBRFragment(Varyings input) : SV_Target
        {
            float3 positionWS = input.positionWS;
            float2 uv = input.uv;
            float3 viewDirWS = SafeNormalize(GetCameraPositionWS() - positionWS);
            float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
            float4 metallicGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
            float occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).r * _OcclusionStrength;
            float3 emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv).xyz;
            float4 bumpMapColor = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);
            float3 normalTS = UnpackNormalScale(bumpMapColor,1.0);
            float3 lightDirection = normalize(_MainLightPosition.xyz);
            float3 lightColor = _MainLightColor.rgb;

            float metalness = metallicGloss.x * _Metallic;
            float3 albedo = baseColor.rgb * _BaseColor.rgb;
            float gloss =  metallicGloss.a * _GlossScale;
            float sgn = input.tangentWS.w;
            input.normalWS.xyz = normalize(input.normalWS.xyz);
            input.tangentWS.xyz = normalize(input.tangentWS.xyz);
            float3 bitangent = normalize(sgn * cross(input.normalWS.xyz, input.tangentWS.xyz));
            float3x3 tangentToWorld = float3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
            float3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
            normalWS = NormalizeNormalPerPixel(normalWS);
            float3 h = normalize(viewDirWS + lightDirection);
            float nl = max(dot(normalWS, lightDirection), 0.0);
            float hv = max(dot(h, viewDirWS), 0.0);
            float nv = max(dot(normalWS, viewDirWS), 0.0);
            float nh = max(dot(normalWS, h), 0.0);
            float roughness = (1.0 - gloss);
            float3 reflectDir = reflect(-viewDirWS, normalWS);
            //������ķǽ�����F0Ϊ0.04��ʱ�������Ӿ�������ȷ��,�������ǽ���ʱalbedo��ʾ����F0����������,
            //��������ʹ�ý����������в�ֵ
            float3 f0 = lerp(0.04, albedo.rgb, metalness);
            //ֱ�ӹ��ղ���
            float3 directLighting = DirectPBR(nl, nv, nh, hv, albedo, metalness, roughness, f0,lightColor);
            //�������ղ���
            //float3 ambientLighting = AmbientPBR(normalWS, albedo, reflectDir, nv, f0, roughness, occlusion, metalness);
            float3 result = directLighting + _EmissionColor * emission;// + ambientLighting;
            return float4(result.xyz ,1);
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            Stencil
            {
                Ref 0
                Comp Always
                Pass Replace
            }
            ZWrite On
            Cull Back
            HLSLPROGRAM
            #pragma vertex PBRVertex
            #pragma fragment PBRFragment
            ENDHLSL
        }
    }
}