# SLMTargets
**SLMTargets** is a MATLAB-based GUI for running 3D _holographic_ photostimulation experiments on abitrary sets of neurons.

![SLMTargets](https://user-images.githubusercontent.com/81040584/191542064-5f83f272-53fc-4393-b11a-1dc8494e90d4.gif)  
Pictured above is z-stack of the cerebellum showing Purkinje cells labeled with GCaMP8s.  (User-defined zones and neural clusters are colored uniquely)

# Basic use
1. Acquire a z-stack of your tissue of interest
2. Run [cellpose](https://github.com/MouseLand/cellpose) on the z-stack in order to extract the position of each neuron in the form of a 'masks file'
3. Optional: define zone boundaries with a 'zone file'
4. Load all files into SLMTargets then define cluster size, desired laser power per cell, manually included neurons
