//D项
float DistributionGGX(float3 NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;

    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}
//G项
float GeometrySchlickGGX(float cosTheta, float k)
{
    float nom = cosTheta;
    float denom = cosTheta * (1.0 - k) + k;
    return nom / (denom + 1e-5f);
}
//G项考虑视线方向和光照方向
float GeometrySmith(float NdotV,float NdotL ,float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    float ggx2 = GeometrySchlickGGX(NdotV, k);
    float ggx1 = GeometrySchlickGGX(NdotL, k);
    return ggx1 * ggx2;
}
//F项
float3 FresnelTerm(float3 F0, float cosA)
{
    half t = pow(1 - cosA,5.0); 
    return F0 + (1 - F0) * t;
}


//直接光照计算
float3 DirectPBR(float nl,float nv,float nh,float hv,float3 albedo,float metalness,float roughness,float3 f0,float3 lightColor)
{
    float dTerm = DistributionGGX(nh, roughness);
    float gTerm = GeometrySmith(nl, nv, roughness);
    float3 fTerm = FresnelTerm(f0, hv);
    //max 0.001 保证分母不为0
    float3 specular = dTerm * gTerm * fTerm / (4.0 * max(nv * nl, 0.001));
    //我们按照能量守恒的关系，首先计算镜面反射部分，它的值等于入射光线被反射的能量所占的百分比。
    float3 kS = fTerm;
    //然后折射光部分就可以直接由镜面反射部分计算得出：
    float3 kD = (1.0 - kS) ;
    //金属是没有漫反射的,所以Kd需要乘上1-metalness
    kD *= 1.0 - metalness;
    //除π是为了能量守恒，但Unity也没有除以π，应该是觉得除以π后太暗，所以我们这里也先不除
    float3 diffuse = kD * albedo;// *INV_PI;
    float3 result = (diffuse + specular) * nl * lightColor;
    return (result);
}

//  //void PrefilterDiffuseCubemap(Cubemap envCubemap,out Cubemap outputCubemap) 
//  //  {
//  //      int size = 128;
//  //      outputCubemap = new Cubemap(size, TextureFormat.RGBAFloat, false);
//  //      ComputeBuffer reslutBuffer = new ComputeBuffer(size * size, sizeof(float) * 4);
//  //      Color[] tempColors = new Color[size * size];
//  //      for (int face = 0; face < 6; ++face)
//  //      {
//  //          genIrradianceMapShader.SetInt("_Face", face);
//  //          genIrradianceMapShader.SetTexture(0, "_Cubemap", envCubemap);
//  //          genIrradianceMapShader.SetInt("_Resolution", size);
//  //          genIrradianceMapShader.SetBuffer(0, "_Reslut", reslutBuffer);
//  //          genIrradianceMapShader.Dispatch(0, size / 8, size / 8, 1);
//  //          reslutBuffer.GetData(tempColors);
//  //          outputCubemap.SetPixels(tempColors, (CubemapFace)face);
//  //      }
//  //      reslutBuffer.Release();
//  //      outputCubemap.Apply();
//  //  }

//    //void PrefilterDiffuseCubemap(Cubemap envCubemap,out Cubemap outputCubemap) 
//    //{
//    //    int size = 128;
//    //    outputCubemap = new Cubemap(size, TextureFormat.RGBAFloat, false);
//    //    ComputeBuffer reslutBuffer = new ComputeBuffer(size * size, sizeof(float) * 4);
//    //    Color[] tempColors = new Color[size * size];
//    //    for (int face = 0; face < 6; ++face)
//    //    {
//    //        genIrradianceMapShader.SetInt("_Face", face);
//    //        genIrradianceMapShader.SetTexture(0, "_Cubemap", envCubemap);
//    //        genIrradianceMapShader.SetInt("_Resolution", size);
//    //        genIrradianceMapShader.SetBuffer(0, "_Reslut", reslutBuffer);
//    //        genIrradianceMapShader.Dispatch(0, size / 8, size / 8, 1);
//    //        reslutBuffer.GetData(tempColors);
//    //        outputCubemap.SetPixels(tempColors, (CubemapFace)face);
//    //    }
//    //    reslutBuffer.Release();
//    //    outputCubemap.Apply();
//    //}
//    #pragma kernel CSMainDiffuse
//#define PI 3.1415926

//TextureCube<float4> _Cubemap;
//SamplerState _PointClamp;
//RWStructuredBuffer<float4> _Reslut;
//int _Face;
//int _Resolution;
////根据面和uv计算方向
// float3 DirectionFromCubemapTexel(int face, float2 uv)
//{
//    float3 dir = 0;

