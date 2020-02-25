//
//  MetalCam.m
//  metal-cam
//
//  Created by josephchow on 2/20/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#import "MetalCam.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "ShaderTypes.h"

// The max number of command buffers in flight
static const NSUInteger kMaxBuffersInFlight = 3;

// The max number anchors our uniform buffer will hold
static const NSUInteger kMaxAnchorInstanceCount = 64;

// The 256 byte aligned size of our uniform structures
//static const size_t kAlignedSharedUniformsSize = (sizeof(SharedUniforms) & ~0xFF) + 0x100;
//static const size_t kAlignedInstanceUniformsSize = ((sizeof(InstanceUniforms) * kMaxAnchorInstanceCount) & ~0xFF) + 0x100;

// Vertex data for an image plane
static const float kImagePlaneVertexData[16] = {
    -1.0, -1.0,  0.0, 1.0,
    1.0, -1.0,  1.0, 1.0,
    -1.0,  1.0,  0.0, 0.0,
    1.0,  1.0,  1.0, 0.0,
};


@implementation MetalCam{
    // The current viewport size
    CGSize _viewportSize;
       
}

-(void) setOrientation:(UIInterfaceOrientation)orientation{
    _orientation = orientation;
}

- (MetalCam*) setup:(ARSession*) session : (id<MTLDevice>) device{
 
    // set references. 
    self.session = session;
    self.device = device;
    
    // load and initailize all the metal components we'll need.
    [self _loadMetal];

    
    return self;
}


-(void) update:(MTLRenderPassDescriptor *)renderPassDescriptor drawable:(id<MTLDrawable>)currentDrawable {
    
    if (!self.session) {
        return;
    }
    
    // if viewport hasn't been set to something other than 0, try to set the viewport
    // values to be 0,0,<auto calcualted width>, <auto calculated height>
    _viewport = [[UIScreen mainScreen] bounds];
    
    // update the camera image.
    [self _updateCamera];
    
   
    // Wait to ensure only kMaxBuffersInFlight are getting proccessed by any stage in the Metal
    //   pipeline (App, Metal, Drivers, GPU, etc)
    dispatch_semaphore_wait(self.inFlightSemaphore, DISPATCH_TIME_FOREVER);
    
    // Create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // give an id to the command buffer so we can identify it during debugging.
    commandBuffer.label = @"CameraRenderCommand";
    
    // Add completion hander which signal _inFlightSemaphore when Metal and the GPU has fully
    //   finished proccssing the commands we're encoding this frame.  This indicates when the
    //   dynamic buffers, that we're writing to this frame, will no longer be needed by Metal
    //   and the GPU.
    __block dispatch_semaphore_t block_sema = self.inFlightSemaphore;
    
    // Retain our CVMetalTextureRefs for the duration of the rendering cycle. The MTLTextures
    //   we use from the CVMetalTextureRefs are not valid unless their parent CVMetalTextureRefs
    //   are retained. Since we may release our CVMetalTextureRef ivars during the rendering
    //   cycle, we must retain them separately here.
    CVBufferRef capturedImageTextureYRef = CVBufferRetain(_capturedImageTextureYRef);
    CVBufferRef capturedImageTextureCbCrRef = CVBufferRetain(_capturedImageTextureCbCrRef);
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
        CVBufferRelease(capturedImageTextureYRef);
        CVBufferRelease(capturedImageTextureCbCrRef);
        
    }];
    
    
    // If we've gotten a renderPassDescriptor we can render to the drawable, otherwise we'll skip
    // any rendering this frame because we have no drawable to draw to
    if (renderPassDescriptor != nil) {
        //NSLog(@"Got render pass descriptor - we can render!");
        
        //if(_cameraImage){
        //    renderPassDescriptor.colorAttachments[0].texture = _cameraTexture;
        //}
        
        
        // Create a render command encoder so we can render into something
        id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        
        // DRAW PRIMATIVE
    
        [self _drawCapturedImageWithCommandEncoder:renderEncoder];
        
        
        // We're done encoding commands
        [renderEncoder endEncoding];
    }else{
        NSLog(@"Error - do not have render pass descriptor");
    }
    
    
      // Schedule a present once the framebuffer is complete using the current drawable
      [commandBuffer presentDrawable:currentDrawable];
      
      // Finalize rendering here & push the command buffer to the GPU
      [commandBuffer commit];
}


