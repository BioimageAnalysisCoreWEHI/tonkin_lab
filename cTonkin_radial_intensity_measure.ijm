#@ File (label="<HTML><h3>Choose a czi</h3>(Will be ignored if choosing batching)", style="File") ctonkin_fpath
#@ File (label="<HTML><h3>Choose an output path", style="Directory") ctonkin_outpath
#@ Float   (label="Width of \"edge\" (um)", style="slider", min=0.0, max=5.0, value=0.5, stepSize=0.1) edgeWidth
#@ Boolean (label="Get Radial Distribution", value=true) get_radial
#@ Boolean (label="Display graph (if unchecked will just still save csv)", value=true) display_graph 
#@ Boolean (label="Batch", value=false) batching 
#@ Boolean (label="Allow multiple rois", value=false) allow_multiple
#@ Boolean (label="Useless button - do not press", value=false) useless //debug mode*/
#@ Integer (label="Parasite Masking Channel", min=1,max=5, value=1, style="Slider") masking_channel
#@ Integer (label="Measurement Channel", min=1,max=5, value=1, style="Slider") measure_channel
#@ String (label="Mode", choices = {"Classic","Annotate","Analyse"}, style="listBox") what_are_we_doing



var batch_dir = "";
var fiji_dir = getDir("imagej");
var plugin_dir = getDir("plugins");
check_for_required_plugins();

var dir2 = "" + ctonkin_outpath + File.separator();

run("Close All");

if ( what_are_we_doing == "Classic" ) { 
	//Setup custom results table 
	Table_Heading = "Mean Radial Intensity Measures";
	if(!allow_multiple){
		columns = "Filename,Mean Background,Mean Periphery Intensity,Mean Inner Region Intensity,Periphery Area,Inner Area,Max pixel, Distance of Max Pixel to edge";
	}else{
		columns = "Filename,Mean Background,Mean Periphery Intensity,Mean Inner Region Intensity,Periphery Area,Inner Area,Max pixel, Distance of Max Pixel to edge,ROI Number";
	}
	
	columns = split(columns,",");
	table = generateTable(Table_Heading,columns);
	
	if(batching){
		batch_dir = getDirectory("Choose input directory full of .czis");
		flist = getFileList(batch_dir);
		for(i=0;i<flist.length;i++){
			if(endsWith(flist[i],"czi")){
				run("Close All");
				fpath = batch_dir+flist[i];
				if(!allow_multiple){
					res = process_file(fpath);
					fname = File.getName(fpath);
					res = Array.concat(fname,res);
					logResults(table,res);	
					saveTable(Table_Heading);
				}else{
					fname = open_and_project(file_path);
					prompt_user_to_draw_roi();
					nRois = roiManager("Count");
					if(nRois>1){
						roiPath = ctonkin_outpath + File.separator() + "tmp.zip";
					}else{
						roiPath = ctonkin_outpath + File.separator() + "tmp.roi";
					}
					roiManager("Save",roiPath);
					process_multiple_rois(fpath,table,roiPath,fname);				
				}
			}
		}
	}else{
		fpath = ctonkin_fpath;
		if(!allow_multiple){
			res = process_file(fpath);
			fname = File.getName(fpath);
			res = Array.concat(fname,res);
			logResults(table,res);
			saveTable(Table_Heading);
		}else{
			process_multiple_rois(fpath,table);
			
		}		
	}
}

if (what_are_we_doing == "Annotate") {
	print("Doing annotation");
	if(batching){
		batch_dir = getDirectory("Choose input directory full of .czis");
		flist = getFileList(batch_dir);
		for(i=0;i<flist.length;i++){
			if(endsWith(flist[i],"czi")){
				shortfname = File.getNameWithoutExtension(flist[i]);
				if( !File.exists(ctonkin_outpath + File.separator() + shortfname + "rois.zip") && 
				!File.exists(ctonkin_outpath + File.separator() + shortfname + "rois.roi") ){					
					run("Close All");
					file_path = batch_dir+flist[i];
					define_ROIS_for_later(file_path);
				}else{
					print("Already has ROI");
				}	
			}
		}
	}	
}

