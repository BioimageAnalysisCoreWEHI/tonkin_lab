# tonkin_lab
Code for Tonkin Lab data

# cTonkin_montageMaker.ijm
## Create a consistent montage from multi-channel data.
### Options
 - File to montage
 - Output path to save montage to
 - Ch1-5 colours, false colour for each channel
 - ROI Size - Side length of roi to montage
 - Add scale bar
 - Length of scale bar

# cTonkin_radial_intensity_measure.ijm
## Measre mean radial intensity of cells 
### Options
 - Input file (ignored if batch is selected)
 - Output path - where to put results
 - Width of "edge" - how many micron to step output edge in from edge of detected region
 - Get radial distribution - measure (and save) actual intensity distribution normalised from edge to centre
 - Display graph - show radial distribution on screen
 - Batch - Batch a directory instead of an individual file, will prompt for directory
 - Allow multiple rois
#### Mode: 
    - Classic - will do the above
    - Annotate - Will open each image and allow annotation, will skip file if there's already an annotation
    - Analyse - Will open each image that has an associated annotation and perform analysis
#### Note for both analyse and annotate you need to specify the correct output path above which is where the annotations are stored. 
    
   
