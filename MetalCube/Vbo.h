//
//  Vbo.h
//  MetalCube
//
//  Created by josephchow on 2/24/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#ifndef Vbo_h
#define Vbo_h

#include <vector>
#include <memory>

/**
 Meant to act in a similar manner to an OpenGL buffer. 
 */
typedef std::shared_ptr<class Vbo> VboRef;
class Vbo {
    
public:
    Vbo(id<MTLDevice> device){
        this->device = device;
    }
    
    static VboRef create(id<MTLDevice> device){
        return VboRef(new Vbo(device));
    }
    
    //! Add data
    template<typename T>
    void bufferData(std::vector<T> &data){
        buffer = [device newBufferWithBytes:data.data() length:sizeof(T) * data.size() options:MTLResourceCPUCacheModeDefaultCache];
    }
    
    //! Returns the buffer.
    id<MTLBuffer> getBuffer() { return buffer; }
    
protected:
    id <MTLDevice> device;
    id <MTLBuffer> buffer;
    
};

#endif /* Vbo_h */