if (what_are_we_doing == "Analyse") {
	Table_Heading = "Mean Radial Intensity Measures";
	if(!allow_multiple){
		columns = "Filename,Mean Background,Mean Periphery Intensity,Mean Inner Region Intensity,Periphery Area,Inner Area,Max pixel, Distance of Max Pixel to edge";
	}else{
		columns = "Filename,Mean Background,Mean Periphery Intensity,Mean Inner Region Intensity,Periphery Area,Inner Area,Max pixel, Distance of Max Pixel to edge,ROI Number";
	}
	
	columns = split(columns,",");
	table = generateTable(Table_Heading,columns);
	print("Doing analysis with saved ROIs");
	if(batching){
		batch_dir = getDirectory("Choose input directory full of .czis");
		flist = getFileList(batch_dir);
		for(i=0;i<flist.length;i++){
			if(endsWith(flist[i],"czi")){
				shortfname = File.getNameWithoutExtension(flist[i]);
				if( !File.exists(ctonkin_outpath + File.separator() + shortfname + "rois.zip") && 
				!File.exists(ctonkin_outpath + File.separator() + shortfname + "rois.roi") ){					
					print("Aint no ROI file");
				}else{
					if( File.exists(ctonkin_outpath + File.separator() + shortfname + "rois.zip")){
						roiPath = ctonkin_outpath + File.separator() + shortfname + "rois.zip";
					}
					if( File.exists(ctonkin_outpath + File.separator() + shortfname + "rois.roi")){
						roiPath = ctonkin_outpath + File.separator() + shortfname + "rois.roi";
					}
					file_path = batch_dir+flist[i];
					fname = open_and_project(file_path);
					process_multiple_rois(file_path,table,roiPath,fname);							
				}			
			}
		}
	}
}

function define_ROIS_for_later(file_path){	
	fname = open_and_project(file_path);
	prompt_user_to_draw_roi();
	nRois = roiManager("Count");
	shortfname = File.getNameWithoutExtension(file_path);
	print(shortfname);
	if(nRois>1){
		roiManager("Save",ctonkin_outpath + File.separator() + shortfname + "rois.zip");
	}else{
		roiManager("Save",ctonkin_outpath + File.separator() + shortfname + "rois.roi");
	}
	closeRoiManager();
}



function process_multiple_rois(file_path,table,roiPath,fname){
	roiManager("Open",roiPath);
	nRois = roiManager("Count");
	for(roi=0;roi<nRois;roi++){
		if(!isOpen("ROI Manager")){
			roiManager("Open",roiPath);
		}
		
		
		if(!isOpen(fname)){
			fname = open_and_project(file_path);
		}
		
		
		roiManager("Select",roi);
		
		mask = filter_and_get_boundary("MAX_"+fname);
		if(get_radial){
			get_radial_distribution(fname);	
		}
		get_region_mask();
		res = get_intensity_measures_and_brightest_pixel();
		res = Array.concat(fname,res);
		res = Array.concat(res,roi);
		make_mask(fname);
		cleanup(fname);
		run("Z Project...", "projection=[Max Intensity]");
		
		logResults(table,res);
		saveTable(Table_Heading);
		
	}
}


function process_file(file_path){
	fname = open_and_project(file_path);
	prompt_user_to_draw_roi();
	mask = filter_and_get_boundary("MAX_"+fname);
	if(get_radial){
		get_radial_distribution(fname);	
	}
	get_region_mask();
	res = get_intensity_measures_and_brightest_pixel();
	make_mask(fname);
	cleanup(fname);

	return res;	
}

