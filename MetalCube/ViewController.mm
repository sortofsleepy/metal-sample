//
//  ViewController.m
//  sfgesfesf
//
//  Created by josephchow on 2/20/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#import "ViewController.h"
#include "MetalCam.h"

@interface ViewController () <MTKViewDelegate, ARSessionDelegate>

@property(nonatomic,strong) MTKView *view;
@property (nonatomic, strong) ARSession *session;
@property (nonatomic, strong) MetalCam * camera;


@end


@interface MTKView () <RenderDestinationProvider>

@end

//! borrowed from https://github.com/wdlindmeier/Cinder-Metal/blob/master/include/MetalHelpers.hpp
      //! helpful converting to and from SIMD
      template <typename T, typename U >
      const U static inline convert( const T & t )
      {
          U tmp;
          memcpy(&tmp, &t, sizeof(U));
          U ret = tmp;
          return ret;
      }


@implementation ViewController
@dynamic view;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create an ARSession
    self.session = [ARSession new];
    self.session.delegate = self;
    
    // Set the view to use the default device
    self.view = (MTKView *)self.view;
    self.view.device = MTLCreateSystemDefaultDevice();
    self.view.backgroundColor = UIColor.clearColor;
    self.view.delegate = self;
    
    if(!self.view.device) {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    // initialize camera.
    _camera = [[MetalCam alloc] setup:self.session :self.view.device];
    
    [_camera setOrientation:self.view.window.windowScene.interfaceOrientation];
    
    
    // generate geometry
    [self generateCube];
    
    // setup camera matrices and model matrix.
    [self setupCamera];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObjectsFromArray:self.view.gestureRecognizers];
    self.view.gestureRecognizers = gestureRecognizers;
}

- (void) setupCamera {
  
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float aspect = screenBounds.size.width / screenBounds.size.height;
    
    projectionMatrix = matrix_identity_float4x4;
    viewMatrix = matrix_identity_float4x4;
    modelMatrix = matrix_identity_float4x4;
    

    // build the projection matrix
    projectionMatrix = convert<GLKMatrix4,matrix_float4x4>(GLKMatrix4MakePerspective(50.0, aspect, 0.1, 1000.0));
    
    // build view matrix.
    GLKMatrix4 view = GLKMatrix4Identity;
    view = GLKMatrix4Translate(view, 0, 0, -20);
    viewMatrix = convert<GLKMatrix4,matrix_float4x4>(view);
    
    uniforms.projection = projectionMatrix;
    uniforms.view = viewMatrix;
    uniforms.model = modelMatrix;
    
    ubo = UBO::create(self.view.device);
    ubo->setData(uniforms);
    
}

- (void) generateCube {
    cubeVerts= Vbo::create(self.view.device);
    cubeUvs = Vbo::create(self.view.device);
    cubeIndices = Vbo::create(self.view.device);
    
    std::vector<float> vertices = {
        -10,10,10,0,10,10,10,10,10,-10,0,10,0,0,10,10,0,10,-10,-10,10,0,-10,10,10,-10,10,10,10,-10,0,10,-10,-10,10,-10,10,0,-10,0,0,-10,-10,0,-10,10,-10,-10,0,-10,-10,-10,-10,-10,-10,10,-10,-10,10,0,-10,10,10,-10,0,-10,-10,0,0,-10,0,10,-10,-10,-10,-10,-10,0,-10,-10,10,10,10,10,10,10,0,10,10,-10,10,0,10,10,0,0,10,0,-10,10,-10,10,10,-10,0,10,-10,-10,-10,10,-10,0,10,-10,10,10,-10,-10,10,0,0,10,0,10,10,0,-10,10,10,0,10,10,10,10,10,-10,-10,10,0,-10,10,10,-10,10,-10,-10,0,0,-10,0,10,-10,0,-10,-10,-10,0,-10,-10,10,-10,-10
    };
    
    std::vector<float> uvs = {
    0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0
    };
    
    
    std::vector<float> indices = {
        0,3,4,0,4,1,1,4,5,1,5,2,3,6,7,3,7,4,4,7,8,4,8,5,9,12,13,9,13,10,10,13,14,10,14,11,12,15,16,12,16,13,13,16,17,13,17,14,18,21,22,18,22,19,19,22,23,19,23,20,21,24,25,21,25,22,22,25,26,22,26,23,27,30,31,27,31,28,28,31,32,28,32,29,30,33,34,30,34,31,31,34,35,31,35,32,36,39,40,36,40,37,37,40,41,37,41,38,39,42,43,39,43,40,40,43,44,40,44,41,45,48,49,45,49,46,46,49,50,46,50,47,48,51,52,48,52,49,49,52,53,49,53,50
    };
    
    // store data into buffers.
    cubeVerts->bufferData(vertices);
    cubeUvs->bufferData(uvs);
    cubeIndices->bufferData(indices);
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];

    // turn on enviromental texturing.
    

    
    
    
    //[self.session runWithConfiguration:configuration];
    [self.session runWithConfiguration:configuration];

    // setup orientation changes
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@sel name:<#(nullable NSNotificationName)#> object:<#(nullable id)#>]
    
}

-(void) viewWillLayoutSubviews {
    [_camera setOrientation:self.view.window.windowScene.interfaceOrientation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.session pause];
}

- (void)handleTap:(UIGestureRecognizer*)gestureRecognize {
   
}

#pragma mark - MTKViewDelegate

// Called whenever view changes orientation or layout is changed
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
 
}

// Called whenever the view needs to render
- (void)drawInMTKView:(nonnull MTKView *)view {
    [_camera update:self.view.currentRenderPassDescriptor drawable:self.view.currentDrawable];
    
}

#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end
