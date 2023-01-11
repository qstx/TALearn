Shader "TALearn/TessellationAndGeometry/GeometryShader"
{
    Properties
    {
        [Header(Main)]
        _Color("Color",Color)=(1,1,1,1)
        [Space]
        [Header(Line)]
        _LineColorLerp("Line Color Lerp",Color)=(0,1,0,1)
        _LineColor("Line Color",Color)=(0,0,1,1)
        _LineLength("Line Length",Range(0.01,2))=0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            struct appdata
            {
                float3 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct geomdata{
                float3 vertex : INTERNALGEOPOS;
                float3 normal:NORMAL;
            };
            struct v2f
            {
                float3 normal:TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            struct v2fgeom
            {
                float3 normal:TEXCOORD0;
                float4 vertex : SV_POSITION;
                float d:TEXCOORD1;
            };

            half4 _Color;
            half4 _LineColor;
            half4 _LineColorLerp;
            float _LineLength;

            geomdata vertgeom (appdata v)
            {
                geomdata o;
                o.vertex = TransformObjectToWorld(v.vertex);
                o.normal=TransformObjectToWorldNormal(v.normal);
                return o;
            }

            [maxvertexcount(6)]
            void geom(triangle geomdata data[3],inout LineStream<v2fgeom>stream){
                for(int i=0;i<3;++i){
                    v2fgeom v1,v2;
                    v1.vertex=TransformWorldToHClip(data[i].vertex);
                    v2.vertex=TransformWorldToHClip(data[i].vertex+_LineLength*normalize(data[i].normal));
                    v1.normal=data[i].normal;
                    v2.normal=data[i].normal;
                    v1.d=0;
                    v2.d=1;
                    stream.Append(v1);
                    stream.Append(v2);
                    stream.RestartStrip();
                }
            }
            v2f vert(appdata v){
                v2f o;
                o.vertex=TransformObjectToHClip(v.vertex);
                o.normal=TransformObjectToWorldNormal(v.normal);
                return o;
            }
            half4 fraggeom (v2fgeom i) : SV_Target
            {
                half3 col=lerp(_LineColorLerp.rgb,_LineColor.rgb,i.d);
                return half4(col,1.0);
            }
            half4 frag (v2f i):SV_Target{
                Light light=GetMainLight();
                float d=max(0,dot(light.direction,i.normal));
                float3 SHColor=SampleSH(i.normal);
                half3 col=_Color*light.color*d+_Color*SHColor;
                return half4(col,1.0);
            }
        ENDHLSL
        Pass
        {
            
            Name "Geometry"
            Tags{"LightMode"="SRPDefaultUnlit"}
            HLSLPROGRAM
            #pragma vertex vertgeom
            #pragma geometry geom
            #pragma fragment fraggeom
            #pragma target 4.0
            ENDHLSL
        }
        Pass
        {
            Cull Off
            Name "SimpleLit"
            Tags{"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0
            ENDHLSL
        }
        

        
    }
}