//    switch (face)
//    {
//    case 0: //+X
//        dir.x = 1.0;
//        dir.yz = uv.yx * -2.0 + 1.0;
//        break;

//    case 1: //-X
//        dir.x = -1.0;
//        dir.y = uv.y * -2.0f + 1.0f;
//        dir.z = uv.x * 2.0f - 1.0f;
//        break;

//    case 2: //+Y
//        dir.xz = uv * 2.0f - 1.0f;
//        dir.y = 1.0f;
//        break;
//    case 3: //-Y
//        dir.x = uv.x * 2.0f - 1.0f;
//        dir.z = uv.y * -2.0f + 1.0f;
//        dir.y = -1.0f;
//        break;

//    case 4: //+Z
//        dir.x = uv.x * 2.0f - 1.0f;
//        dir.y = uv.y * -2.0f + 1.0f;
//        dir.z = 1;
//        break;

//    case 5: //-Z
//        dir.xy = uv * -2.0f + 1.0f;
//        dir.z = -1;
//        break;
//    }
//    return normalize(dir);
//}

//[numthreads(8,8,1)]
//void CSMainDiffuse(uint3 id : SV_DispatchThreadID)
//{
//    //+0.5/Resolution是像素中心点
//    float2 uv = (float2)id.xy / (float2)(_Resolution) + 0.5 / (float2)_Resolution;
//    uint index = id.y * _Resolution + id.x;
//    float3 dir = DirectionFromCubemapTexel(_Face, uv);

//    float3 tangent = float3(0, 1, 0);
//    float upOrDown = dot(dir, tangent);
//    if (upOrDown == 1)
//        tangent = float3(1, 0, 0);
//    else if (upOrDown == -1)
//        tangent = float3(-1, 0, 0);
//    else
//        tangent = normalize(cross(float3(0, 1, 0), dir));
//    float3 binormal = normalize(cross(dir, tangent));
//    float sampleDelta = 0.025;
//    int N1 = 0;
//    int N2 = 0;
//    float3 irradiance = float3(0, 0, 0);

//    for (float phi = 0.0; phi < 2.0 * PI; phi += sampleDelta)
//    {
//        N2 = 0;

//        for (float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)
//        {
//            //球面坐标
//            float3 tangentSpaceNormal = float3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
//            float3 worldNormal = tangentSpaceNormal.x * tangent + tangentSpaceNormal.y * binormal + tangentSpaceNormal.z * dir;
//            irradiance += _Cubemap.SampleLevel(_PointClamp, worldNormal, 0).rgb * cos(theta) * sin(theta);
//            N2++;
//        }
//        N1++;
//    }
//    //对应黎曼和积分
//    float weight = PI * PI / (N1 * N2);
//    irradiance *= weight;
//    _Reslut[index] = float4(irradiance.xyz,1.0);
//}
// //Vector3[] BakeSH(Cubemap map)
// //   {
// //       Vector3[] coefficients = new Vector3[9];
// //       float[] sh9 = new float[9];
// //       for (int face = 0; face < 6; ++face)
// //       {
// //            var colos = map.GetPixels((CubemapFace)face);
// //           for (int texel = 0; texel < map.width * map.width; ++texel)
// //           {
// //               float u = (texel % map.width) / (float)map.width;
// //               float v = ((int)(texel / map.width)) / (float)map.width;
// //               Vector3 dir = DirectionFromCubemapTexel(face, u, v);
// //               Color radiance = colos[texel];
// //               float d_omega = DifferentialSolidAngle(map.width, u, v);
// //               HarmonicsBasis(dir, sh9);
// //               for (int c = 0; c < 9; ++c)
// //               {
// //                   float sh = sh9[c];
// //                   coefficients[c].x += radiance.r * d_omega * sh ;
// //                   coefficients[c].y += radiance.g * d_omega * sh ;
// //                   coefficients[c].z += radiance.b * d_omega * sh ;

// //               }
// //           }
// //       }
// //       return coefficients;
// //   }

////public static Vector3 DirectionFromCubemapTexel(int face, float u, float v)
////    {
////        Vector3 dir = Vector3.zero;

////        switch (face)
////        {
////            case 0: //+X
////                dir.x = 1;
////                dir.y = v * -2.0f + 1.0f;
////                dir.z = u * -2.0f + 1.0f;
////                break;

////            case 1: //-X
////                dir.x = -1;
////                dir.y = v * -2.0f + 1.0f;
////                dir.z = u * 2.0f - 1.0f;
////                break;

