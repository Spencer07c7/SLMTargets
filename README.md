# SLMTargets
**SLMTargets** is a MATLAB-based GUI for running 3D _holographic_ photostimulation experiments on arbitrary sets of neurons. Its output consists of  phase masks for creating custom holograms with a reflective _phase only_ LCoS [spatial light modulator](https://en.wikipedia.org/wiki/Spatial_light_modulator) (SLM) and [Bruker](https://www.bruker.com/en/products-and-solutions/mr.html?gclid=Cj0KCQjwj7CZBhDHARIsAPPWv3dGf_KSiU_riwNS8jdjhhcRLIdNeDB6sLp11rB1zRIoYhl91VFGrkQaAqXSEALw_wcB) microscope control files used for photostimulation experiments.

![SLMTargets](https://user-images.githubusercontent.com/81040584/191542064-5f83f272-53fc-4393-b11a-1dc8494e90d4.gif)  
[ The **main interface** displaying a two-photon z-stack of Purkinje cells of the cerebellum labeled with the calcium indicator [GCaMP8s](https://www.janelia.org/jgcamp8-calcium-indicators). User-defined zones and neural clusters targeted for stimulation are colored uniquely. ]
# Background: modulating light in space
When light strikes the surface of an LCoS SLM, it is reflected and phase shifted according to the [refractive index](https://en.wikipedia.org/wiki/Refractive_index) of the pixel it passes through - a property that is conveniently modifiable with voltage. Thus the user is empowered with the ability to pattern the phase of the reflected wavefront in a spatially specific manner simply by setting the voltage at each pixel to a desired value. This is achieved by uploading a phase mask image to the SLM. When phase-modulated light is subsequently passed through the objective lens of a microscope it undergoes a Fourier transform, resulting in the spatially varying distribution of light we call a hologram.  

The basic operating principle of a reflective _phase only_ SLM is simple. 

![combine_images](https://user-images.githubusercontent.com/81040584/191947510-60a9e911-c752-4e85-867b-5145b28aaafc.jpg)
[ _Left_: The desired pattern of light, _Middle_: the computed phase mask required for pattern generation, _Right_: the resultant 2-dimensional hologram projected into a flourescent slide and captured using a microscope camera. ]
# Basic use
**1.** Acquire a **z-stack** of your tissue of interest and load it using the **_load image_** button. The higher the z-resolution of the image stack, the more precise your holographic targeting will be. I recommend using **2-4 µm spacing**. Do ensure the images have a high _signal-to-noise ratio_ (you will likely need to average many images per plane).  

**2.** Run [Cellpose](https://github.com/MouseLand/cellpose) on the z-stack in order to automatically **extract the 3D mask** of each neuronal cell body in the form of a 'masks.tif' file. This file will be used to compute the _centroid_ of each neuron within the image volume. Load it using the **_load masks_** button.  
**Note:** The mask of each neuron contains pixels that have a value corresponding its ROI number from Cellpose. Please ensure the masks file contains as many images as your z-stack.  
            
<p align="center">
  <img src="https://user-images.githubusercontent.com/81040584/191570971-2d93cfdc-04a0-47f9-8645-fdbd26b1efa8.gif"/>
</p>
<p align="center">
[ The 3D projection of Purkinje cell masks created in Cellpose. ]
</p>

**3.** **Optional:** create a 'zone.tif' file in order to define zones within the **xy** plane.  

**4.** Load all files into **SLMTargets** then remove any undesirable neurons, define the stimulation cluster size, and prefered laser power per cell.  

**5.** To finish click the **_export all_** button. All target positions, phase masks, and microscope control files will be saved to the current SLMTargets directory.


