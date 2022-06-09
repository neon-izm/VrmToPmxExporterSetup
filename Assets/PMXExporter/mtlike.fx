////////////////////////////////////////////////////////////////////////////////////////////////
//
//  MToonLike.fx ver1.1
//  �쐬: furia
//  LICENSE: MIT license
//  
//  Code of "MToon" of "Masataka SUMI" is partly included.
//
////////////////////////////////////////////////////////////////////////////////////////////////
// �p�����[�^�錾

// ���@�ϊ��s��
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldViewMatrix          : WORLDVIEW;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// �}�e���A���F
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
float3   MaterialToon      : TOONCOLOR;
float4   EdgeColor         : EDGECOLOR;
// ���C�g�F
float3   LightDiffuse      : DIFFUSE   < string Object = "Light"; >;
float3   LightAmbient      : AMBIENT   < string Object = "Light"; >;
float3   LightSpecular     : SPECULAR  < string Object = "Light"; >;
static float4 DiffuseColor  = MaterialDiffuse  * float4(LightDiffuse, 1.0f);
static float3 AmbientColor  = saturate(MaterialAmbient  * LightAmbient + MaterialEmmisive);
static float3 SpecularColor = MaterialSpecular * LightSpecular;

bool     parthf;   // �p�[�X�y�N�e�B�u�t���O
bool     transp;   // �������t���O
bool	 spadd;    // �X�t�B�A�}�b�v���Z�����t���O
#define SKII1    1500
#define SKII2    8000
#define Toon     3

// �I�u�W�F�N�g�̃e�N�X�`��
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

// �X�t�B�A�}�b�v�̃e�N�X�`��
texture ObjectSphereMap: MATERIALSPHEREMAP;
sampler ObjSphareSampler = sampler_state {
    texture = <ObjectSphereMap>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

// MMD�{����sampler���㏑�����Ȃ����߂̋L�q�ł��B�폜�s�B
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

////////////////////////////////////////////////////////////////////////////////////////////////
//�ڋ�Ԏ擾
float3x3 compute_tangent_frame(float3 Normal, float3 View, float2 UV)
{
  float3 dp1 = ddx(View);
  float3 dp2 = ddy(View);
  float2 duv1 = ddx(UV);
  float2 duv2 = ddy(UV);

  float3x3 M = float3x3(dp1, dp2, cross(dp1, dp2));
  float2x3 inverseM = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));
  float3 Tangent = mul(float2(duv1.x, duv2.x), inverseM);
  float3 Binormal = mul(float2(duv1.y, duv2.y), inverseM);

  return float3x3(normalize(Tangent), normalize(Binormal), Normal);
}
/*
	float3x3 tangentFrame = compute_tangent_frame(In.Normal, In.Eye, In.Tex);
	float3 normal = normalize(mul(2.0f * tex2D(normalSamp, In.Tex) - 1.0f, tangentFrame));
*/

////////////////////////////////////////////////////////////////////////////////////////////////
// �֊s�`��


struct EDGE_VS_OUTPUT {
    float4 Pos        : POSITION;    // �ˉe�ϊ����W
    float2 Tex        : TEXCOORD1;   // �e�N�X�`��
    float3 Normal        : TEXCOORD2;   // �e�N�X�`��
};

// ���_�V�F�[�_
EDGE_VS_OUTPUT ColorRender_VS(float4 Pos : POSITION, float2 Tex : TEXCOORD0, float3 Normal : NORMAL)
{
    EDGE_VS_OUTPUT Out = (EDGE_VS_OUTPUT)0;
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
	float len = length(mul((float3x3)transpose(WorldMatrix), Normal));
    Out.Pos = mul( Pos, WorldViewProjMatrix );
	
    // �e�N�X�`�����W
    Out.Tex = Tex;

	Out.Normal = Normal;

    return Out;
}

