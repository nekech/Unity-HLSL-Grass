Shader "Unlit/GrassTutorial"
{
    Properties
    {
        _BottomColor ("BottomColor", Color) = (0, 0, 0, 1)
        _TopColor ("TopColor", Color) = (0, 0, 0, 1)

        _BladeWidth("Blade Width", Float) = 0.05
        _BladeWidthRandom("Blade Width Random", Float) = 0.02

        _BladeHeight("Blade Height", Float) = 0.5
        _BladeHeightRandom("Blade Height Random", Float) = 0.3

        _BladeForward("Blade Forward Amount", Float) = 0.38
        _BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2

        _BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2

        _WindDistortionMap("Wind Distortion Map", 2D) = "black" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0, 0.05, 0)
        _WindStrength("Wind Strength", Float) = 1

        _ExtraBias ("ExtraBias", Float) = 0
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    
    #define UNITY_PI 3.14

    //get a scalar random value from a 3d value
    float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719))
    {
        //make value smaller to avoid artefacts
        float3 smallValue = sin(value);
        //get scalar value from 3d vector
        float random = dot(smallValue, dotDir);
        //make value more random by making it bigger and then taking the factional part
        random = frac(sin(random) * 143758.5453);
        return random;
    }

    float3x3 getTransformationMatrixAngleAxis3x3(float angle, float3 axis)
    {
        float c, s;
        sincos(angle, s, c);

        float t = 1 - c;
        float x = axis.x;
        float y = axis.y;
        float z = axis.z;

        return float3x3(
            t * x * x + c, t * x * y - s * z, t * x * z + s * y,
            t * x * y + s * z, t * y * y + c, t * y * z - s * x,
            t * x * z - s * y, t * y * z + s * x, t * z * z + c
            );
    }

    struct VertexData
    {
        float3 position;
        float3 normal;
        float2 uv;
        float4 tangent;
        float3 binormal;
    };

    StructuredBuffer<VertexData> GrassVerticesData;
    StructuredBuffer<int> GrassIndexes;

    StructuredBuffer<VertexData> GrassPositionsData;

    float4x4 _LocalToWorld;
    float4x4 _WorldToLocal;

    float3 transformObjectToWorld(float3 positionOS)
    {
        return mul(_LocalToWorld, float4(positionOS, 1.0)).xyz;
    }

    float3 transformObjectToWorldNormal(float3 normalOS, bool doNormalize = true)
    {
        // Normal need to be multiply by inverse transpose
        float3 normalWS = mul(normalOS, _WorldToLocal);
        if (doNormalize)
            return SafeNormalize(normalWS);

        return normalWS;
    }

    struct v2f //TODO create 2 structs
    {
        float4 vertex : SV_POSITION;
        float3 normal: NORMAL;
        float2 uv : TEXCOORD0;
        float4 shadowCoord : TEXCOORD1;
        float4 tangent: TANGENT;
    };

    struct VertexInfo
    {
        float3 position;
        float3 normal;
        float2 uv;
        float4 shadowCoord;
        float4 tangent;
    };

    float4 _BottomColor;
    float4 _TopColor;

    float _BladeWidth;
    float _BladeWidthRandom;

    float _BladeHeight;
    float _BladeHeightRandom;

    float _BladeForward;
    float _BladeCurve;

    float _BendRotationRandom;

    sampler2D _WindDistortionMap;
    float4 _WindDistortionMap_ST;
    float2 _WindFrequency;
    float _WindStrength;

    float _ExtraBias;

    VertexInfo getGrassBladeVertexInfo(uint vertex_id: SV_VertexID, uint instance_id: SV_InstanceID)
    {
        int grassVerticesIndex = GrassIndexes[vertex_id];

        VertexData grassVertexData = GrassVerticesData[grassVerticesIndex];

        VertexData grassPositionData = GrassPositionsData[instance_id];

        float3 grassVertexPosition = grassVertexData.position;

        float width = (rand3dTo1d(grassPositionData.position) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
        grassVertexPosition.x *= width;

        float height = (rand3dTo1d(grassPositionData.position) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
        grassVertexPosition.y *= height;

        float forward = rand3dTo1d(grassPositionData.position.zzy) * _BladeForward;

        float segmentForward = pow(grassVertexPosition.y, _BladeCurve) * forward;
        grassVertexPosition.z = segmentForward;

        float2 wind_uv = grassPositionData.position.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
        float2 windSample = (tex2Dlod(_WindDistortionMap, float4(wind_uv, 0, 0)).rg * 2 - 1) * _WindStrength;
        float3 wind = normalize(float3(windSample.x, 0, windSample.y));

        float3x3 windRotation = getTransformationMatrixAngleAxis3x3(3.14 * windSample * grassVertexPosition.y, wind);

        float3x3 facingRotationMatrix = getTransformationMatrixAngleAxis3x3(rand3dTo1d(grassPositionData.position), float3(0, 1, 0));

        float3x3 bendRotationMatrix = getTransformationMatrixAngleAxis3x3(rand3dTo1d(grassPositionData.position.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0)); //TODO remove or explain

        float3 binormal = grassPositionData.binormal;
        float3 normal = grassPositionData.normal;
        float4 tangent = grassPositionData.tangent;

        binormal = cross(normal, tangent) * tangent.w;

        float3x3 localToTangent = float3x3
        (
            tangent.x, normal.x, binormal.x,
            tangent.y, normal.y, binormal.y,
            tangent.z, normal.z, binormal.z
        );

        //float3x3 transformationMatrix = mul(bendRotationMatrix, facingRotationMatrix);

        //transformationMatrix = mul(windRotation, transformationMatrix);

        float3x3 transformationMatrix = windRotation;

        transformationMatrix = mul(localToTangent, transformationMatrix);

        float3 positionOS = mul(transformationMatrix, grassVertexPosition) + grassPositionData.position;
        float4 positionWS = mul(_LocalToWorld, float4(positionOS, 1.0));

        VertexInfo output = (VertexInfo)0;

        output.position = positionOS;

        output.normal = mul(localToTangent, grassVertexData.normal);

        output.uv = grassVertexData.uv;

        output.tangent = tangent;

        return output;
    }

    ENDHLSL

    SubShader
    {
        Tags 
        {
            "RenderType"="Opaque" 
            "LightMode" = "UniversalForward"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            VertexPositionInputs getVertexPositionInputs(float3 positionOS)
            {
                VertexPositionInputs input;
                input.positionWS = transformObjectToWorld(positionOS);
                input.positionVS = TransformWorldToView(input.positionWS);
                input.positionCS = TransformWorldToHClip(input.positionWS);

                float4 ndc = input.positionCS * 0.5f;
                input.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
                input.positionNDC.zw = input.positionCS.zw;

                return input;
            }

            v2f vert(uint vertex_id: SV_VertexID, uint instance_id: SV_InstanceID)
            {
                VertexInfo vertexInfo = getGrassBladeVertexInfo(vertex_id, instance_id);
                
                VertexPositionInputs inputs = getVertexPositionInputs(vertexInfo.position);

                v2f output = (v2f)0;

                output.normal = transformObjectToWorldNormal(vertexInfo.normal);

                output.vertex = inputs.positionCS;
                output.shadowCoord = GetShadowCoord(inputs);

                return output;
            }

            half4 frag(v2f input) : SV_TARGET
            {
                Light mainLight = GetMainLight(input.shadowCoord);

                float3 normal = normalize(input.normal);
                float NdotL = dot(_MainLightPosition, normal);

                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                
                float4 lightColor = NdotL*float4(attenuatedLightColor, 1);

                half NdotL2 = saturate(dot(input.normal, mainLight.direction));
                float4 lightIntensity = float4(NdotL2*mainLight.color, 1);

                return lerp(_BottomColor, _TopColor*lightIntensity, input.uv.y)* mainLight.shadowAttenuation;

                //return lerp(_BottomColor, _TopColor, input.uv.y);
            }

            ENDHLSL
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma multi_compile_shadowcaster
            

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            CBUFFER_END
            float4 _BaseColor;
            float _Cutoff;

            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            float4 getShadowPositionHClip(float3 positionOS, float3 normalOS)
            {
                float3 positionWS = transformObjectToWorld(positionOS);
                float3 normalWS = transformObjectToWorldNormal(normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;
            }

            v2f ShadowVert(uint vertex_id: SV_VertexID, uint instance_id: SV_InstanceID)
            {
                v2f output = (v2f)0;

                VertexInfo vertexInfo = getGrassBladeVertexInfo(vertex_id, instance_id);

                _ShadowBias.x += _ExtraBias;

                output.vertex = getShadowPositionHClip(vertexInfo.position, vertexInfo.normal);

                return output;
            }

            float4 ShadowFrag(v2f i) : SV_Target
            {
                return float4(1, 1, 1, 1);
            }

            ENDHLSL
        }
    }
}
