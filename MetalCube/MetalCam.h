//
//  MetalCam.h
//  metal-cam
//
//  Created by josephchow on 2/20/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#ifndef MetalCam_h
#define MetalCam_h

#import <Metal/Metal.h>
#import <ARKit/ARKit.h>

// example of preprocessor definitions
#ifdef __IPHONE_13_0

#endif


NS_ASSUME_NONNULL_BEGIN

/*
 Protocol abstracting the platform specific view in order to keep the Renderer
 class independent from platform.
 */
@protocol RenderDestinationProvider

@property (nonatomic, readonly, nullable) MTLRenderPassDescriptor *currentRenderPassDescriptor;
@property (nonatomic, readonly, nullable) id<MTLDrawable> currentDrawable;

@property (nonatomic) MTLPixelFormat colorPixelFormat;
@property (nonatomic) MTLPixelFormat depthStencilPixelFormat;
@property (nonatomic) NSUInteger sampleCount;

@end


@interface MetalCam : NSObject {

    id <MTLTexture> _renderTarget;
    id <MTLCommandQueue> _commandQueue;
    id <MTLBuffer> _sharedUniformBuffer;
    id <MTLBuffer> _imagePlaneVertexBuffer;
    id <MTLRenderPipelineState> _capturedImagePipelineState;
    id <MTLDepthStencilState> _capturedImageDepthState;
    
    // texture refering to y texture
    CVMetalTextureRef _capturedImageTextureYRef;
    
    // texture refering to CbCr texture
    CVMetalTextureRef _capturedImageTextureCbCrRef;
    
    // texture refering to depth map
    CVMetalTextureRef _depthTexture;
    
    //! Combined camera image that gets rendered onto
    CVMetalTextureRef _cameraImage;
    
    id<MTLTexture> _cameraTexture;
    
    // maintains knowledge of the current orientation of the device
    UIInterfaceOrientation _orientation;
    
    // Flag for viewport size changes
    BOOL _viewportSizeDidChange;
    
    // current viewport settings - using CGRect cause
    // it's needed to allow things to render correctly.
    CGRect _viewport;
    
    // texture caches for the camera image. 
    CVMetalTextureCacheRef _capturedImageTextureCache,_combinedCameraTextureCache;
    
    //! depth data for the current frame. 
    AVDepthData * depthData;

}

@property(nonatomic,retain)dispatch_semaphore_t inFlightSemaphore;
@property (nonatomic) MTLPixelFormat colorPixelFormat;
@property (nonatomic) MTLPixelFormat depthStencilPixelFormat;
@property (nonatomic) NSUInteger sampleCount;
@property (nonatomic,retain)id<MTLDevice> device;
@property(nonatomic,retain)ARSession * session;

//set the orientation of the current rotation.
-(void) setOrientation: (UIInterfaceOrientation) orientation;

//! Initialize the camera 
- (MetalCam*) setup:(ARSession*) session : (id<MTLDevice>) device;

//! Updates the camera image on the plane. Pass in a renderpass descriptor from the View used to render the camera.
- (void) update: (MTLRenderPassDescriptor*) renderPassDescriptor drawable:(id<MTLDrawable>) currentDrawable;

- (void) updateWithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
                buffer:(id<MTLCommandBuffer>) commandBuffer
                descriptor:(MTLRenderPassDescriptor*) renderPassDescriptor
                  drawable:(id<MTLDrawable>) currentDrawable;

//! Builds textures from the camera pixel buffer of each frame.
- (CVMetalTextureRef)_createTextureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer pixelFormat:(MTLPixelFormat)pixelFormat planeIndex:(NSInteger)planeIndex;

//! Render the quad used to show the camera image. 
- (void)_drawCapturedImageWithCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder;

// ====== PRIVATE ========= //
-(void) _updateCamera;
-(void) _loadMetal;
-(void) _updateImagePlaneWithFrame;
@end


#endif /* MetalCam_h */

NS_ASSUME_NONNULL_END
