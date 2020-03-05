//
//  Session.h
//  MetalCube
//
//  Created by josephchow on 3/5/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#ifndef Session_h
#define Session_h

#include <ARKit/ARKit.h>

#import <sys/utsname.h>

NSString* deviceModelName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}




class Session {
public:
    Session() = default;
   
    
    static void detectDevice(){
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString* name = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    }
    
protected:
    
    NSString* deviceID;
    
    ARSession * session;
    
    
    
}

#endif /* Session_h */