function open_and_project(file_path){
	run("Bio-Formats Importer", "open=["+file_path+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	fname = getTitle();
	run("Z Project...", "projection=[Max Intensity]");
	return fname;
}


function prompt_user_to_draw_roi(){
	closeRoiManager();
	run("ROI Manager...");
	roiManager("Show All without labels");
	if(!useless){
		if(!allow_multiple){
			waitForUser("Draw region around parasite cluster");		
		}else{
			waitForUser("Draw multiple rois.\n\nPress \"t\" after each");
		}
	}else{
		exit("I told you not to click that");
		makeRectangle(560, 834, 214, 232);
	}
}

function filter_and_get_boundary(mip_window_name){
	selectWindow(mip_window_name);
	run("Duplicate...", "duplicate title=roi");
	run("Duplicate...", "duplicate title=mask channels="+masking_channel);
	if(selectionType()!=-1){
		run("Clear Outside");
	}
	run("Median...", "radius=5");
	setAutoThreshold("Default dark no-reset");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Morphological Filters", "operation=Closing element=Disk radius=50");
	run("Morphological Filters", "operation=Dilation element=Disk radius=5");
	mask=getTitle();
	return mask;
}

function get_radial_distribution(fname){
	shortfname = File.getNameWithoutExtension(fname);
	run("3D Distance Map", "map=Both image="+mask+" mask=Same threshold=0");
	selectWindow("roi");
	run("Duplicate...", "duplicate title=signal channels=1");
	run("3D EVF Layers", "step=0.020 evf=EVF signal=signal values=[Average Intensity] save");
	r=0;
	while(File.exists(ctonkin_outpath + File.separator() + shortfname+"_region_"+r+"_radialDistribution.csv")){
		r = r + 1;
	}	
	//move results to a more logical location and clean up
	File.copy(fiji_dir+"nullsignal-EVFLayers-avg.csv",ctonkin_outpath + File.separator() + shortfname+"_region_"+r+"_radialDistribution.csv");
	File.delete(fiji_dir+"nullsignal-EVFLayers-avg.csv");
	File.delete(fiji_dir+"nullsignal-EVFLayers-vol.csv");
	if(!display_graph){	close("Average Intensity");}
	close("Volume of Layers");
}
	

//Do intensity measures between 0 and 0.5 um
function get_region_mask(){
	if(isOpen("EDT")){
		selectWindow("EDT");
	}else{
		run("3D Distance Map", "map=EDT image="+mask+" mask=Same threshold=0");		
	}
	
	run("Duplicate...","title=inside");
	run("Duplicate...","title=background");
	run("Duplicate...","title=outside");
	
	setThreshold(0.001, edgeWidth);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
	
	selectWindow("inside");
	setThreshold(edgeWidth,10000);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
	
	selectImage("background");
	setThreshold(0.00, 0.001);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
	
	run("Image Expression Parser (Macro)", "expression=[A +  (2*B) + (3*C)] a=background-lbl b=outside-lbl c=inside-lbl d=None e=None f=None g=None h=None i=None j=None k=None l=None m=None n=None o=inside-lbl p=background-lbl");
	x = getTitle();
	run("Duplicate...", "title=lbl");
			
	close(x);
	close("inside*");
	close("outside*");
	close("background*");
	
}

function get_intensity_measures_and_brightest_pixel(){
	if(isOpen("signal")){
		print("signal open");
	}else{
		selectWindow("MAX_"+fname);
		run("Duplicate...","duplicate title=signal channels=1");
	}
	run("Intensity Measurements 2D/3D", "input=signal labels=lbl mean stddev max min median mode skewness kurtosis numberofvoxels volume neighborsmean neighborsstddev neighborsmax neighborsmin neighborsmedian neighborsmode neighborsskewness neighborskurtosis");
	
	bgMean = Table.get("Mean",0);
	outsideMean = Table.get("Mean",1);
	insideMean = Table.get("Mean",2);
	
	outsideArea = Table.get("Volume",1);
	insideArea = Table.get("Volume",2);
		
	maxIntArray = newArray(Table.get("Max",1),Table.get("Max",2));
	Array.getStatistics(maxIntArray, min, maxI, mean, stdDev);
	
	
	selectWindow("signal");
	setThreshold(maxI-5,maxI+5);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Connected Components Labeling", "connectivity=4 type=[16 bits]");
	rename("MaxPixel_LBL");
	run("Maximum...", "radius=2");
	
	run("Intensity Measurements 2D/3D", "input=EDT labels=MaxPixel_LBL mean stddev max min median mode skewness kurtosis numberofvoxels volume neighborsmean neighborsstddev neighborsmax neighborsmin neighborsmedian neighborsmode neighborsskewness neighborskurtosis");
	
	distanceFromEdge = Table.get("Mean",0);
	setThreshold(1,2);
	run("Analyze Particles...", "pixel display clear add");
	
	res = newArray(bgMean,outsideMean,insideMean,outsideArea,insideArea,maxI,distanceFromEdge);
	return res;
}	
							
function make_mask(fname){
	shortfname = File.getName(fname);
	selectWindow("roi");
	roiManager("Select", 0);
	selectWindow("lbl");
	setAutoThreshold("Default dark no-reset");
	//run("Threshold...");
	setThreshold(1.5,2.5);
	run("Convert to Mask");
	
	selectWindow("roi");
	run("Add Image...", "image=lbl x=0 y=0 opacity=50 zero");
	run("RGB Color");
	run("Flatten");
	roiManager("Show All without labels");
	run("Flatten");
	rename("thisone");
	
	
	selectWindow("roi");
	run("Select None");
	run("Duplicate...", "duplicate title=signal-1 channels=1");
	run("RGB Color");
	run("Concatenate...", "open image1=thisone image2=signal-1 image3=[-- None --]");
	run("Make Montage...", "columns=2 rows=1 scale=1");
	
//save mask
	r=0;
	while(File.exists(ctonkin_outpath + File.separator() + shortfname+"_region_"+r+"_mask.jpg")){
		r = r + 1;
	}	
	saveAs("JPG",ctonkin_outpath + File.separator() + shortfname+"_region_"+r+"_mask.jpg");	
}

function check_for_required_plugins(){
	if(File.exists(plugin_dir + "mcib3d-suite")){
		print("3d suite exists");
	}else{
		exit("Needs 3d-suite installed");
	}
	
	if(File.exists(plugin_dir + "MorphoLibJ_-1.6.0.jar")){
		print("MorpholibJ exists");
	}else{
		exit("Needs morpholibJ, \n\nPlease install IJPB_Plugins update site");
	}	
}

function cleanup(fname){
	windows = getList("image.titles");
	for(i=0;i<windows.length;i++){
		if ( windows[i] != fname ){
			close(windows[i]);
		}
	}
	
	/*
	
	
	close(fname);
	close("MAX_"+fname);
	close("Max*");
	close("Untitled");
	close("roi");
	close("signal");
	close("mask*");
	close("E*");
	close("lbl");
	close("roi*");
	*/
	//close("Log");
	close("ROI Manager");
	close("signal-intensity-measurements");
	close("EDT-intensity-measurements");
}



//Generate a custom table
//Give it a title and an array of headings
//Returns the name required by the logResults function
function generateTable(tableName,column_headings){
	if(isOpen(tableName)){
		selectWindow(tableName);
		run("Close");
	}
	tableTitle=tableName;
	tableTitle2="["+tableTitle+"]";
	run("Table...","name="+tableTitle2+" width=600 height=250");
	newstring = "\\Headings:"+column_headings[0];
	for(i=1;i<column_headings.length;i++){
			newstring = newstring +" \t " + column_headings[i];
	}
	print(tableTitle2,newstring);
	return tableTitle2;
}


//Log the results into the custom table
//Takes the output table name from the generateTable funciton and an array of resuts
//No checking is done to make sure the right number of columns etc. Do that yourself
function logResults(tablename,results_array){
	resultString = results_array[0]; //First column
	//Build the rest of the columns
	for(i=1;i<results_array.length;i++){
		resultString = toString(resultString + " \t " + results_array[i]);
	}
	//Populate table
	print(tablename,resultString);	
}



function saveTable(temp_tablename){
	selectWindow(temp_tablename);
	saveAs("Results",dir2+temp_tablename+".csv");
}

function closeRoiManager(){
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
	}
}
