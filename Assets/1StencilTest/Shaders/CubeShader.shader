Shader "StencilTest/CubeShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,0)
        [IntRange]_StencilMask("Stencil Mask", Range(0,255)) = 0
        //_ZWrite("ZWrite")
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry"}
        LOD 100
        
        HLSLINCLUDE
        #include "Packages\com.unity.render-pipelines.universal\ShaderLibrary\Core.hlsl"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float4 normal : NORMAL;
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
        
        v2f vert2 (appdata v)
        {
            v2f o;
            o.vertex = TransformObjectToHClip(v.vertex+v.normal*0.05f);
            return o;
        }

        half4 frag2 (v2f i) : SV_Target
        {
            return half4(1,1,1,1);
        }
        ENDHLSL
        
        Pass
        {
            Stencil
            {
                Ref [_StencilMask]
                Comp Always
                Pass Replace
                ZFail Keep
            }
            Tags {
                "LightMode"="UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
        //Pass
        //{
        //    Tags {
        //        "LightMode"="SRPDefaultUnlit"
        //    }
        //    ZTest Off
        //    ZWrite Off
        //    HLSLPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag
        //    ENDHLSL
        //}
    }
}
