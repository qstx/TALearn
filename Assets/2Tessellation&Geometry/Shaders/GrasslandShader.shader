Shader "TALearn/TessellationAndGeometry/GrassGroundShader"
{
    Properties
    {
        _TopColor("TopColor", Color) = (1,0,0)
        _BottomColor("BottomColor", Color) = (0,0,1)
        //弯曲程度
        _BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
        //宽度
        _BladeWidth("Blade Width",Float)=0.05
        _BladeWidthRandom("Blade Width Random",Float)=0.02
        _BladeHeight("Blade Height",Range(0.5,1.5))=0.5
        _BladeHeightRandom("Blade Height Random",Float)=0.3

        _TessellationUniform("Tessellation Uniform",Range(10,20))=10
        //风
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        _WindStrength("Wind Strength",Range(0.1,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Cull Off

        HLSLINCLUDE
        #include "Packages\com.unity.render-pipelines.universal\ShaderLibrary\Core.hlsl"
        struct TessVertex
        {
            float4 vertex : INTERNALTESSPOS;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
        };

        struct OutputPatchConstant
        {
            //不同的图元，该结构会有所不同
            //该部分用于Hull Shader里面
            //定义了patch的属性
            //Tessellation Factor和Inner Tessellation Factor
            float edge[3] : SV_TESSFACTOR;
            float inside : SV_INSIDETESSFACTOR;
        };
        //顶点着色器输入
        struct vertexInput
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            //float2 uv : TEXCOORD0;
        };
        struct vertexOutput
        {
            float4 vertex : SV_POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
        };
        //几何着色器输出
        struct geometryOutput
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD;
        };
        vertexOutput vertFunc(vertexInput v)
        //这个函数应用在domain函数中，用来空间转换的函数
        {
            vertexOutput o;
            //o.vertex = TransformObjectToHClip(v.vertex);
            o.vertex=v.vertex;
            o.tangent = v.tangent;
            o.normal = v.normal;
            return o;
        }
        //Func to produce grassable data
        geometryOutput VertexOutput(float3 pos, float2 uv)
        {
            geometryOutput o;
            o.pos=TransformObjectToHClip(pos);
            o.uv=uv;
            return o;
        }
        float rand(float3 co)
        {
            return frac(sin(dot(co.xyz,float3(12.9898f,78.233f,53.539f)))*43758.5453);
        }
        float3x3 AngleAxis3x3(float angle,float3 axis)
        {
            float c,s;
            sincos(angle,s,c);
            float t=1-c;
            float x=axis.x;
            float y=axis.y;
            float z=axis.z;

            return float3x3(
                t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                t * x * z - s * y, t * y * z + s * x, t * z * z + c
            );
        }
        ENDHLSL
        Pass
        {
            HLSLPROGRAM
            #pragma hull hullProgram
            #pragma domain ds
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag
            
            half4 _TopColor;
            half4 _BottomColor;
            float _BendRotationRandom;
            float _BladeWidth;
            float _BladeWidthRandom;
            float _BladeHeight;
            float _BladeHeightRandom;
            
            float _TessellationUniform;

            sampler2D _WindDistortionMap;
            float4 _WindDistortionMap_ST;
            float2 _WindFrequency;
            float _WindStrength;

            vertexOutput vert (vertexInput v)
            {
                vertexOutput o;
                //o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.vertex=v.vertex;
                o.normal=v.normal;
                o.tangent=v.tangent;
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            OutputPatchConstant hsconst(InputPatch <vertexOutput,3> patch)
            {
                //定义曲面细分的参数
                OutputPatchConstant o;
                o.edge[0] = _TessellationUniform;
                o.edge[1] = _TessellationUniform;
                o.edge[2] = _TessellationUniform;
                o.inside = _TessellationUniform;
                return o;
            }
            [domain("tri")]//确定图元，quad,triangle等
            [partitioning("fractional_odd")]//拆分edge的规则，equal_spacing,fractional_odd,fractional_even
            [outputtopology("triangle_cw")]
            [patchconstantfunc("hsconst")]//一个patch一共有三个点，但是这三个点都共用这个函数
            [outputcontrolpoints(3)]      //不同的图元会对应不同的控制点
            TessVertex hullProgram(InputPatch < vertexOutput, 3 > patch, uint id : SV_OutputControlPointID)
            {
                //定义hullshaderV函数
                return patch[id];
            }
            [domain("tri")]//同样需要定义图元
            vertexOutput ds(OutputPatchConstant tessFactors, const OutputPatch < TessVertex, 3 > patch, float3 bary : SV_DOMAINLOCATION)
            //bary:重心坐标
            {
                vertexInput v;
                v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
                v.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
                v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;

                vertexOutput o = vertFunc(v);
                return o;
            }

            [maxvertexcount(3)]
            void geo(triangle vertexOutput IN[3],inout TriangleStream<geometryOutput> triStream)
            {
                float3 pos = IN[0].vertex;

                float3 vNormal=IN[0].normal;
                float4 vTangent=IN[0].tangent;
                float3 vBinormal = cross(vNormal,vTangent)*vTangent.w;

                float3x3 tangentToLocal=float3x3(
                    vTangent.x,vBinormal.x,vNormal.x,
                    vTangent.y,vBinormal.y,vNormal.y,
                    vTangent.z,vBinormal.z,vNormal.z
                );

                float height = (rand(pos.zyx)*2-1)*_BladeHeightRandom+_BladeHeight;
                float width = (rand(pos.xzy)*2-1)*_BladeWidthRandom+_BladeWidth;

                float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos)*TWO_PI,float3(0,0,1));
                float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx)*_BendRotationRandom*0.5*PI,float3(-1,0,0));
                //风
                float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
                float2 windSample = (tex2Dlod(_WindDistortionMap,float4(uv,0,0)).xy * 2 - 1) * _WindStrength;
                float3 wind = normalize(float3(windSample.x,windSample.y,0));//Wind Vector
                float3x3 windRotation = AngleAxis3x3(PI * windSample, wind);
                float3x3 transformationMatrix=mul(mul(mul(tangentToLocal,facingRotationMatrix),bendRotationMatrix),windRotation);
                float3x3 transformationMatrixFacing = mul(tangentToLocal,facingRotationMatrix);
                triStream.Append(VertexOutput(pos + mul(transformationMatrixFacing,float3(width,0.0f,0.0f)),float2(0,0)));
                triStream.Append(VertexOutput(pos + mul(transformationMatrixFacing,float3(-width,0.0f,0.0f)),float2(1,0)));
                triStream.Append(VertexOutput(pos + mul(transformationMatrix,float3(0.0f,0.0f,height)),float2(0.5f,1)));
            }

            half4 frag (geometryOutput i,half facing : VFACE) : SV_Target
            {
                // sample the texture
                //half4 col = tex2D(_MainTex, i.uv);
                //return col;
                //return half4(0.1h,0.9h,0.05h,1.0h);
                return lerp(_BottomColor,_TopColor,i.uv.y);
            }
            ENDHLSL
        }
    }
}
