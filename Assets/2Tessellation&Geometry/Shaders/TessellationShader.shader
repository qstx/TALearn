//����ϸ��Demo1
Shader "TALearn/TessellationAndGeometry/Tessellation"
{
    Properties
    {
        _TessellationUniform("TessellationUniform",Range(1,64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            HLSLPROGRAM
            #include "Packages\com.unity.render-pipelines.universal\ShaderLibrary\Core.hlsl"
            //����2������ hull domain
            #pragma hull hullProgram
            #pragma domain ds
           
            #pragma vertex tessvert
            #pragma fragment frag

            //#include "UnityCG.cginc"
            //��������ϸ�ֵ�ͷ�ļ�
            //#include "Tessellation.cginc" 

            #pragma target 5.0
            
            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct VertexOutput
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            VertexOutput vert (VertexInput v)
            //�������Ӧ����domain�����У������ռ�ת���ĺ���
            {
                VertexOutput o;
                o.vertex = TransformWorldToHClip(v.vertex);
                o.uv = v.uv;
                o.tangent = v.tangent;
                o.normal = v.normal;
                return o;
            }

            //��ЩӲ����֧������ϸ����ɫ���������˸ú���ܹ��ڲ�֧�ֵ�Ӳ���ϲ����ۣ�Ҳ���ᱨ��
            //#ifdef UNITY_CAN_COMPILE_TESSELLATION
                //������ɫ���ṹ�Ķ���
                struct TessVertex{
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv : TEXCOORD0;
                };

                struct OutputPatchConstant { 
                    //��ͬ��ͼԪ���ýṹ��������ͬ
                    //�ò�������Hull Shader����
                    //������patch������
                    //Tessellation Factor��Inner Tessellation Factor
                    float edge[3] : SV_TESSFACTOR;
                    float inside  : SV_INSIDETESSFACTOR;
                };

                TessVertex tessvert (VertexInput v){
                    //������ɫ������
                    TessVertex o;
                    o.vertex  = v.vertex;
                    o.normal  = v.normal;
                    o.tangent = v.tangent;
                    o.uv      = v.uv;
                    return o;
                }

                float _TessellationUniform;
                OutputPatchConstant hsconst (InputPatch<TessVertex,3> patch){
                    //��������ϸ�ֵĲ���
                    OutputPatchConstant o;
                    o.edge[0] = _TessellationUniform;
                    o.edge[1] = _TessellationUniform;
                    o.edge[2] = _TessellationUniform;
                    o.inside  = _TessellationUniform;
                    return o;
                }

                [domain("tri")]//ȷ��ͼԪ��quad,triangle��
                [partitioning("fractional_odd")]//���edge�Ĺ���equal_spacing,fractional_odd,fractional_even
                [outputtopology("triangle_cw")]
                [patchconstantfunc("hsconst")]//һ��patchһ���������㣬�����������㶼�����������
                [outputcontrolpoints(3)]      //��ͬ��ͼԪ���Ӧ��ͬ�Ŀ��Ƶ�
              
                TessVertex hullProgram (InputPatch<TessVertex,3> patch,uint id : SV_OutputControlPointID){
                    //����hullshaderV����
                    return patch[id];
                }

                [domain("tri")]//ͬ����Ҫ����ͼԪ
                VertexOutput ds (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3>patch,float3 bary :SV_DOMAINLOCATION)
                //bary:��������
                {
                    VertexInput v;
                    v.vertex = patch[0].vertex*bary.x + patch[1].vertex*bary.y + patch[2].vertex*bary.z;
			        v.tangent = patch[0].tangent*bary.x + patch[1].tangent*bary.y + patch[2].tangent*bary.z;
			        v.normal = patch[0].normal*bary.x + patch[1].normal*bary.y + patch[2].normal*bary.z;
			        v.uv = patch[0].uv*bary.x + patch[1].uv*bary.y + patch[2].uv*bary.z;

                    VertexOutput o = vert (v);
                    return o;
                }
            //#endif

            float4 frag (VertexOutput i) : SV_Target
            {

                return float4(1.0,1.0,1.0,1.0);
            }
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}