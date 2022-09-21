# SLMTargets
**SLMTargets** is a MATLAB-based GUI for running 3D _holographic_ photostimulation experiments on arbitrary sets of neurons.

![SLMTargets](https://user-images.githubusercontent.com/81040584/191542064-5f83f272-53fc-4393-b11a-1dc8494e90d4.gif)  
* Pictured above is z-stack of the cerebellum showing Purkinje cells labeled with GCaMP8s.  (User-defined zones and neural clusters are colored uniquely)

# Basic use
**1.** Acquire a **z-stack** of your tissue of interest. The higher the z-resolution of the image stack, the more precise your holograhpic targeting will be. I recommend using 2-4 µm spacing. Do ensure that the images have a high signal-to-noise ratio (you will likely need to average many images per plane).  

**2.** Run [Cellpose](https://github.com/MouseLand/cellpose) on the z-stack in order to automatically extract the 3D position of each neuronal cell body in the form of a 'masks' .tif file. This file will be loaded into SLMTargets and used to detect the centroid of each neuron.  
          ![masks](https://user-images.githubusercontent.com/81040584/191570971-2d93cfdc-04a0-47f9-8645-fdbd26b1efa8.gif)  
          
**3.** Optional: define zones in the xy plane with a 'zone' .tif file.  

**4.** Load all files into SLMTargets then define cluster size, desired laser power per cell, manually included neurons.  


