Shader "Unlit/HleathBarShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Health("Health", Range(0, 1)) = 1
        _ColorStart("Color Start", Color) = (0, 1, 0, 1)
        _ColorEnd("Color End", Color) = (1, 0, 0, 1)
        _BGColor("background Color", Color) = (0, 0, 0, 1)
        _MinThreshold("Min Threshold", Float) = 0.2
        _MaxThreshold("Max Threshold", Float) = 0.8
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha;

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _Health;
            float4 _ColorStart;
            float4 _ColorEnd;
            float4 _BGColor;
            float _MinThreshold;
            float _MaxThreshold;
            sampler2D _MainTex;

            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
            };

            float InverseLerp (float a, float b, float v){
                return (v - a) / (b - a);
            }

            Interpolator vert (MeshData v)
            {
                Interpolator o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                
                return o;
            }

            float4 frag(Interpolator i) : SV_Target
            {
                // Mask to split the health color and the background color (missing health)
                float healthBarMask = _Health > i.uv.x;  // Classic health Bar
                float healthBarMask2 = _Health > floor(i.uv.x * 8) / 8; // Health Bar that decreases / increases by Chunks

                // Assignment 1d 
                // Reads a vertical slice of the texture at the x-coordinate health
                float4 col = tex2D(_MainTex, float2(_Health, i.uv.y));

                // Assignment 1e
                // Pulsate the health bar when at low health

                if (_Health <= _MinThreshold) {
                    healthBarMask *= 0.25*cos(_Time.y * 5) + 0.5;
                }
                return col * healthBarMask; 



                // Assignment 1a 1b 1c

                // Remaps the whole health bar between the two thresholds (e.g. 0.2 becomes 0 and 0.8 becomes 1 by default)
                float tHealthColor = saturate(InverseLerp(_MinThreshold, _MaxThreshold, _Health)); 

                // The color is interpolated between the start color (green by default) and the end color (red by default)
                i.color = lerp(_ColorStart, _ColorEnd, (1 - _Health));

                // Apply the mask on the health bar
                float4 healthBarColor = lerp(_BGColor, i.color, healthBarMask); // !! lerp is unclamped, to clamp, use saturate

                // Removes the background color and makes it transparent. Can also use Blend SrcAlpha OneMinuesSrcAlplha and modify the tags to transparent
                clip(healthBarMask-0.01);

                return healthBarColor; 
            }
            ENDCG
        }
    }
}
