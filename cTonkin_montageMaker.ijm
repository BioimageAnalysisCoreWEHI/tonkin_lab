#@ File (label="choose file", style=file) tonkin_panel_fpath
#@ File (label="Output Path", style=directory) tonkin_panel_outpath
#@ String (label="Ch1 colour for merge", choices={"Red","Green","Blue","Cyan","Yellow","Magenta","Grays"}, value="Green") ch1_colour
#@ String (label="Ch2 colour for merge", choices={"Red","Green","Blue","Cyan","Yellow","Magenta","Grays"}, value="Red") ch2_colour
#@ String (label="Ch3 colour for merge", choices={"Red","Green","Blue","Cyan","Yellow","Magenta","Grays"}, value="Cyan") ch3_colour
#@ String (label="Ch4 colour for merge", choices={"Red","Green","Blue","Cyan","Yellow","Magenta","Grays"}, value="Magenta") ch4_colour
#@ String (label="Ch5 colour for merge", choices={"Red","Green","Blue","Cyan","Yellow","Magenta","Grays"}, value="Yellow") ch5_colour
#@ Integer (label="ROI Size", value=256) roi_sidelength
#@ Boolean (label="Add scale bar", value=true) scale_bar
#@ Integer (label="Scale bar Length (um)", value=5) sb_width
#@ Boolean (label="Placebo button", value=false) placebo



dir2 = tonkin_panel_outpath + File.separator();
var how_many_channels = 1;

run("Close All");
close("ROI Manager");

run("Bio-Formats Importer", "open=["+tonkin_panel_fpath+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

getDimensions(width, height, how_many_channels, slices, frames);

run("Z Project...", "projection=[Max Intensity]");
fname = getTitle();
setTool("Multipoint");
waitForUser("Click all the things");
getPixelSize(unit, pixelWidth, pixelHeight);

run("Clear Results");
run("Measure");

for(n=0;n<nResults();n++){
	xpos = getResult("X",n) / pixelWidth;
	ypos = getResult("Y",n) / pixelWidth;
	makeRectangle(xpos - roi_sidelength/2, ypos-roi_sidelength/2, roi_sidelength, roi_sidelength);
	roiManager("add");
	roiManager("Show All without labels");	
}


for(r=0;r<roiManager("Count");r++){
	selectWindow(fname);
	roiManager("Select",r);
	run("Duplicate...","title=working duplicate");
	make_montage("working");
	selectWindow("Montage");
	saveAs("PNG",dir2 + fname + "_roi"+r+".png");
	selectWindow(fname);
	close("\\Others");
}


function make_montage(window_name){
	setForegroundColor(255,255,255);
	selectWindow(window_name);
	Stack.setChannel(1);run(ch1_colour);
	Stack.setChannel(2);run(ch2_colour);
	Stack.setChannel(3);run(ch3_colour);
	if(how_many_channels > 3){
		Stack.setChannel(4);run(ch4_colour);
	}
	if(how_many_channels > 4){
		Stack.setChannel(5);run(ch5_colour);
	}
	
	run("RGB Color");
	if (scale_bar) {
		run("Scale Bar...", "width="+sb_width+" height=5 thickness=10 bold hide");
	}
	
	
	selectWindow(window_name);
	run("Split Channels");
	for(c=1;c<=how_many_channels;c++){
		selectWindow("C"+c+"-"+window_name);run("Grays");run("RGB Color");
	}
	
	if(how_many_channels == 3){
		run("Concatenate...", "open image1=C1-working image2=C2-working image3=C3-working image4=[working (RGB)] image5=[-- None --]");
		run("Make Montage...", "columns=4 rows=1 scale=1 border=10 use");
	}
	if(how_many_channels == 4){
		run("Concatenate...", "open image1=C1-working image2=C2-working image3=C3-working image4=C4-working image5=[working (RGB)] image6=[-- None --]");
		run("Make Montage...", "columns=5 rows=1 scale=1 border=10 use");
	}
	if(how_many_channels == 5){
		run("Concatenate...", "open image1=C1-working image2=C2-working image3=C3-working image4=C4-working image5=C5-working image6=[working (RGB)] image6=[-- None --]");
		run("Make Montage...", "columns=6 rows=1 scale=1 border=10 use");
	}
	
	
	
}
