
Shader "Particles/Additive HDR" 
{
    Properties
    {
        [HDR]_TintColor("Tint Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex("Particle Texture", 2D) = "white" {}
        _InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
    }

    Category
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }

        Blend SrcAlpha One
        ColorMask RGB
        Cull Off Lighting Off ZWrite Off

        SubShader
        {
            Pass
            {
                CGPROGRAM

                #include "UnityCG.cginc"

                #pragma vertex ComputeVertex
                #pragma fragment ComputreFragment
                #pragma target 2.0
                #pragma multi_compile_particles
                #pragma multi_compile_fog

                sampler2D _MainTex;
                float4 _MainTex_ST;
                float4 _TintColor;
                float _InvFade;
                UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

                struct VertexInput
                {
                    float4 Vertex : POSITION;
                    fixed4 Color : COLOR;
                    float2 TexCoord : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct VertexOutput
                {
                    float4 Vertex : SV_POSITION;
                    fixed4 Color : COLOR;
                    float2 TexCoord : TEXCOORD0;
                    UNITY_FOG_COORDS(1)
                    #ifdef SOFTPARTICLES_ON
                    float4 ProjPos : TEXCOORD2;
                    #endif
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                VertexOutput ComputeVertex(VertexInput vertexInput)
                {
                    VertexOutput vertexOutput;
                    UNITY_SETUP_INSTANCE_ID(vertexInput);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(vertexOutput);
                    vertexOutput.Vertex = UnityObjectToClipPos(vertexInput.Vertex);
                    #ifdef SOFTPARTICLES_ON
                    vertexOutput.ProjPos = ComputeScreenPos(vertexOutput.Vertex);
                    COMPUTE_EYEDEPTH(vertexOutput.ProjPos.z);
                    #endif
                    vertexOutput.Color = vertexInput.Color;
                    vertexOutput.TexCoord = TRANSFORM_TEX(vertexInput.TexCoord, _MainTex);
                    UNITY_TRANSFER_FOG(vertexOutput, vertexOutput.Vertex);
                    return vertexOutput;
                }

                fixed4 ComputreFragment(VertexOutput vertexOutput) : SV_Target
                {
                    #ifdef SOFTPARTICLES_ON
                    float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(vertexOutput.ProjPos)));
                    float partZ = vertexOutput.ProjPos.z;
                    float fade = saturate(_InvFade * (sceneZ - partZ));
                    vertexOutput.Color.a *= fade;
                    #endif

                    fixed4 color = tex2D(_MainTex, vertexOutput.TexCoord) * vertexOutput.Color * _TintColor;
                    UNITY_APPLY_FOG_COLOR(vertexOutput.fogCoord, color, fixed4(0, 0, 0, 0));
                    return color;
                }

                ENDCG
            }
        }
    }
}
