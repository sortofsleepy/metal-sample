//
//  ViewController.h
//  sfgesfesf
//
//  Created by josephchow on 2/20/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ARKit/ARKit.h>
#import "Vbo.h"
#import "Ubo.h"

struct CameraUniforms {
    matrix_float4x4 projection;
    matrix_float4x4 view;
    matrix_float4x4 model;
    float color;
};


@interface ViewController : UIViewController{
    VboRef cubeVerts,cubeIndices,cubeUvs,testVbo;
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 modelMatrix;
    
    CameraUniforms uniforms;
    UboRef ubo;
}

// generates necessary buffers for the cube.
- (void) generateCube;

// generates the necessary information for the camera information.
- (void) setupCamera;
@end


