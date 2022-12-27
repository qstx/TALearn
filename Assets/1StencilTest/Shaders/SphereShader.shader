Shader "StencilTest/SphereShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,0)
        [IntRange]_StencilRef("Stencil Ref", Range(0,255)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="Universal RenderPipeline" "Queue"="Geometry+1"}
        LOD 100

        HLSLINCLUDE
        #include "Packages\com.unity.render-pipelines.universal\ShaderLibrary\Core.hlsl"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        half4 _Color;

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = TransformObjectToHClip(v.vertex);
            return o;
        }

        half4 frag (v2f i) : SV_Target
        {
            return half4(_Color.rgb,1);
        }
        half4 frag2 (v2f i) : SV_Target
        {
            return half4(1,1,1,1);
        }
        ENDHLSL
        Pass
        {
            Tags {
                "LightMode"="UniversalForward"
            }
            ZTest Greater
            Stencil
            {
                Ref [_StencilRef]
                Comp Equal
                Pass Keep
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
        Pass
        {
            Tags {
                "LightMode"="SRPDefaultUnlit"
            }
            ZTest LEqual
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag2
            ENDHLSL
        }
    }
}
