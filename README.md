# SLMTargets
**SLMTargets** is a MATLAB-based GUI for running 3D _holographic_ photostimulation experiments on arbitrary sets of neurons.

![SLMTargets](https://user-images.githubusercontent.com/81040584/191542064-5f83f272-53fc-4393-b11a-1dc8494e90d4.gif)  
* Pictured above is the main interface of **SLMTargets** displaying a two-photon z-stack of lobule Crus I of the cerebellum. Cre-expressing Purkinje cells were labeled virally with [GCaMP8s](https://www.janelia.org/jgcamp8-calcium-indicators). User-defined zones and neural clusters targeted for stimulation are colored uniquely.

# Basic use
**1.** Acquire a **z-stack** of your tissue of interest. The higher the z-resolution of the image stack, the more precise your holographic targeting will be. I recommend using **2-4 µm spacing**. Do ensure the images have a high _signal-to-noise ratio_ (you will likely need to average many images per plane).  

**2.** Run [Cellpose](https://github.com/MouseLand/cellpose) on the z-stack in order to automatically **extract the 3D mask** of each neuronal cell body in the form of a 'masks.tif' file. This file will be loaded into **SLMTargets** and used to detect the _centroid_ of each neuron.  
**Note:** The mask of each neuron will contain pixels that have a value corresponding its ROI number from Cellpose. Please ensure the masks file contains as many images as your z-stack.  
            
<p align="center">
  <img src="https://user-images.githubusercontent.com/81040584/191570971-2d93cfdc-04a0-47f9-8645-fdbd26b1efa8.gif"/>
</p>

**3.** **Optional:** create a 'zone.tif' file in order to define zones within the **xy** plane.  

**4.** Load all files into **SLMTargets** then remove any undesirable neurons, define the stimulation cluster size, and prefered laser power per cell.  


