Shader "Custom"
{
        Properties {
         _MainTex ("MainTex", 2D) = "white" {}
         _SubTex ("SubTex",2D) = "white"{}
         _Color ("Color", Color) = (1,1,1,1)
         _Offset("Offset",Vector) = (1,1,1,1)
     }
 
     SubShader {
 
         Tags 
         {
             "Queue"="Transparent"
             "IgnoreProjector"="True"
             "RenderType"="Transparent"
             "PreviewType"="Plane"
         }

         Blend SrcAlpha OneMinusSrcAlpha

         Pass 
         {
             CGPROGRAM
             #pragma vertex vert
             #pragma fragment frag
 
             #include "UnityCG.cginc"
 
             struct appdata_t {
                 float4 vertex : POSITION;
                 fixed4 color : COLOR;
                 float2 texcoord : TEXCOORD0;
                 float2 texcoord1 : TEXCOORD1;
             };
 
             struct v2f {
                 float4 vertex : SV_POSITION;
                 fixed4 color : COLOR;
                 float2 texcoord : TEXCOORD0;
                 float2 texcoord1 : TEXCOORD1;
             };
 
             sampler2D _MainTex;
             uniform float4 _MainTex_ST;
             sampler2D _SubTex;
             uniform float4 _SubTex_ST;
             uniform fixed4 _Color;
             float4 _Offset;
             
             v2f vert (appdata_t v)
             {
                 v2f o;
                 o.vertex = UnityObjectToClipPos(v.vertex);
                 o.color = v.color * _Color;
                 o.texcoord = TRANSFORM_TEX(_Offset.z * v.texcoord, _MainTex);
                 o.texcoord1 = TRANSFORM_TEX(v.texcoord1, _SubTex) ;
                 return o;
             }
 
             fixed4 frag (v2f i) : SV_Target
             {
                 fixed4 t1 = tex2D(_MainTex, i.texcoord + float2(_Offset.x,_Offset.y));
                 fixed4 t2 = tex2D(_SubTex, i.texcoord1);
                 fixed4 col = t2 * (1-t1.a) * i.color;
                 col *= (1-t1.a);
                 return col;
             }
             ENDCG 
         }
     }
}
