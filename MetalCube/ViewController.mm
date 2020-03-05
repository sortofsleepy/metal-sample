//
//  ViewController.m
//  sfgesfesf
//
//  Created by josephchow on 2/20/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#import "ViewController.h"
#include "MetalCam.h"

#import <sys/utsname.h>

NSString* deviceModelName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}


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
    
    //map = WorldMap::create(session);
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObjectsFromArray:self.view.gestureRecognizers];
    self.view.gestureRecognizers = gestureRecognizers;
}

/**
 Build the main UBO that contains necessary data to construct a mock camera.
 */
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
    view = GLKMatrix4Translate(view, 0, 0, -200);
    viewMatrix = convert<GLKMatrix4,matrix_float4x4>(view);
    
    uniforms.projection = projectionMatrix;
    uniforms.view = viewMatrix;
    uniforms.model = modelMatrix;

    ubo = UBO::create(self.view.device);
    ubo->setData(uniforms);
    
}



- (void) updateCamera {
    uniforms.appTime += 0.05;
    ubo->update(uniforms);
}

- (void) generateCube {
    cubeVerts= Vbo::create(self.view.device);
    cubeUvs = Vbo::create(self.view.device);
    cubeIndices = Vbo::create(self.view.device);
    testVbo = Vbo::create(self.view.device);
    
    std::vector<float> data = {
         0.0,  1.0, 0.0,
        -1.0, -1.0, 0.0,
         1.0, -1.0, 0.0
    };


    testVbo->bufferData(data);
    
    
    std::vector<float> vertices = {
       -10,10,10,0,10,10,10,10,10,-10,0,10,0,0,10,10,0,10,-10,-10,10,0,-10,10,10,-10,10,10,10,-10,0,10,-10,-10,10,-10,10,0,-10,0,0,-10,-10,0,-10,10,-10,-10,0,-10,-10,-10,-10,-10,-10,10,-10,-10,10,0,-10,10,10,-10,0,-10,-10,0,0,-10,0,10,-10,-10,-10,-10,-10,0,-10,-10,10,10,10,10,10,10,0,10,10,-10,10,0,10,10,0,0,10,0,-10,10,-10,10,10,-10,0,10,-10,-10,-10,10,-10,0,10,-10,10,10,-10,-10,10,0,0,10,0,10,10,0,-10,10,10,0,10,10,10,10,10,-10,-10,10,0,-10,10,10,-10,10,-10,-10,0,0,-10,0,10,-10,0,-10,-10,-10,0,-10,-10,10,-10,-10
    };
    
    std::vector<float> uvs = {
    0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0,0,1,0.5,1,1,1,0,0.5,0.5,0.5,1,0.5,0,0,0.5,0,1,0
    };
    
    
    std::vector<uint16_t> indices = {
        0,3,4,0,4,1,1,4,5,1,5,2,3,6,7,3,7,4,4,7,8,4,8,5,9,12,13,9,13,10,10,13,14,10,14,11,12,15,16,12,16,13,13,16,17,13,17,14,18,21,22,18,22,19,19,22,23,19,23,20,21,24,25,21,25,22,22,25,26,22,26,23,27,30,31,27,31,28,28,31,32,28,32,29,30,33,34,30,34,31,31,34,35,31,35,32,36,39,40,36,40,37,37,40,41,37,41,38,39,42,43,39,43,40,40,43,44,40,44,41,45,48,49,45,49,46,46,49,50,46,50,47,48,51,52,48,52,49,49,52,53,49,53,50
    };
    
    // store data into buffers.
    cubeVerts->bufferData(vertices);
    cubeUvs->bufferData(uvs);
    cubeIndices->bufferData(indices);
    
    
}

