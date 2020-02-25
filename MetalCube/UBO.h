//
//  UBO.h
//  MetalCube
//
//  Created by josephchow on 2/24/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#ifndef UBO_h
#define UBO_h

#include <memory>

typedef std::shared_ptr<class UBO>UboRef;

/**
    A wrapper around the idea of uniform buffers.
    TODO may not actually need a separate class but it might be nice for readability.
 */
class UBO {
public:
    UBO(id<MTLDevice> device){
        this->device = device;
    }
       
    static UboRef create(id<MTLDevice> device){
        return UboRef(new UBO(device));
    }
       
    
    id<MTLBuffer> getBuffer(){ return buffer; }
    
    template<typename T>
    void setData(T value){
        buffer = [device newBufferWithBytes:&value length:sizeof(T) options:MTLResourceCPUCacheModeDefaultCache];
    }
protected:
    id <MTLBuffer> buffer;
    id <MTLDevice> device;
};

#endif /* UBO_h */
