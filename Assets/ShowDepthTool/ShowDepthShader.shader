//https://www.jianshu.com/p/1aefa8145c4c

Shader "Unlit/ShowDepthShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {   
        //URP下实体渲染完毕才会写入深度图，所以想访问它就要在Transparent里面访问
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);  //到裁切空间
                o.screenPos = ComputeScreenPos(o.vertex);   //屏幕空间的齐次坐标
                return o;
            }
            

            half4 frag(v2f v) : SV_Target
            {
                float2 screenPos = v.screenPos.xy / v.screenPos.w;  //计算屏幕空间的UV(去齐次)
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r; //采样深度
                float depthValue = Linear01Depth(depth, _ZBufferParams);    //转换深度到0-1区间灰度值
                return float4(depthValue, depthValue, depthValue, 1.0); //返回显示灰度颜色
            }
        ENDHLSL
        }
    }
}