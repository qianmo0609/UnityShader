Shader "BlackAndWhite"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Transprent" "Queue"="Geometry" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D_X(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            float3 SampleSceneColor(float2 uv)
            {
                return SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, UnityStereoTransformScreenSpaceTex(uv)).rgb;
            }

            float4 ComputeScreenPos (float4 pos, float projectionSign)
            {
               float4 o = pos * 0.5f;
               o.xy = float2(o.x, o.y * projectionSign) + o.w;
               o.zw = pos.zw;
               return o;
            }

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 ScreenPosition : TEXCOORD0;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(UNITY_MATRIX_MVP,v.vertex);
                o.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(mul(unity_ObjectToWorld, v.vertex)),_ProjectionParams.x);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 _ScreenPosition_Out_0 = float4(i.ScreenPosition.xy / i.ScreenPosition.w, 0, 0);
                float3 col = SampleSceneColor(_ScreenPosition_Out_0.xy);// tex2D(_CameraOpaqueTexture, _ScreenPosition_Out_0.xy);
                float c = (col.x + col.y + col.z) / 3;
                return float4(c,c,c,1);
            }
            ENDHLSL
        }
    }
}
