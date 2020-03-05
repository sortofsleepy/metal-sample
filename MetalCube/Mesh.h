//
//  Plane.h
//  MetalCube
//
//  Created by josephchow on 3/5/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#ifndef Plane_h
#define Plane_h

#include <Metal/Metal.h>
#include <memory>
#include <vector>
#include "Vbo.h"

typedef std::shared_ptr<class Mesh>MeshRef;

class Mesh {
public:
    Mesh(id<MTLDevice> device):
    device(device),
    hasIndices(false),
    primType(MTLPrimitiveTypeTriangle),
    meshCompiled(false){
        
        // initialize descriptor.
        descrip = [[MTLRenderPipelineDescriptor alloc] init];
        
    }
    
    static MeshRef create(id<MTLDevice> device){
        auto ref= MeshRef(new Mesh(device));
       
        return ref;
    }
    
    
    //! Loads a shader for the mesh.
    void loadShader(NSString * vertex, NSString * fragment){
        id <MTLLibrary> defaultLibrary = [device newDefaultLibrary];
        vertex_func = [defaultLibrary newFunctionWithName:vertex];
        fragment_func = [defaultLibrary newFunctionWithName:fragment];
    }
    
    
    //! Sets a label to use in the render pipeline for debugging.
    void setPipelineLabel(NSString * label){
        descrip.label = label;
    }
    
    //! compiles the mesh in preperation for rendering. Must be compiled prior to rendering.
    void compileMesh(){
        
        // ====== COMPILE THE RENDER PIPELINE =========== //
        
        NSError * err = nil;
        renderPipeline = [device newRenderPipelineStateWithDescriptor:descrip error:&err];
        if (err != nil) {
            NSLog(@"Error creating render pipeline state: %@",[err localizedFailureReason]);
        }
        
        
    }
    
    //! Sets the primitive type of the mesh.
    void setPrimType(MTLPrimitiveType type){ primType = type;}
    
    //! Render the mesh
    void render(id<MTLCommandBuffer> commandBuffer, id<MTLRenderCommandEncoder> renderEncoder){
        
        if(!meshCompiled){
            return;
        }
        
        [renderEncoder setRenderPipelineState:renderPipeline];
        
        
        
        if(hasIndices){
            
        }else{
            [renderEncoder drawIndexedPrimitives:primType
                                           indexCount:(NSInteger)indices->getDataSize()
                                            indexType:MTLIndexTypeUInt16
                                          indexBuffer:indices->getBuffer()
                                    indexBufferOffset:0];
        }
        
        [renderEncoder endEncoding];
    }
    
    //! Loads vertex information for a mesh.
    template<typename T>
    void loadVertices(std::vector<T> data){
        vertices = Vbo::create(device);
        vertices->bufferData(data);
    }
    
    //! sets index data on the mesh.
    void setIndices(std::vector<uint16_t> _indices){
       
        indices = Vbo::create(device);
        indices->bufferData(_indices);
        
        hasIndices = true;
        
    }

protected:
    
    //! Describes the primitive type to use when rendering
    MTLPrimitiveType primType;
    
    //! The descriptor for the rendering pipeline.
    MTLRenderPipelineDescriptor * descrip;
    
    //! The render pipeline state object for the mesh
    id <MTLRenderPipelineState> renderPipeline;
    
    //! Reference to the current metal device.
    id <MTLDevice> device;
    
    //! The vertex function to use
    id <MTLFunction> vertex_func;
    
    //! The fragment function to use
    id <MTLFunction> fragment_func;
    
    //! flag to check if a mesh has indices
    bool hasIndices;
    
    //! Flag to check to see if a mesh has been compiled yet.
    bool meshCompiled;

    //! vbo buffers to keep track of mesh data.
    VboRef vertices,indices;
      
};

#endif /* Plane_h */
