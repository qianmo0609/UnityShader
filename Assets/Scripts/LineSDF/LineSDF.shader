Shader "Custom/LineSDF"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed2 uv:TEXCOORD0;
            };
           
           float line_segment(float2 p, float2 a, float2 b) {
	            float2 ba = b - a;
	            float2 pa = p - a;
	            float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
	            return length(pa - h * ba);
           } 

           float sdCircle( float2 p, float r )
           {
                return length(p) - r;
           }
         
           float3 mix(float3 e1, float3 e2, float e3){
                return e1 * (1-e3) + e2 * e3; 
           }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 pos = (i.uv - 1 * .5) / 1;
	            float zoom = 2.5;
	            pos *= zoom;

	            float2 v1 = cos(_Time.x + float2(0.,5.));
	            float2 v2 = cos(_Time.x + float2(0.,5.) + 3.1);
	            float thickness = .2 * (.5 + .5 * sin(_Time.x * 1.));

	            //float d = line_segment(pos, v1, v2) - thickness;
                float d = sdCircle(pos,v1);

	            float3 color = float3(1,1,1) - sign(d) * float3(0,0,0);
	            color *= 1.5 - exp(.5 * abs(d));
	            color *= .5 + .3 * cos(120. * d);
	            color = mix(color, float3(1,1,1), 1. - smoothstep(.0, .015, abs(d)));

                return float4(color, 1.);
            }
            ENDCG
        }
    }
}