-(void) updateWithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder buffer:(id<MTLCommandBuffer>)commandBuffer descriptor:(MTLRenderPassDescriptor *)renderPassDescriptor drawable:(id<MTLDrawable>)currentDrawable{
     if (!self.session) {
         return;
     }
     
     // if viewport hasn't been set to something other than 0, try to set the viewport
     // values to be 0,0,<auto calcualted width>, <auto calculated height>
     _viewport = [[UIScreen mainScreen] bounds];
     
     // update the camera image.
     [self _updateCamera];
     
    
     // Wait to ensure only kMaxBuffersInFlight are getting proccessed by any stage in the Metal
     //   pipeline (App, Metal, Drivers, GPU, etc)
     dispatch_semaphore_wait(self.inFlightSemaphore, DISPATCH_TIME_FOREVER);
     
     
     // Add completion hander which signal _inFlightSemaphore when Metal and the GPU has fully
     //   finished proccssing the commands we're encoding this frame.  This indicates when the
     //   dynamic buffers, that we're writing to this frame, will no longer be needed by Metal
     //   and the GPU.
     __block dispatch_semaphore_t block_sema = self.inFlightSemaphore;
     
     // Retain our CVMetalTextureRefs for the duration of the rendering cycle. The MTLTextures
     //   we use from the CVMetalTextureRefs are not valid unless their parent CVMetalTextureRefs
     //   are retained. Since we may release our CVMetalTextureRef ivars during the rendering
     //   cycle, we must retain them separately here.
     CVBufferRef capturedImageTextureYRef = CVBufferRetain(_capturedImageTextureYRef);
     CVBufferRef capturedImageTextureCbCrRef = CVBufferRetain(_capturedImageTextureCbCrRef);
     
     [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
         dispatch_semaphore_signal(block_sema);
         CVBufferRelease(capturedImageTextureYRef);
         CVBufferRelease(capturedImageTextureCbCrRef);
     }];
     
     
     // If we've gotten a renderPassDescriptor we can render to the drawable, otherwise we'll skip
     // any rendering this frame because we have no drawable to draw to
     if (renderPassDescriptor != nil) {
         // DRAW PRIMATIVE
     
         [self _drawCapturedImageWithCommandEncoder:renderEncoder];
         
         
     }else{
         NSLog(@"Error - do not have render pass descriptor");
     }
}


- (void)_drawCapturedImageWithCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder{
    if (_capturedImageTextureYRef == nil || _capturedImageTextureCbCrRef == nil) {
        //NSLog(@"Have not obtained image");
        return;
    }
    
    // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
    [renderEncoder pushDebugGroup:@"DrawCapturedImage"];
    
    // Set render command encoder state
    [renderEncoder setCullMode:MTLCullModeNone];
    [renderEncoder setRenderPipelineState:_capturedImagePipelineState];
    [renderEncoder setDepthStencilState:_capturedImageDepthState];
    
    // Set mesh's vertex buffers
    [renderEncoder setVertexBuffer:_imagePlaneVertexBuffer offset:0 atIndex:kBufferIndexMeshPositions];
    
    // Set any textures read/sampled from our render pipeline
    [renderEncoder setFragmentTexture:CVMetalTextureGetTexture(_capturedImageTextureYRef) atIndex:kTextureIndexY];
    [renderEncoder setFragmentTexture:CVMetalTextureGetTexture(_capturedImageTextureCbCrRef) atIndex:kTextureIndexCbCr];
    
    // Draw each submesh of our mesh
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
    [renderEncoder popDebugGroup];

}

// ========= CORE / PRIVATE FUNCTIONS ============== //

#pragma mark - Private
- (void) _updateImagePlaneWithFrame{
    
    if(_session.currentFrame != nil){
        
        // Update the texture coordinates of our image plane to aspect fill the viewport
        CGAffineTransform displayToCameraTransform = CGAffineTransformInvert([_session.currentFrame displayTransformForOrientation:_orientation viewportSize:_viewport.size]);
        
        // TODO - example code is fine but here I have to cast? :/
        float *vertexData = (float*)[_imagePlaneVertexBuffer contents];
        
        for (NSInteger index = 0; index < 4; index++) {
            NSInteger textureCoordIndex = 4 * index + 2;
            CGPoint textureCoord = CGPointMake(kImagePlaneVertexData[textureCoordIndex], kImagePlaneVertexData[textureCoordIndex + 1]);
            CGPoint transformedCoord = CGPointApplyAffineTransform(textureCoord, displayToCameraTransform);
            vertexData[textureCoordIndex] = transformedCoord.x;
            vertexData[textureCoordIndex + 1] = transformedCoord.y;
        }
    }
    
    
}
-(void) _updateCamera{
    if(self.session.currentFrame){
         // Create two textures (Y and CbCr) from the provided frame's captured image
         CVPixelBufferRef pixelBuffer = _session.currentFrame.capturedImage;
        
        
         
         CVBufferRelease(_capturedImageTextureYRef);
         CVBufferRelease(_capturedImageTextureCbCrRef);
        
         _capturedImageTextureYRef = [self _createTextureFromPixelBuffer:pixelBuffer pixelFormat:MTLPixelFormatR8Unorm planeIndex:0];
         _capturedImageTextureCbCrRef = [self _createTextureFromPixelBuffer:pixelBuffer pixelFormat:MTLPixelFormatRG8Unorm planeIndex:1];
        
        [self _updateImagePlaneWithFrame];
         
    }
}