////            case 2: //+Y
////                dir.x = u * 2.0f - 1.0f;
////                dir.y = 1.0f;
////                dir.z = v * 2.0f - 1.0f;
////                break;

////            case 3: //-Y
////                dir.x = u * 2.0f - 1.0f;
////                dir.y = -1.0f;
////                dir.z = v * -2.0f + 1.0f;
////                break;

////            case 4: //+Z
////                dir.x = u * 2.0f - 1.0f;
////                dir.y = v * -2.0f + 1.0f;
////                dir.z = 1;
////                break;

////            case 5: //-Z
////                dir.x = u * -2.0f + 1.0f;
////                dir.y = v * -2.0f + 1.0f;
////                dir.z = -1;
////                break;
////        }

////        return dir.normalized;
////    }

////  public static float DifferentialSolidAngle(int textureSize, float U, float V)
////    {
////        float inv = 1.0f / textureSize;
////        float u = 2.0f * (U + 0.5f * inv) - 1;
////        float v = 2.0f * (V + 0.5f * inv) - 1;
////        float x0 = u - inv;
////        float y0 = v - inv;
////        float x1 = u + inv;
////        float y1 = v + inv;
////        return AreaElement(x0, y0) - AreaElement(x0, y1) - AreaElement(x1, y0) + AreaElement(x1, y1);
////    }

////   public static float AreaElement(float x, float y)
////    {
////        return Mathf.Atan2(x * y, Mathf.Sqrt(x * x + y * y + 1));
////    }

////    const float sh0_0 = 0.28209479f;
////    const float sh1_1 = 0.48860251f;
////    const float sh2_n2 = 1.09254843f;
////    const float sh2_n1 = 1.09254843f;
////    const float sh2_0 = 0.31539157f;
////    const float sh2_1 = 1.09254843f;
////    const float sh2_2 = 0.54627421f;

////    void HarmonicsBasis(Vector3 pos, float[] sh9)
////    {
////        Vector3 normal = pos;
////        float x = normal.x;
////        float y = normal.y;
////        float z = normal.z;
////        sh9[0] = sh0_0;
////        sh9[1] = sh1_1 * y;
////        sh9[2] = sh1_1 * z;
////        sh9[3] = sh1_1 * x;
////        sh9[4] = sh2_n2 * x * y;
////        sh9[5] = sh2_n1 * z * y;
////        sh9[6] = sh2_0 * (2 * z * z - x * x - y * y);// (-x * x - z * z + 2 * y * y);
////        sh9[7] = sh2_1 * z * x;
////        sh9[8] = sh2_2 * (x * x - y * y);
////    }
//    float3 _SH_PARAM0;
//float3 _SH_PARAM1;
//float3 _SH_PARAM2;
//float3 _SH_PARAM3;
//float3 _SH_PARAM4;
//float3 _SH_PARAM5;
//float3 _SH_PARAM6;
//float3 _SH_PARAM7;
//float3 _SH_PARAM8;

//float3 GetSH9(float3 normal)
//{
//    float3 res = _SH_PARAM0 * 0.28209479f;

//    float3 temp = normal.y * _SH_PARAM1  * 0.48860251;
//    res += temp;
//    temp = normal.z * _SH_PARAM2 *  0.48860251;
//    res += temp;
//    temp = normal.x * _SH_PARAM3 *  0.48860251;
//    res += temp;