// �s�N�Z���V�F�[�_
float4 ColorRender_PS(EDGE_VS_OUTPUT IN) : COLOR
{
	
    // �e�N�X�`���K�p
	float2 uv = IN.Tex;
	//uv.x /= 3.0f;
    float4 TexColor = tex2D( ObjTexSampler, uv);
    
	return TexColor;

	float border = 0.5f;

	if(SpecularPower < 1.0f)
		border = SpecularPower;

	clip(TexColor.a - border);

    // �֊s�F�œh��Ԃ�
    return EdgeColor;
}
float4 ColorRender_PSC() : COLOR
{
	clip(-1);
    return EdgeColor;
}

// �֊s�`��p�e�N�j�b�N
technique EdgeTec < string MMDPass = "edge"; > {
    pass DrawEdge {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable  = FALSE;

        VertexShader = compile vs_3_0 ColorRender_VS();
        PixelShader  = compile ps_3_0 ColorRender_PSC();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �e�i��Z���t�V���h�E�j�`��

// ���_�V�F�[�_
float4 Shadow_VS(float4 Pos : POSITION) : POSITION
{
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    return mul( Pos, WorldViewProjMatrix );
}

// �s�N�Z���V�F�[�_
float4 Shadow_PS() : COLOR
{
    // �A���r�G���g�F�œh��Ԃ�
    return float4(AmbientColor.rgb, 0.65f);
}

// �e�`��p�e�N�j�b�N
technique ShadowTec < string MMDPass = "shadow"; > {
    pass DrawShadow {
        VertexShader = compile vs_3_0 Shadow_VS();
        PixelShader  = compile ps_3_0 Shadow_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EOFF�j

struct VS_OUTPUT {
    float4 Pos        : POSITION;    // �ˉe�ϊ����W
    float2 Tex        : TEXCOORD1;   // �e�N�X�`��
    float3 Normal     : TEXCOORD2;   // �@��
    float3 Eye        : TEXCOORD3;   // �J�����Ƃ̑��Έʒu
    float4 Pos2      : TEXCOORD4;	 // �X�t�B�A�}�b�v�e�N�X�`�����W
    float4 Color      : COLOR0;      // �f�B�t���[�Y�F
};

// ���_�V�F�[�_
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
    
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );
	Out.Pos2 = Out.Pos;
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    
    Out.Color = MaterialDiffuse;
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    
    return Out;
}

#define UV_X_BORDER	(1.0f/3.0f)
#define UV_X_BORDER_D	(2.0f/3.0f)

// �s�N�Z���V�F�[�_
float4 Basic_PS(VS_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR0
{
    float2 texUv = IN.Tex;
    texUv.x = texUv.x % UV_X_BORDER;
	//texUv.x /= 3.0f;

	float2 normalUv = texUv;
	normalUv.x += UV_X_BORDER_D;

	float2 eUv = texUv;
	eUv.x += UV_X_BORDER;

	float3x3 tangentFrame = compute_tangent_frame(IN.Normal, IN.Eye, IN.Tex);
	
	float3 normal = normalize(mul(2.0f * tex2D(ObjTexSampler, normalUv) - 1.0f, tangentFrame));

	float3 worldNormal = normal;
	worldNormal *= step(0, dot(CameraPosition.xyz - IN.Pos2.xyz, worldNormal)) * 2 - 1;
    worldNormal = normalize(worldNormal);
    
    // �X�y�L�����F�v�Z
    float3 HalfVector = normalize( normalize(IN.Eye) + -LightDirection );
    
	float sp = 5.00f;
	float spf = 0.30f;
    float3 Specular = pow( max(0,dot( HalfVector, normalize(worldNormal) )), sp ) * LightSpecular * spf;
    
    float4 Color = IN.Color;
    float4 ShadowColor = float4(MaterialEmmisive, Color.a);  // �e�̐F
    if ( useTexture ) {
        // �e�N�X�`���K�p
        float4 TexColor = tex2D( ObjTexSampler, texUv );
        Color *= TexColor;
        ShadowColor *= TexColor;
    }

	
	float border = 0.5f;

	if(SpecularPower < 1.0f)
		border = SpecularPower;

	clip(Color.a - border);

    // �X�y�L�����K�p
    Color.rgb += Specular;
    
	
	float lightIntensity = dot(LightDirection, worldNormal);
    lightIntensity = lightIntensity * 0.5 + 0.5; // from [-1, +1] to [0, 1]
	
	
	float diffContrib = dot( normalize(worldNormal) , -LightDirection) * 0.5 +0.5;
	diffContrib = diffContrib*diffContrib;
	///------------



	lightIntensity = lightIntensity * 2.0 - 1.0; // from [0, 1] to [-1, +1]
    //lightIntensity = smoothstep(_ShadeShift, _ShadeShift + (1.0 - _ShadeToony), lightIntensity); // shade & tooned
	
    // lighting with color
    half3 directLighting = lightIntensity * LightDiffuse.rgb; // direct
    half3 indirectLighting = LightAmbient * diffContrib;// * ShadeSH9(half4(worldNormal, 1)); // ambient
    half3 lighting = directLighting + indirectLighting;
    //lighting = lerp(lighting, max(0.001, max(lighting.x, max(lighting.y, lighting.z))), _LightColorAttenuation); // color atten
    float4 ans = lerp(ShadowColor, Color, float4(lighting,1));
	
	if ( useSphereMap ) {
	
        float2 NormalWV = mul( normal, (float3x3)ViewMatrix );
        NormalWV.x = NormalWV.x * 0.5f + 0.5f;
        NormalWV.y = NormalWV.y * -0.5f + 0.5f;

		float3 worldCameraUp = WorldViewMatrix[1].xyz;
		float3 worldView = IN.Eye;
		float3 worldViewUp = normalize(worldCameraUp - worldView * dot(worldView, worldCameraUp));
		float3 worldViewRight = normalize(cross(worldView, worldViewUp));
		float2 rimUv = half2(dot(worldViewRight, worldNormal), dot(worldViewUp, worldNormal)) * 0.5 + 0.5;
		float3 rimLighting = tex2D(ObjSphareSampler, NormalWV);//rimUv);
		ans.rgb += rimLighting;
    }

    half3 emission = tex2D(ObjTexSampler, eUv).rgb * MaterialSpecular.rgb;
    ans.rgb += emission;

    return ans;
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N�i�A�N�Z�T���p�j
// �s�v�Ȃ��͍̂폜��
technique MainTec0 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Basic_PS(false, false, false);
    }
}

technique MainTec1 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, false, false);
        PixelShader  = compile ps_3_0 Basic_PS(true, false, false);
    }
}