-(bool) isIphone11 {
    if([deviceName isEqualToString: @"iPhone12,3"]){
        return true;
    }else{
        return false;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    deviceName = deviceModelName();
    
    /**
        If iPhone 11 class device, we use body tracking config. Otherwise we shift to use default configuration type.
     */
    
    if(ARBodyTrackingConfiguration.isSupported){
        ARBodyTrackingConfiguration * bodyconfig = [ARBodyTrackingConfiguration new];
        bodyconfig.autoFocusEnabled = true;
        bodyconfig.automaticSkeletonScaleEstimationEnabled = true;
        bodyconfig.planeDetection = true;
            
                
        [self.session runWithConfiguration:bodyconfig];
    }else{
        ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];

        // turn on enviromental texturing.
        configuration.environmentTexturing = AREnvironmentTexturingAutomatic;
        [self.session runWithConfiguration:configuration];
    }
    

    


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
    auto device = self.view.device;
    auto renderPassDescriptor = self.view.currentRenderPassDescriptor;
    
    // TODO probably shouldn't be making a new command queue every time.
    auto commandQueue = [self.view.device newCommandQueue];
    
    // update app time
    [self updateCamera];
      
    // =================== SET CLEAR COLOR ================== //
    
    //[_camera update:self.view.currentRenderPassDescriptor drawable:self.view.currentDrawable];
    MTLClearColor color = MTLClearColor();
    color.red = 0.0f;
    color.green = 104.0 / 255.0;
    color.blue = 55.0 / 255.0;
    color.alpha = 1.0;
    
    renderPassDescriptor.colorAttachments[0].clearColor = color;
       
    // =================== SET PIPELINE  ================== //
    // compile render pipeline
    id <MTLLibrary> defaultLibrary = [device newDefaultLibrary];
    id <MTLFunction> vertex_func = [defaultLibrary newFunctionWithName:@"cube_vertex"];
    id <MTLFunction> fragment_func = [defaultLibrary newFunctionWithName:@"cube_fragment"];
    
    MTLRenderPipelineDescriptor * descrip = [[MTLRenderPipelineDescriptor alloc] init];
    descrip.label = @"Cube Pipeline";
    descrip.vertexFunction = vertex_func;
    descrip.fragmentFunction =fragment_func;
    descrip.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
 
    
    NSError * err = nil;
    auto pipeline = [device newRenderPipelineStateWithDescriptor:descrip error:&err];
    if (err != nil) {
            NSLog(@"Error creating render pipeline state: %@",[err localizedFailureReason]);
    }
    
    // =================== START RENDER  ================== //
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // render the camera image
    [_camera updateWithEncoder:renderEncoder
                        buffer:commandBuffer
                    descriptor:self.view.currentRenderPassDescriptor
                      drawable:self.view.currentDrawable];
    
    
    // ========= START RENDERING CUBE ============== //
    
   
    /*
     [renderEncoder setRenderPipelineState:pipeline];
        
        [renderEncoder setVertexBuffer:cubeVerts->getBuffer() offset:0 atIndex:0];
        [renderEncoder setVertexBuffer:cubeUvs->getBuffer() offset:0 atIndex:1];
        [renderEncoder setVertexBuffer:ubo->getBuffer() offset:0 atIndex:2];
        

        [renderEncoder setFragmentBuffer:ubo->getBuffer() offset:0 atIndex:0];
        
        
        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                  indexCount:(NSInteger)cubeIndices->getDataSize()
                                   indexType:MTLIndexTypeUInt16
                                 indexBuffer:cubeIndices->getBuffer()
                           indexBufferOffset:0];
     
     */
    
    [renderEncoder endEncoding];
    
    
    
    // ============ COMMIT AND PRESENT DRAWING ==================== ///
    
    [commandBuffer presentDrawable:self.view.currentDrawable];
    [commandBuffer commit];
    
    
}



#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

-(void)session:(ARSession*)session didAddAnchors:(nonnull NSArray<__kindof ARAnchor *> *)anchors{
    


    
    for (ARAnchor* anchor in anchors) {
     
        // extract body stuff if supported. 
        if(ARBodyTrackingConfiguration.isSupported){
            if([anchor isKindOfClass:[ARBodyAnchor class]]){
                ARBodyAnchor * bAnchor = (ARBodyAnchor*)anchor;
                BodyAnchorObject _body;
                _body.anchor = bAnchor;
                _body.id = bAnchor.identifier;
           
                
                // figure out if this is a new body or not
                auto it = std::find_if(bodies.begin(),bodies.end(),[=](const BodyAnchorObject& obj){
                    return (obj.id == bAnchor.identifier);
                });
                
                if(it == bodies.end()){
                    bodies.push_back(_body);
                }
                
            }
        }
    
        
        
        if([anchor isKindOfClass:[ARPlaneAnchor class]]){
            NSLog(@"Plane anchor");
        }else if([anchor isKindOfClass:[ARObjectAnchor class]]){
            NSLog(@"Object anchor");
        }else if([anchor isKindOfClass:[ARImageAnchor class]]){
            NSLog(@"ImageAnchor");
        }else if([anchor isKindOfClass:[ARFaceAnchor class]]){
            NSLog(@"Face anchor" );
        }else if([anchor isKindOfClass:[AREnvironmentProbeAnchor class]]){
            NSLog(@"env probe" );
        }
    }
    

       
    
}


- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<__kindof ARAnchor *> *)anchors {
    
    
    auto anchorsCount = session.currentFrame.anchors.count;
    
    for (NSInteger index = 0; index < anchorsCount; index++) {
        
        ARAnchor *anchor = session.currentFrame.anchors[index];
    
        if(ARBodyTrackingConfiguration.isSupported){
            if([anchor isKindOfClass:[ARBodyAnchor class]]){
                     
                     
                                                               
            }
                 
        }
    }
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end
