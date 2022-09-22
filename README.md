# SLMTargets
**SLMTargets** is a MATLAB-based GUI for running 3D _holographic_ photostimulation experiments on arbitrary sets of neurons. Its output is compromised of  phase masks used for creating custom holograms with a liquid crystal [spatial light modulator](https://en.wikipedia.org/wiki/Spatial_light_modulator) (SLM) and _optional_ [Bruker](https://www.bruker.com/en/products-and-solutions/mr.html?gclid=Cj0KCQjwj7CZBhDHARIsAPPWv3dGf_KSiU_riwNS8jdjhhcRLIdNeDB6sLp11rB1zRIoYhl91VFGrkQaAqXSEALw_wcB) microscope control files containing galvo positioning instructions and photostimulation sequencing instructions.

![SLMTargets](https://user-images.githubusercontent.com/81040584/191542064-5f83f272-53fc-4393-b11a-1dc8494e90d4.gif)  
[ Pictured above is the main interface of **SLMTargets** displaying a two-photon z-stack of lobule Crus I of the cerebellum. Cre-expressing Purkinje cells were labeled virally with the _state-of-the-art_ calcium indicator [GCaMP8s](https://www.janelia.org/jgcamp8-calcium-indicators). User-defined zones and neural clusters targeted for stimulation are colored uniquely. ]
# Background: modulating light in space
![GitHub_targets_altered330x330](https://user-images.githubusercontent.com/81040584/191792073-db272860-1b16-4981-a57e-f8cebe329c62.jpg) ![GitHub_phasemask330x330](https://user-images.githubusercontent.com/81040584/191792586-14e15657-e8a8-4ea7-82f9-49685ef261e7.jpg) ![Hologram330x330](https://user-images.githubusercontent.com/81040584/191792614-04f39d4c-0ca3-4fa2-bd00-23b8c19f21c5.jpg)  
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


