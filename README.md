# Using Machine Learning to quantify the strength of weathering at carbonate rock landscapes

## Dataset

![Extent of karstified areas over Europe](./images/map_of_europe.png)

## Format of the bordering tiles dataset:

    - A subset of tiles that include non-karstified areas as well as karstified areas was created
    - Data was stored in a compressed .npz file (4.6 GB) containing 144000 images, 
		115.200 images for training and 28.800 images for testing.
    - The Data was stored in 4 seperate arrays containing testing and training input and output 
		(x_train/x_test for input and y_train/y_test for output)
    - Input data contains a 3D array with elevation, slope and surface roughness
    - output data contains a 3D binary array with replicated channels
	
## References

### CNN Architecture

Badrinarayanan, Vijay; Kendall, Alex; Cipolla, Roberto (2015): SegNet: A Deep Convolutional Encoder-Decoder Architecture for Image Segmentation.
http://arxiv.org/pdf/1511.00561v3.

### Data sources

Chen, Zhao; Auler, Augusto S.; Bakalowicz, Michel; Drew, David; Griger, Franziska; Hartmann, Jens et al. (2017): The World Karst Aquifer Mapping project: concept, mapping procedure and map of Europe. 
In: Hydrogeol J 25 (3), S. 771–785. DOI: 10.1007/s10040-016-1519-3.

Shuttle Radar Topography Mission (2000): Resampled SRTM data, spatial resolution approximately 250 meter on the line of the equator: NASA. 
http://srtm.csi.cgiar.org/srtmdata/.