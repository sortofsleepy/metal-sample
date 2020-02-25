//
//  Cube.metal
//  MetalCube
//
//  Created by josephchow on 2/24/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"

/**
 Defines the shader functions to render a cube.
*/

typedef struct {
    float3 position [[attribute(kVertexAttributePosition)]];
    float2 texCoord [[attribute(kVertexAttributeTexcoord)]];
} Vertex;


struct DefaultUniforms {
    matrix_float4x4 projection;
    matrix_float4x4 view;
    matrix_float4x4 model;
    float appTime;
};

float3 rotateX(float3 p, float theta){
    float s = sin(theta);
    float c = cos(theta);
    return float3(p.x, p.y * c - p.z * s, p.z * c + p.y * s);
}


float3 rotateY(float3 p, float theta) {
  float s = sin(theta);
  float c = cos(theta);
  return float3(p.x * c + p.z * s, p.y, p.z * c - p.x * s);
}

float3 rotateZ(float3 p, float theta) {
  float s = sin(theta);
  float c = cos(theta);
  return float3(p.x * c - p.y * s, p.y * c + p.x * s, p.z);
}


// vertex shader for the cube.
// index 1 = vertices
// index 2 = uvs
// index 3 uniform buffer
vertex float4 cube_vertex(const device packed_float3* vertex_array [[ buffer(0) ]],
                          const device packed_float3* uv_array [[ buffer(1) ]],
                          constant DefaultUniforms &uniforms [[buffer(2)]],
                          
                           unsigned int vid [[ vertex_id ]]) {
  
    float3 pos = vertex_array[vid];
    
    pos = rotateX(pos, uniforms.appTime);
    pos = rotateY(pos, uniforms.appTime);
    pos = rotateZ(pos, uniforms.appTime);
        
    
    
    
    return  uniforms.projection * uniforms.view * uniforms.model * float4(pos, 1.0); 
    
    
}


// fragment shader for the cube
fragment half4 cube_fragment(constant DefaultUniforms &uniforms [[buffer(0)]]) {
  
    return half4(1.0,sin(uniforms.appTime),0.0,1.0);
}
