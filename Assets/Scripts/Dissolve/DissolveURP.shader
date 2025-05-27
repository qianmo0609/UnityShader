Shader "DissolveURP"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _NoisoScale("NoisoScale", Float) = 40
        _NoiseStrenth("NoiseStrenth", Float) = 3.07
        _CutoffHeight("CutoffHeight", Range(-10,10)) = 0.12
        _EdgeWidth("EdgeWidth", Range(0,0.5)) = -0.03
        [HDR]_EdgeColor("EdgeColor", Color) = (1, 0.8352941, 0, 0)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        
        HLSLPROGRAM
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        #define _NORMALMAP 1
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float2 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD0;
            float3 normalWS : NORMAL;
            float3 viewDirectionWS : TEXCOORD1;
            float2 uv : TEXCOORD2;
        };
        
        // Graph Pixel
        // struct SurfaceDescription
        // {
        //     float3 BaseColor;
        //     float3 NormalTS;
        //     float3 Emission;
        //     float Metallic;
        //     float Smoothness;
        //     float Occlusion;
        // };

        float Unity_SimpleNoise_RandomValue_float (float2 uv)
        {
            float angle = dot(uv, float2(12.9898, 78.233));
            return frac(sin(angle)*43758.5453);
        }

        float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
        {
            return (1.0-t)*a + (t*b);
        }

        void Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        void Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }
        float SimpleNoise_ValueNoise_float (float2 uv)
        {
            float2 i = floor(uv);
            float2 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            uv = abs(frac(uv) - 0.5);
            float2 c0 = i + float2(0.0, 0.0);
            float2 c1 = i + float2(1.0, 0.0);
            float2 c2 = i + float2(0.0, 1.0);
            float2 c3 = i + float2(1.0, 1.0);
            float r0 = Unity_SimpleNoise_RandomValue_float(c0);
            float r1 = Unity_SimpleNoise_RandomValue_float(c1);
            float r2 = Unity_SimpleNoise_RandomValue_float(c2);
            float r3 = Unity_SimpleNoise_RandomValue_float(c3);

            float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
            float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
            float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
            return t;
        }

        void SimpleNoise_float(float2 UV, float Scale, out float Out)
        {
            float t = 0.0;

            float freq = pow(2.0, float(0));
            float amp = pow(0.5, float(3-0));
            t += SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, float(1));
            amp = pow(0.5, float(3-1));
            t += SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            freq = pow(2.0, float(2));
            amp = pow(0.5, float(3-2));
            t += SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

            Out = t;
        }

        float _NoisoScale;
        float _NoiseStrenth;
        float _CutoffHeight;
        float _EdgeWidth;
        float4 _EdgeColor;
        float4 _BaseColor;

        void InitializeInputData(Varyings input,out InputData inputData)
        {
            inputData = (InputData)0;
            inputData.positionWS = input.positionWS;
            inputData.normalWS = input.normalWS;
            inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
            inputData.viewDirectionWS = SafeNormalize(input.viewDirectionWS);
            inputData.shadowCoord = float4(0, 0, 0, 0);
            inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, float3(0,0,0), inputData.normalWS);
            inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
            inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
        }

        Varyings vert(Attributes input)
        {
            Varyings output = (Varyings)0;
            //世界空间下的坐标
            float3 positionWS = TransformObjectToWorld(input.positionOS);
            //世界空间下的法线坐标
            output.normalWS = TransformObjectToWorldNormal(input.normalOS);
            output.positionCS = TransformWorldToHClip(positionWS);
            output.viewDirectionWS = GetWorldSpaceViewDir(positionWS);
            output.uv = input.uv0;
            return output;
        }

        half4 frag(Varyings unpacked) : SV_TARGET
        {
            float outNoise;
            SimpleNoise_float(unpacked.uv,_NoisoScale,outNoise);
            float newStrenth;
            Negate_float(_NoiseStrenth,newStrenth);
            float finalNoise;
            Remap_float(outNoise,float2(0,1),float2(newStrenth,_NoiseStrenth),finalNoise);
            finalNoise = finalNoise + _CutoffHeight;
            float3 _color = step(finalNoise,unpacked.positionWS.y + _EdgeWidth) * _EdgeColor; 
            float alpha = step(unpacked.positionWS.y,finalNoise);

            InputData inputData;
            InitializeInputData(unpacked,inputData);

            SurfaceData surface;
            #ifdef UNITY_COLORSPACE_GAMMA
                surface.albedo = float3(0.5, 0.5, 0.5);
            #else
                surface.albedo = SRGBToLinear(float3(0.5, 0.5, 0.5));
            #endif
            surface.metallic            = 0;
            surface.specular            = 0;
            surface.smoothness          = saturate(0.5);
            surface.occlusion           = 1;
            surface.emission            = float3(0, 0, 0);
            surface.alpha               = 1;
            surface.normalTS            = half3(0, 0, 0);
            surface.clearCoatMask       = 0;
            surface.clearCoatSmoothness = 1;

            half4 color = UniversalFragmentPBR(inputData, surface);
            color.rgb = MixFog(color.rgb, inputData.fogCoord);
            return color;
        }        
        ENDHLSL
        }
    }
}