technique MainTec2 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, true, false);
        PixelShader  = compile ps_3_0 Basic_PS(false, true, false);
    }
}

technique MainTec3 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, true, false);
        PixelShader  = compile ps_3_0 Basic_PS(true, true, false);
    }
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N�iPMD���f���p�j
technique MainTec4 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, false, true);
        PixelShader  = compile ps_3_0 Basic_PS(false, false, true);
    }
}

technique MainTec5 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, false, true);
        PixelShader  = compile ps_3_0 Basic_PS(true, false, true);
    }
}

technique MainTec6 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, true, true);
        PixelShader  = compile ps_3_0 Basic_PS(false, true, true);
    }
}

technique MainTec7 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, true, true);
        PixelShader  = compile ps_3_0 Basic_PS(true, true, true);
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �Z���t�V���h�E�pZ�l�v���b�g

struct VS_ZValuePlot_OUTPUT {
    float4 Pos : POSITION;              // �ˉe�ϊ����W
    float4 ShadowMapTex : TEXCOORD0;    // Z�o�b�t�@�e�N�X�`��
    float2 Tex        : TEXCOORD1;   // �e�N�X�`��
};

// ���_�V�F�[�_
VS_ZValuePlot_OUTPUT ZValuePlot_VS( float4 Pos : POSITION , float2 Tex : TEXCOORD0)
{
    VS_ZValuePlot_OUTPUT Out = (VS_ZValuePlot_OUTPUT)0;

    // ���C�g�̖ڐ��ɂ�郏�[���h�r���[�ˉe�ϊ�������
    Out.Pos = mul( Pos, LightWorldViewProjMatrix );

    // �e�N�X�`�����W�𒸓_�ɍ��킹��
    Out.ShadowMapTex = Out.Pos;

	Out.Tex = Tex;

    return Out;
}

