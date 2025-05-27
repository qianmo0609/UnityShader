Shader "CustomURPLitShaderBase"
{
    Properties
    {

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
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
        Blend One Zero
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
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS : NORMAL;
            float3 positionWS : TEXCOORD0;
            float3 viewDirectionWS : TEXCOORD1;
        };

        void InitializeInputData(Varyings input,out InputData inputData)
        {
            inputData = (InputData)0;
            inputData.positionWS = input.positionWS;
            inputData.normalWS = NormalizeNormalPerPixel(input.normalWS);
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
            return output;
        }

        half4 frag(Varyings unpacked) : SV_TARGET
        {
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
            surface.smoothness          = 0.5;
            surface.occlusion           = 1;
            surface.emission            = float3(0, 0, 0);
            surface.alpha               = 1;
            surface.normalTS            = half3(0, 0, 0);
            surface.clearCoatMask       = 0;
            surface.clearCoatSmoothness = 1;
            return UniversalFragmentPBR(inputData, surface);
        }        
        ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}