- (CVMetalTextureRef)_createTextureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer pixelFormat:(MTLPixelFormat)pixelFormat planeIndex:(NSInteger)planeIndex {
    
    const size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
    const size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    
    CVMetalTextureRef mtlTextureRef = nil;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, _capturedImageTextureCache, pixelBuffer, NULL, pixelFormat, width, height, planeIndex, &mtlTextureRef);
    if (status != kCVReturnSuccess) {
        CVBufferRelease(mtlTextureRef);
        mtlTextureRef = nil;
        NSLog(@"Issue creating texture from pixel buffer");
    }
    
    return mtlTextureRef;
}

-(void) _loadMetal{
    _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
    //_depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    _depthStencilPixelFormat = MTLPixelFormatInvalid;
    _colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    _sampleCount = 1;
    
    
    // ============== BUILD VERTEX BUFFER FOR SHOWING CAMERA IMAGE ================= //
    // Create a vertex buffer with our image plane vertex data.
    _imagePlaneVertexBuffer = [self.device newBufferWithBytes:&kImagePlaneVertexData length:sizeof(kImagePlaneVertexData) options:MTLResourceCPUCacheModeDefaultCache];
      
    _imagePlaneVertexBuffer.label = @"ImagePlaneVertexBuffer";
    
    
    // ============== LOAD SHADER ================== //

    // Load all the shader files with a metal file extension in the project
    // NOTE - this line will throw an exception if you don't have a .metal file as part of your compiled sources.
    id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        
    id <MTLFunction> capturedImageVertexFunction = [defaultLibrary newFunctionWithName:@"capturedImageVertexTransform"];
    id <MTLFunction> capturedImageFragmentFunction = [defaultLibrary newFunctionWithName:@"capturedImageFragmentShader"];
    
  
    // ======== BUILD VERTEX DATA ================= //
    // Create a vertex descriptor for our image plane vertex buffer
    MTLVertexDescriptor *imagePlaneVertexDescriptor = [[MTLVertexDescriptor alloc] init];
         
    // build camera image plane
    // Positions.
    imagePlaneVertexDescriptor.attributes[kVertexAttributePosition].format = MTLVertexFormatFloat2;
    imagePlaneVertexDescriptor.attributes[kVertexAttributePosition].offset = 0;
    imagePlaneVertexDescriptor.attributes[kVertexAttributePosition].bufferIndex = kBufferIndexMeshPositions;
         
    // Texture coordinates.
    imagePlaneVertexDescriptor.attributes[kVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    imagePlaneVertexDescriptor.attributes[kVertexAttributeTexcoord].offset = 8;
    imagePlaneVertexDescriptor.attributes[kVertexAttributeTexcoord].bufferIndex = kBufferIndexMeshPositions;
         
    // Position Buffer Layout
    imagePlaneVertexDescriptor.layouts[kBufferIndexMeshPositions].stride = 16;
    imagePlaneVertexDescriptor.layouts[kBufferIndexMeshPositions].stepRate = 1;
    imagePlaneVertexDescriptor.layouts[kBufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;
    
    // =========== BUILD RENDER PIPELINE ===================== //

    // Create a pipeline state for rendering the captured image
    MTLRenderPipelineDescriptor *capturedImagePipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    capturedImagePipelineStateDescriptor.label = @"MyCapturedImagePipeline";
    capturedImagePipelineStateDescriptor.sampleCount = _sampleCount;
    capturedImagePipelineStateDescriptor.vertexFunction = capturedImageVertexFunction;
    capturedImagePipelineStateDescriptor.fragmentFunction = capturedImageFragmentFunction;
    capturedImagePipelineStateDescriptor.vertexDescriptor = imagePlaneVertexDescriptor;
    capturedImagePipelineStateDescriptor.colorAttachments[0].pixelFormat = _colorPixelFormat;

    capturedImagePipelineStateDescriptor.depthAttachmentPixelFormat = _depthStencilPixelFormat;
    capturedImagePipelineStateDescriptor.stencilAttachmentPixelFormat = _depthStencilPixelFormat;
   
    NSError *error = nil;
    _capturedImagePipelineState = [_device newRenderPipelineStateWithDescriptor:capturedImagePipelineStateDescriptor error:&error];
    if (!_capturedImagePipelineState) {
       NSLog(@"Failed to created captured image pipeline state, error %@", error);
    }
    
    // do stencil setup
    // TODO this might not be needed in this case.
    MTLDepthStencilDescriptor *capturedImageDepthStateDescriptor = [[MTLDepthStencilDescriptor alloc] init];
    capturedImageDepthStateDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
    capturedImageDepthStateDescriptor.depthWriteEnabled = NO;
    _capturedImageDepthState = [_device newDepthStencilStateWithDescriptor:capturedImageDepthStateDescriptor];
          
    // initialize image cache
    CVMetalTextureCacheCreate(NULL, NULL, _device, NULL, &_capturedImageTextureCache);
          
    // Create the command queue
    _commandQueue = [_device newCommandQueue];
       
}

- (void)dealloc {
    CVBufferRelease(_capturedImageTextureYRef);
    CVBufferRelease(_capturedImageTextureCbCrRef);
}
- (void)drawRectResized:(CGSize)size {
    _viewportSize = size;
    _viewportSizeDidChange = YES;
}
@end