// �s�N�Z���V�F�[�_
float4 ZValuePlot_PS(VS_ZValuePlot_OUTPUT IN) : COLOR
{

    // �e�N�X�`���K�p
	float2 uv = IN.Tex;
    uv.x = uv.x % UV_X_BORDER;
	//uv.x /= 3.0f;
    float4 TexColor = tex2D( ObjTexSampler, uv);

	float border = 0.5f;

	if(SpecularPower < 1.0f)
		border = SpecularPower;

	clip(TexColor.a - border);

    // R�F������Z�l���L�^����
    return float4(IN.ShadowMapTex.z/IN.ShadowMapTex.w,0,0,1);
}

// Z�l�v���b�g�p�e�N�j�b�N
technique ZplotTec < string MMDPass = "zplot"; > {
    pass ZValuePlot {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 ZValuePlot_VS();
        PixelShader  = compile ps_3_0 ZValuePlot_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EON�j

// �V���h�E�o�b�t�@�̃T���v���B"register(s0)"�Ȃ̂�MMD��s0���g���Ă��邩��
sampler DefSampler : register(s0);

struct BufferShadow_OUTPUT {
    float4 Pos      : POSITION;     // �ˉe�ϊ����W
    float4 ZCalcTex : TEXCOORD0;    // Z�l
    float2 Tex      : TEXCOORD1;    // �e�N�X�`��
    float3 Normal   : TEXCOORD2;    // �@��
    float3 Eye      : TEXCOORD3;    // �J�����Ƃ̑��Έʒu
    float4 Pos2    : TEXCOORD4;	
    float4 Color    : COLOR0;       // �f�B�t���[�Y�F
};

// ���_�V�F�[�_
BufferShadow_OUTPUT BufferShadow_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;

    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );

	Out.Pos2 = Out.Pos;
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
	// ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );
    
    Out.Color = MaterialDiffuse;
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    
    return Out;
}

