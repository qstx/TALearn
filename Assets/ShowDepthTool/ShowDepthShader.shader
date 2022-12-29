//https://www.jianshu.com/p/1aefa8145c4c

Shader "Unlit/ShowDepthShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {   
        //URP��ʵ����Ⱦ��ϲŻ�д�����ͼ���������������Ҫ��Transparent�������
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
                o.vertex = TransformObjectToHClip(v.vertex);  //�����пռ�
                o.screenPos = ComputeScreenPos(o.vertex);   //��Ļ�ռ���������
                return o;
            }
            

            half4 frag(v2f v) : SV_Target
            {
                float2 screenPos = v.screenPos.xy / v.screenPos.w;  //������Ļ�ռ��UV(ȥ���)
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r; //�������
                float depthValue = Linear01Depth(depth, _ZBufferParams);    //ת����ȵ�0-1����Ҷ�ֵ
                return float4(depthValue, depthValue, depthValue, 1.0); //������ʾ�Ҷ���ɫ
            }
        ENDHLSL
        }
    }
}