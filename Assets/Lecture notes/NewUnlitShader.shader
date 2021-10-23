Shader "Unlit/NewUnlitShader"
{
    
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Value("Value", Float) = 1.0
        _Color("Color", Color) = (1, 1, 1, 1)
        _ColorA("Color A", Color) = (1, 1, 1, 1)
        _ColorB("Color B", Color) = (1, 1, 1, 1)
        _GradientStart("Gradient Start Position", Range(0, 1)) = 0
        _GradientEnd("Gradient End Position", Range(0, 1)) = 1
        _XScale("X Scale", Float) = 1.0
        _YScale("Y Scale", Float) = 1.0
        _WaveAmplitude("Wave Amplitude", Range(0, 0.2)) = 0
    }
    
        
    SubShader
    {
        // Subshader Tags
        Tags { 
            "RenderType" = "Transparent" // tag to inform the render pipeline of what type it is
            "Queue" = "Transparent" // changes the render order

            // rendering pipeline unity: Skybox > Opaque (geometry) > Transparent > Overlays (lens flare, etc.)
        }

        Pass
        {
            // Pass Tags (Shader lab)

            //Blend One One // additive blending 
            //Blend DstColor Zero // multiplicative blending

            // Writing to the Depth buff or not (occlude objects behind)
            // be careful of fill rate (smoke screen that has a lot of quads)
            //ZWrite Off

            // Show object, testing depending on the Depth buffer (ZTest LEqual, GEqual, Always)
            //ZTest LEqual

            // Cull removes something (cull off / cull back / call front)
            Cull Back

            // HLSL Code: CGPROGRAM -> ENDCG = code
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _Value;
            float4 _Color;  
            float4 _ColorA;
            float4 _ColorB;
            float _GradientStart;
            float _GradientEnd;
            float _XScale;
            float _YScale;
            float _WaveAmplitude;

            // Unity built-in variables
            #include "UnityCG.cginc"
            #define TAU 6.28

            // Per-vertex mesh data, automatically filled out by unity
            struct MeshData 
            { 
                // Type name : SEMANTIC
                float4 vertex : POSITION;
                //float4 tangents: TANGENT;
                float3 normals: NORMAL;
                float2 uv : TEXCOORD0; // Texcoord is uv related
                // float2 uv1 : TEXCOORD1; (lightmap)

                //float4 color: COLOR
            };

            struct Interpolator
            { //v2f or FragInput, interpolates between 2 vertices  
                float4 vertex : SV_POSITION; // clip space position
                float3 normal: TEXCOORD0; // Texcoord is an index used to separate values
                float2 uv : TEXCOORD1;
                float4 color : TEXCOORD2;
                // float... someValues : TEXCOORD...
            };


            float InverseLerp(float a, float b, float v) {
                return (v - a) / (b - a);
            }



            // Is there more vertices than pixels?
            // usually yes, if so, transformations in the vertex shader than fragment shaders
            Interpolator vert (MeshData v)
            {
                Interpolator o;

                float2 uvCentered = v.uv * 2 - 1;
                float2 radialDistance = length(uvCentered);
                float wave = cos((radialDistance - _Time.y * 0.1) * TAU * 5);

                v.vertex.y = wave * _WaveAmplitude * exp(- 2 *radialDistance);

                o.vertex = UnityObjectToClipPos(v.vertex); // local space to clip space
                // if v.vertex, the shader renders direclty on the camera and is not moved along with the object
                //o.normal = _Color.rgb;
                //o.normal = v.normals; // World space normals, not local space
                o.normal = UnityObjectToWorldNormal(v.normals); // mul ((float3x3)unity_ObjectToWorld, v.normals);
                o.uv = v.uv;

                //_Time.xyzw built in Unity, y is the time in seconds, 

                float t = InverseLerp(_GradientStart, _GradientEnd, (v.uv.x + v.uv.y) / 2);
                // frac = v - floor(v) // check if values are clamped between 0 and 1
                //o.color = lerp(_ColorA, _ColorB, saturate(t)); // saturate clamps between 0 and 1
                o.color = lerp(_ColorA, _ColorB, t); // saturate clamps between 0 and 1


                //float xOffset = i.uv.y; // offset changing depending on vertical position > drill

                return o;
            }

            // float (32 bit float)
            // half (16 bit float)
            // fixed (12 bit float - lower precision) -1 to 1
            // less precision is faster, less memory

            // vector: float2, half3, fixed4, int3, bool4 for example
            // matrices: float4x4, half4x4

            float4 frag(Interpolator i) : SV_Target
            { // output to the frame buffer

                //float4 myValue;
                //float2 otherValue = myValue.xy; // casting float 4 to float2 (swizzling)
                //float4 otherValue = myValue.xxxx; // grayscale (swizzling)
                //float2 otherValue = myValue.rg; // only red and green (swizzling)

                //float2 otherValue = myValue.gr; // flip red and green channel(swizzling)
                float2 uvCentered = i.uv * 2 - 1;
                float2 radialDistance = length(uvCentered);
                float wave = cos((radialDistance - _Time.y * 0.1) * TAU * 5) * 0.5+ 0.5;                
                return float4( wave * exp(-2.5 * radialDistance.x) + 0.1, wave  * exp(-2*radialDistance.x) + 0.1, wave * exp(-0.001*radialDistance.x) + 0.5, 1);
                //return _Color;
                //return float4(i.uv.xxx, 1);
            }
            ENDCG
        }
    }
}