// �s�N�Z���V�F�[�_
float4 BufferShadow_PS(BufferShadow_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR
{
    float2 texUv = IN.Tex;
    texUv.x = texUv.x % UV_X_BORDER;
	//texUv.x /= 3.0f;

	float2 normalUv = texUv;
	normalUv.x += UV_X_BORDER_D;

	float2 eUv = texUv;
	eUv.x += UV_X_BORDER;

	float3x3 tangentFrame = compute_tangent_frame(IN.Normal, IN.Eye, IN.Tex);
	float3 normal = normalize(mul(2.0f * tex2D(ObjTexSampler, normalUv) - 1.0f, tangentFrame));

	float3 worldNormal = normal;
	worldNormal *= step(0, dot(CameraPosition.xyz - IN.Pos2.xyz, worldNormal)) * 2 - 1;
    worldNormal = normalize(worldNormal);
    
    // �X�y�L�����F�v�Z
    float3 HalfVector = normalize( normalize(IN.Eye) + -LightDirection );
	float sp = 5.00f;
	float spf = 0.30f;
    float3 Specular = pow( max(0,dot( HalfVector, normalize(worldNormal) )), sp ) * LightSpecular * spf;
    
    float4 Color = IN.Color;
    float4 ShadowColor = float4(MaterialEmmisive, Color.a);  // �e�̐F
    if ( useTexture ) {
        // �e�N�X�`���K�p
        float4 TexColor = tex2D( ObjTexSampler, texUv );
        Color *= TexColor;
        ShadowColor *= TexColor;
    }

	
	float border = 0.5f;

	if(SpecularPower < 1.0f)
		border = SpecularPower;

	clip(Color.a - border);

    // �X�y�L�����K�p
    Color.rgb += Specular;
    
    // �e�N�X�`�����W�ɕϊ�
    IN.ZCalcTex /= IN.ZCalcTex.w;
    float2 TransTexCoord;
    TransTexCoord.x = (1.0f + IN.ZCalcTex.x)*0.5f;
    TransTexCoord.y = (1.0f - IN.ZCalcTex.y)*0.5f;
    
	
	float lightIntensity = dot(LightDirection, normalize(worldNormal));
    lightIntensity = lightIntensity * 0.5 + 0.5; // from [-1, +1] to [0, 1]
	
	float diffContrib = dot( normalize(worldNormal) , -LightDirection) * 0.5 +0.5;
	diffContrib = diffContrib*diffContrib;
	
    
    float comp = 1.0f;

    if( any( saturate(TransTexCoord) != TransTexCoord ) ) {
    } else {

        if(parthf) {
            // �Z���t�V���h�E mode2
            comp=1-saturate(max(IN.ZCalcTex.z-tex2D(DefSampler,TransTexCoord).r , 0.0f)*SKII2*TransTexCoord.y-0.3f);
        } else {
            // �Z���t�V���h�E mode1
            comp=1-saturate(max(IN.ZCalcTex.z-tex2D(DefSampler,TransTexCoord).r , 0.0f)*SKII1-0.3f);
        }
        if ( useToon ) {
            // �g�D�[���K�p
            comp = min(saturate(dot(IN.Normal,-LightDirection)*Toon),comp);
            ShadowColor.rgb *= MaterialToon;
        }
    }
	lightIntensity = lightIntensity * comp;
	lightIntensity = lightIntensity * 2.0 - 1.0; // from [0, 1] to [-1, +1]

    // lighting with color
    half3 directLighting = lightIntensity * LightDiffuse.rgb; // direct
    half3 indirectLighting = LightAmbient * diffContrib * comp;// * ShadeSH9(half4(worldNormal, 1)); // ambient
    half3 lighting = directLighting + indirectLighting;
    //lighting = lerp(lighting, max(0.001, max(lighting.x, max(lighting.y, lighting.z))), comp);//_LightColorAttenuation); // color atten
    float4 ans = lerp(ShadowColor, Color, float4(lighting,1));
	
	
	if ( useSphereMap ) {
	
        float2 NormalWV = mul( normal, (float3x3)ViewMatrix );
        NormalWV.x = NormalWV.x * 0.5f + 0.5f;
        NormalWV.y = NormalWV.y * -0.5f + 0.5f;

		float3 worldCameraUp = WorldViewMatrix[1].xyz;
		float3 worldView = normalize(CameraPosition - IN.Pos2);
		float3 worldViewUp = normalize(worldCameraUp - worldView * dot(worldView, worldCameraUp));
		float3 worldViewRight = normalize(cross(worldView, worldViewUp));
		float2 rimUv = float2(dot(worldViewRight, worldNormal), dot(worldViewUp, worldNormal)) * 0.5f + 0.5f;
		float3 rimLighting = tex2D(ObjSphareSampler, NormalWV);//rimUv);
		ans.rgb += rimLighting;
    }

    half3 emission = tex2D(ObjTexSampler, eUv).rgb * MaterialSpecular.rgb;
    ans.rgb += emission;

    return ans;
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N�i�A�N�Z�T���p�j
technique MainTecBS0  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, false, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, false, false);
    }
}

technique MainTecBS1  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, false, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, false, false);
    }
}

technique MainTecBS2  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, true, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, true, false);
    }
}

technique MainTecBS3  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = false; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, true, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, true, false);
    }
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N�iPMD���f���p�j
technique MainTecBS4  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, false, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, false, true);
    }
}

technique MainTecBS5  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, false, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, false, true);
    }
}

technique MainTecBS6  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, true, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, true, true);
    }
}

technique MainTecBS7  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, true, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, true, true);
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
