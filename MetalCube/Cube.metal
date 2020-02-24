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


struct CameraUniforms {
    matrix_float4x4 projection;
    matrix_float4x4 view;
    matrix_float4x4 model;
};

// vertex shader for the cube.
// index 1 = vertices
// index 2 = uvs
// index 3 uniform buffer
vertex float4 cube_vertex(const device packed_float4* vertex_array [[ buffer(0) ]],
                          const device packed_float4* uv_array [[ buffer(1) ]],
                          constant CameraUniforms &uniforms [[buffer(2)]],
                          
                           unsigned int vid [[ vertex_id ]]) {
  
    
    
    
    return vertex_array[vid];
    
    
}


// fragment shader for the cube
fragment half4 cube_fragment() {
  
    return half4(1.0);
}