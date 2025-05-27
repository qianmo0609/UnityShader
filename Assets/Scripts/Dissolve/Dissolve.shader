Shader "Dissolve"
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
            "RenderType"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 posWS: TEXCOORD1;
            };

            float _NoisoScale;
            float _NoiseStrenth;
            float _CutoffHeight;
            float _EdgeWidth;
            float4 _EdgeColor;
            float4 _BaseColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float outNoise;
                SimpleNoise_float(i.uv,_NoisoScale,outNoise);
                float newStrenth;
                Negate_float(_NoiseStrenth,newStrenth);
                float finalNoise;
                Remap_float(outNoise,float2(0,1),float2(newStrenth,_NoiseStrenth),finalNoise);
                finalNoise = finalNoise + _CutoffHeight;
                float3 color = step(finalNoise,i.posWS.y + _EdgeWidth) * _EdgeColor; 
                float alpha = step(i.posWS.y,finalNoise);
                return fixed4(_BaseColor + color.xyz,alpha) ;
            }
            ENDCG
        }
    }
}