//    temp = normal.x * normal.y * _SH_PARAM4 *  1.09254843;
//    res += temp;
//    temp = normal.y * normal.z * _SH_PARAM5 *  1.09254843;
//    res += temp;
//    temp = (-normal.x * normal.x - normal.y * normal.y + 2 * normal.z * normal.z) * _SH_PARAM6 *  0.31539157;
//    res += temp;
//    temp = normal.z * normal.x * _SH_PARAM7 *  1.09254843f;
//    res += temp;
//    temp = (normal.x * normal.x - normal.y * normal.y) * _SH_PARAM8 *  0.54627421;
//    res += temp;
//    return res / 3.1415926;
//}
////void PrefilterSpecularCubemap(Cubemap cubemap, out Cubemap outputCubemap)
////    {
////        int bakeSize = 128;
////        outputCubemap = new Cubemap(bakeSize, TextureFormat.RGBAFloat, true);
////        int maxMip = outputCubemap.mipmapCount;
////        int sampleCubemapSize = cubemap.width;
////        outputCubemap.filterMode = FilterMode.Trilinear;
////        for (int mip = 0; mip < maxMip; mip++)
////        {
////            int size = bakeSize;
////            size = size >> mip;
////            int size2 = size * size;
////            Color[] tempColors = new Color[size2];
////            float roughness = (float)mip / (float)(maxMip - 1);
////            ComputeBuffer reslutBuffer = new ComputeBuffer(size2, sizeof(float) * 4);
////            for (int face = 0; face < 6; ++face)
////            {
////                genIrradianceMapShader.SetInt("_Face", face);
////                genIrradianceMapShader.SetTexture(1, "_Cubemap", cubemap);
////                genIrradianceMapShader.SetFloat("_SampleCubemapSize", sampleCubemapSize);
////                genIrradianceMapShader.SetInt("_Resolution", size);
////                Debug.Log("roughness" + roughness);
////                genIrradianceMapShader.SetFloat("_FilterMipRoughness", roughness);
////                genIrradianceMapShader.SetBuffer(1, "_Reslut", reslutBuffer);
////                genIrradianceMapShader.Dispatch(1, size, size, 1);
////                reslutBuffer.GetData(tempColors);
////                outputCubemap.SetPixels(tempColors, (CubemapFace)face, mip);
////            }
////            reslutBuffer.Release();
////        }
////        outputCubemap.Apply(false);
////    }
//    float RadicalInverse_VdC(uint bits)
//{
//    bits = (bits << 16u) | (bits >> 16u);
//    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
//    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
//    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
//    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
//    return float(bits) * 2.3283064365386963e-10; // / 0x100000000
//}
////生成[0,1]均匀分布的随机数
//float2 Hammersley(uint i, uint N)
//{
//    return float2(float(i) / float(N), RadicalInverse_VdC(i));
//}
////重要性采样获得采样方向
//float3 ImportanceSampleGGX(float2 Xi, float3 N, float roughness)
//{
//    float a = roughness * roughness;
//    //根据GGX的cdf的反函数求得
//    float phi = 2.0 * PI * Xi.x;
//    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a * a - 1.0) * Xi.y));
//    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

//    //转球面坐标
//    float3 H;
//    H.x = cos(phi) * sinTheta;
//    H.y = sin(phi) * sinTheta;
//    H.z = cosTheta;

//    //切空间转换到世界空间
//    float3 up = abs(N.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
//    float3 tangent = normalize(cross(up, N));
//    float3 bitangent = cross(N, tangent);

//    float3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
//    return normalize(sampleVec);
//}

////float DistributionGGX(float3 NdotH, float roughness)
////{
////    float a = roughness * roughness;
////    float a2 = a * a;
////    float NdotH2 = NdotH * NdotH;
////    float nom = a2;
////    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
////    denom = PI * denom * denom;
////    return nom / denom;
////}

//[numthreads(1, 1, 1)]
//void CSMainGGX(uint3 id : SV_DispatchThreadID)
//{
//    float2 uv = (float2)id.xy / (float2)(_Resolution) + 0.5 / (float2)_Resolution;
//    uint index = id.y * _Resolution + id.x;
//    float3 dir = DirectionFromCubemapTexel(_Face, uv);

//    float3 irradiance = float3(0, 0, 0);
//    float3 N = dir;
//    float3 R = N;
//    float3 V = R;
//    const uint SAMPLE_COUNT = 1024;
//    float totalWeight = 0.0;
//    float3 prefilteredColor =  0.0;

//    for (uint i = 0; i < SAMPLE_COUNT; ++i)
//    {
//        float2 Xi = Hammersley(i, SAMPLE_COUNT);
//        float3 H = ImportanceSampleGGX(Xi, N, _FilterMipRoughness);
//        float3 L = normalize(2.0 * dot(V, H) * H - V);

//        float NdotL = max(dot(N, L), 0.0);
//        if (NdotL > 0.0)
//        {
//            float NdotH = saturate(dot(N, H));
//            float HdotV = saturate(dot(H, V));
//            float D = DistributionGGX(NdotH, _FilterMipRoughness);
//            float pdf = (D * NdotH / (4.0 * HdotV)) + 0.0001;
//            float resolution = _SampleCubemapSize; // resolution of source cubemap (per face)
//            float saTexel = 4.0 * PI / (6.0 * resolution * resolution);
//            float saSample = 1.0 / (float(SAMPLE_COUNT) * pdf + 0.0001);
//           // float mipLevel = _FilterMipRoughness == 0.0 ? 0.0 : 0.5 * log2(saSample / saTexel) ;
//            //使用mip来采用是为了防止太多高亮噪点
//            float mipLevel = _FilterMipRoughness == 0.0 ? 0.0 : 1.0 * log2(saSample / saTexel);
//            prefilteredColor += _Cubemap.SampleLevel(_PointClamp, L, 0).rgb * NdotL;
//            totalWeight += NdotL;
//        }
//    }

