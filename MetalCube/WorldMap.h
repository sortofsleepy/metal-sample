//
//  WorldMap.h
//  MetalCube
//
//  Created by josephchow on 2/25/20.
//  Copyright © 2020 josephchow. All rights reserved.
//

#ifndef WorldMap_h
#define WorldMap_h

#include <vector>
#include <memory>


typedef std::shared_ptr<class WorldMap>WorldMapRef;

class WorldMap {
public:
  
    WorldMap() = default;
    WorldMap(ARSession * session) { this->session = session; }
    static WorldMapRef create(ARSession * session){
        return WorldMapRef(new WorldMap(session));
    }
    
    void saveMap(NSURL *url){
        
    }
    
    void saveMap(){
        //auto path = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:<#(NSSearchPathDomainMask)#>]
    }
    

protected:
    ARSession * session;
};

#endif /* WorldMap_h */
