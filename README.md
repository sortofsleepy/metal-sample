# metal-sample
This is just a simple reference project for how to use Metal. All it does is create a Cube and place it in the middle of the scene while 
simultanneously rendering the camera image from the back camera. It also shows how to use uniform buffers and some shader work in making the cube rotate due to an incrementing value passed via the UBO.

Notes 
====
* Uses ARKit to obtain the camera image 
* Shows how to construct a cube manually 
* Also shows how to render multiple items simultaneously. 
* Note that there are some wrapper classes to make it simpler to remember how to use buffers for instance. 
* Also note that none of this code should be considered best practice, this is just me messing around. 