//    prefilteredColor = prefilteredColor / totalWeight;
//    _Reslut[index] = float4(prefilteredColor.xyz, 1.0);
//}
//void BakeBRDFLut(out Texture2D tex) 
//    {
//        int resolution = 512;
//        int resolution2 = resolution * resolution;
//        tex = new Texture2D(resolution, resolution, TextureFormat.RGBA32,false,true);
//        tex.wrapMode = TextureWrapMode.Clamp;
//        tex.filterMode = FilterMode.Point;
//        Color[] tempColors = new Color[resolution2];
//        ComputeBuffer reslutBuffer = new ComputeBuffer(resolution2, sizeof(float) * 4);
//        genIrradianceMapShader.SetBuffer(2, "_Reslut", reslutBuffer);
//        genIrradianceMapShader.SetInt("_Resolution", resolution);
//        genIrradianceMapShader.Dispatch(2, resolution/8, resolution/8, 1);
//        reslutBuffer.GetData(tempColors);
//        tex.SetPixels(tempColors,  0);
//        tex.Apply();
//    }
//    float GeometrySchlickGGX(float NdotV, float roughness)
//{
//    float a = roughness;
//    //这里IBL和直接光照不一样
//    float k = (a * a) / 2.0;

//    float nom = NdotV;
//    float denom = NdotV * (1.0 - k) + k;

//    return nom / denom;
//}
//// ----------------------------------------------------------------------------
//float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
//{
//    float NdotV = max(dot(N, V), 0.0);
//    float NdotL = max(dot(N, L), 0.0);
//    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
//    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

//    return ggx1 * ggx2;
//}

//[numthreads(8, 8, 1)]
//void CSMainBRDF(uint3 id : SV_DispatchThreadID)
//{
//    float2 uv = (float2)id.xy / (float2)(_Resolution) + 0.5/ (float2)_Resolution;
//    uint index = id.y * _Resolution + id.x;
   
//    float NdotV = uv.x;
//    float roughness = uv.y;
//    float3 V = float3(sqrt(1.0 - NdotV * NdotV),0, NdotV);

//    float scale = 0.0;
//    float bias = 0.0;

//    float3 N = float3(0.0, 0.0, 1.0);

//    const uint SAMPLE_COUNT = 2048;
//    for (uint i = 0; i < SAMPLE_COUNT; ++i)
//    {
//        float2 Xi = Hammersley(i, SAMPLE_COUNT);
//        float3 H = ImportanceSampleGGX(Xi, N, roughness);
//        float3 L = normalize(2.0 * dot(V, H) * H - V);

//        float NdotL = max(L.z, 0.0);
//        float NdotH = max(H.z, 0.0);
//        float VdotH = max(dot(V, H), 0.0);

//        if (NdotL > 0.0)
//        {
//            float G = GeometrySmith(N, V, L, roughness);
//            float G_Vis = (G * VdotH) / (NdotH * NdotV);
//            float Fc = pow(1.0 - VdotH, 5.0);

//            scale += (1.0 - Fc) * G_Vis;
//            bias += Fc * G_Vis;
//        }
//    }
//    scale /= float(SAMPLE_COUNT);
//    bias /= float(SAMPLE_COUNT);

//    _Reslut[index] = float4(scale, bias,0.0, 1.0);
//}

//float3 fresnelSchlickRoughness(float NdotV, float3 F0, float roughness)
//{
//    return F0 + (max(1.0f - roughness, F0) - F0) * pow(1.0 - NdotV, 5.0);
//}

//float3 AmbientPBR(float3 normalWS, float3 albedo,float3 r, float nv,float3 f0, float roughness,float ao, float metalness)
//{
//    float3 kS =  fresnelSchlickRoughness(nv, f0, roughness);
//    float3 kD = (1.0 - kS) * (1.0 - metalness);
//    float3 diffuse = kD * GetSH9(normalWS.xyz) * albedo;
//    float2 envBRDF = SAMPLE_TEXTURE2D_LOD(_IBLBrdf, sampler_IBLBrdf,float2(nv, roughness),0.0).rg;
//    float3 prefilteredColor = SAMPLE_TEXTURECUBE_LOD(_IBLPrefilteredMap, sampler_IBLPrefilteredMap,r,  roughness * _IBLMaxMipCount);
//    float3 specular = prefilteredColor * (kS * envBRDF.x + envBRDF.y);
//    float3 result = (diffuse + specular) * ao;
//    return result;
//}