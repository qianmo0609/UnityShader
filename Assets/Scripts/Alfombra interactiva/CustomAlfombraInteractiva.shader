Shader "Custom/CustomAlfombraInteractiva"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Position("Position", Vector) = (0, 0, 0, 0)
        _radius("radius", Float) = 0
        _edge("edge", Float) = 0
        _blur("blur", Float) = 0
        _intensity("intensity", Float) = 0
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
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Position;
            float _radius;
            float _blur;
            float _edge;
            float _intensity;

            v2f vert (appdata v)
            {
                v2f o;
                float4 ver = mul(unity_ObjectToWorld, v.vertex);
                float range = distance(_Position,ver) - _radius;
                float4 color = smoothstep(_edge,_blur,range);
                float lerpVale = lerp(v.normal.y * color * _intensity,ver.y,color);
                o.vertex = UnityObjectToClipPos(float4(v.vertex.x,lerpVale,v.vertex.z,v.vertex.w));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
