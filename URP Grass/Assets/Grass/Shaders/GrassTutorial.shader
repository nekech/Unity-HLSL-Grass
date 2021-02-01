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
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    
    #define UNITY_PI 3.14

    //get a scalar random value from a 3d value from 0 to 1
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

    //create rotationa matrix
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

    //buffer with vertices data of grass blade mesh
    StructuredBuffer<VertexData> GrassVerticesData;
    //buffer with indexes data of grass blade mesh
    StructuredBuffer<int> GrassIndexes;

    //buffer with verticesdata of grass attached object, positions of grass blades
    StructuredBuffer<VertexData> GrassPositionsData;

    //transformation matrix from object space to world space
    float4x4 _LocalToWorld;
    //transformation matrix from world space to local space
    float4x4 _WorldToLocal;

    //transfor poins from object space to world space
    float3 transformObjectToWorld(float3 positionOS)
    {
        return mul(_LocalToWorld, float4(positionOS, 1.0)).xyz;
    }

    //normal vector from object space to world space
    float3 transformObjectToWorldNormal(float3 normalOS, bool doNormalize = true)
    {
        // Normal need to be multiply by inverse transpose
        float3 normalWS = mul(normalOS, _WorldToLocal);
        if (doNormalize)
            return SafeNormalize(normalWS);

        return normalWS;
    }

    //information about vertex for fragment shader from vertex shader
    struct v2f
    {
        float4 vertex : SV_POSITION;
        float3 normal: NORMAL;
        float2 uv : TEXCOORD0;
        float4 shadowCoord : TEXCOORD1;
        float4 tangent: TANGENT;
    };

    //struct with information about blade of grass vertices
    struct VertexInfo
    {
        float3 position;
        float3 normal;
        float2 uv;
        float4 shadowCoord;
        float4 tangent;
    };

    //declaration block
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

    //compute information about blade of grass vertices
    VertexInfo getGrassBladeVertexInfo(uint vertex_id: SV_VertexID, uint instance_id: SV_InstanceID)
    {
        //get index of vertices in array of vertices
        int grassVerticesIndex = GrassIndexes[vertex_id];

        //get vertices data
        VertexData grassVertexData = GrassVerticesData[grassVerticesIndex];

        //get blade of grass position data
        VertexData grassPositionData = GrassPositionsData[instance_id];

        float3 grassVertexPosition = grassVertexData.position;

        //compute width of curent blade of grass
        float width = (rand3dTo1d(grassPositionData.position) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
        //move x vertex position due to random width
        grassVertexPosition.x *= width;

        //compute height
        float height = (rand3dTo1d(grassPositionData.position) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
        //move y vertex position due to random height
        grassVertexPosition.y *= height;

        //compute random forward coeficient
        float forward = rand3dTo1d(grassPositionData.position.zzy) * _BladeForward;

        //compute forward
        float segmentForward = pow(grassVertexPosition.y, _BladeCurve) * forward;
        //move z vertex position due to forward offset
        grassVertexPosition.z = segmentForward;

        //compute uv coordinate for wind flow map
        float2 wind_uv = grassPositionData.position.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
        //get wind value in current position
        float2 windSample = (tex2Dlod(_WindDistortionMap, float4(wind_uv, 0, 0)).rg * 2 - 1) * _WindStrength;
        //create vector of wind in current position
        float3 wind = normalize(float3(windSample.x, 0, windSample.y));

        //get rotation matrix for blade of grass from wind
        float3x3 windRotation = getTransformationMatrixAngleAxis3x3(3.14 * windSample * grassVertexPosition.y, wind);

        //get random rotation matrix for blade of grass
        float3x3 facingRotationMatrix = getTransformationMatrixAngleAxis3x3(rand3dTo1d(grassPositionData.position) * UNITY_PI * -0.25, float3(0, 1, 0));

        float3 binormal = grassPositionData.binormal;
        float3 normal = grassPositionData.normal;
        float4 tangent = grassPositionData.tangent;

        //compute binormal
        binormal = cross(normal, tangent) * tangent.w;

        //create transformation matrix from local space to tangent space
        float3x3 localToTangent = float3x3
        (
            tangent.x, normal.x, binormal.x,
            tangent.y, normal.y, binormal.y,
            tangent.z, normal.z, binormal.z
        );

        //combine wind and rotation transformations
        float3x3 transformationMatrix = mul(windRotation, facingRotationMatrix);

        //get position in object (tangent) space from local space
        float3 positionOS = mul(localToTangent, grassVertexPosition);

        //apply transforations to vertex of grass blade
        positionOS = mul(transformationMatrix, positionOS) + grassPositionData.position;

        //declare outpup structure and set all fields to 0
        VertexInfo output = (VertexInfo)0;

        output.position = positionOS;

        //transform normal from local space to tangent space
        output.normal = mul(localToTangent, grassVertexData.normal);
        //apply transformations to normal
        output.normal = mul(transformationMatrix, grassVertexData.normal);

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

            //fill VertexPositionInputs structure with custom transformation functions
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
                //get information about current vertex of grass blade
                VertexInfo vertexInfo = getGrassBladeVertexInfo(vertex_id, instance_id);
                
                //calculate inputs
                VertexPositionInputs inputs = getVertexPositionInputs(vertexInfo.position);

                v2f output = (v2f)0;

                output.uv = vertexInfo.uv;

                //transform normal to world space
                output.normal = transformObjectToWorldNormal(vertexInfo.normal);

                output.vertex = inputs.positionCS;

                //get shadow coordinate
                output.shadowCoord = GetShadowCoord(inputs);

                return output;
            }

            half4 frag(v2f input) : SV_TARGET
            {
                //get main light
                Light mainLight = GetMainLight(input.shadowCoord);

                float3 normal = normalize(input.normal);
                float NdotL = dot(_MainLightPosition, normal);

                //compute attenuated color from main light in current pixel
                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                
                //compute light color
                float4 lightColor = NdotL*float4(attenuatedLightColor, 1);

                half NdotL2 = saturate(dot(input.normal, mainLight.direction));
                //compute light intensity
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

            //custom function to transform shadow position from object space to clip space
            float4 getShadowPositionHClip(float3 positionOS, float3 normalOS)
            {
                float3 positionWS = transformObjectToWorld(positionOS);
                float3 normalWS = transformObjectToWorldNormal(normalOS);
                
                //transform from object space to clip space and apply shadow bias
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