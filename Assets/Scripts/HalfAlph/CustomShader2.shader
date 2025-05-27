Shader "CustomTex"
{
        Properties {
         _MainTex ("MainTex", 2D) = "white" {}
         _SubTex ("SubTex",2D) = "white"{}
         _Offset("Offset",Range(-10,10)) = 1
     }
 
     SubShader {

         Pass 
         {
             CGPROGRAM
             #pragma vertex vert
             #pragma fragment frag
 
             #include "UnityCG.cginc"
 
             struct appdata_t {
                 float4 vertex : POSITION;
                 float2 texcoord : TEXCOORD0;
                 float2 texcoord1 : TEXCOORD1;
             };
 
             struct v2f {
                 float4 vertex : SV_POSITION;
                 float2 texcoord : TEXCOORD0;
                 float2 texcoord1 : TEXCOORD1;
                 float val : TEXCOORD2;
             };
 
             sampler2D _MainTex;
             uniform float4 _MainTex_ST;
             sampler2D _SubTex;
             uniform float4 _SubTex_ST;
             float _Offset;
             
             v2f vert (appdata_t v)
             {
                 v2f o;
                 o.vertex = UnityObjectToClipPos(v.vertex);
                 o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                 o.texcoord1 = TRANSFORM_TEX(v.texcoord1, _SubTex);
                 o.val = v.vertex.x;
                 return o;
             }
 
             fixed4 frag (v2f i) : SV_Target
             {
                 fixed4 t1 = tex2D(_MainTex, i.texcoord);
                 fixed4 t2 = tex2D(_SubTex, i.texcoord1);
                 fixed4 col = t1 * max(0,sign(_Offset - i.val)) + t2 * max(0,sign(i.val - _Offset));
                 return col;
             }
             ENDCG 
         }
     }
}
