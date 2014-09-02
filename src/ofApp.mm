/*
 *  app.mm
 *  part of app
 *
 *  Created by Parag K Mital on 11/12/10.
 app
 LICENCE
 
 app "The Software" © Parag K Mital, parag@pkmital.com
 
 The Software is and remains the property of Parag K Mital
 ("pkmital"). The Licensee will ensure that the Copyright Notice set
 out above appears prominently wherever the Software is used.
 
 The Software is distributed under this Licence:
 
 - on a non-exclusive basis,
 
 - solely for non-commercial use in the hope that it will be useful,
 
 - "AS-IS" and in order for the benefit of its educational and research
 purposes, pkmital makes clear that no condition is made or to be
 implied, nor is any representation or warranty given or to be
 implied, as to (i) the quality, accuracy or reliability of the
 Software; (ii) the suitability of the Software for any particular
 use or for use under any specific conditions; and (iii) whether use
 of the Software will infringe third-party rights.
 
 pkmital disclaims:
 
 - all responsibility for the use which is made of the Software; and
 
 - any liability for the outcomes arising from using the Software.
 
 The Licensee may make public, results or data obtained from, dependent
 on or arising out of the use of the Software provided that any such
 publication includes a prominent statement identifying the Software as
 the source of the results or the data, including the Copyright Notice
 and stating that the Software has been made available for use by the
 Licensee under licence from pkmital and the Licensee provides a copy of
 any such publication to pkmital.
 
 The Licensee agrees to indemnify pkmital and hold them
 harmless from and against any and all claims, damages and liabilities
 asserted by third parties (including claims for negligence) which
 arise directly or indirectly from the use of the Software or any
 derivative of it or the sale of any products based on the
 Software. The Licensee undertakes to make no liability claim against
 any employee, student, agent or appointee of pkmital, in connection
 with this Licence or the Software.
 
 
 No part of the Software may be reproduced, modified, transmitted or
 transferred in any form or by any means, electronic or mechanical,
 without the express permission of pkmital. pkmital's permission is not
 required if the said reproduction, modification, transmission or
 transference is done without financial return, the conditions of this
 Licence are imposed upon the receiver of the product, and all original
 and amended source code is included in any transmitted product. You
 may be held legally responsible for any copyright infringement that is
 caused or encouraged by your failure to abide by these terms and
 conditions.
 
 You are not permitted under this Licence to use this Software
 commercially. Use for which any financial return is received shall be
 defined as commercial use, and includes (1) integration of all or part
 of the source code or the Software into a product for sale or license
 by or on behalf of Licensee to third parties or (2) use of the
 Software or any derivative of it for research with the final aim of
 developing software products for sale or license to a third party or
 (3) use of the Software or any derivative of it for research with the
 final aim of developing non-software products for sale or license to a
 third party, or (4) use of the Software to provide any service to an
 external organisation for which payment is received. If you are
 interested in using the Software commercially, please contact pkmital to
 negotiate a licence. Contact details are: parag@pkmital.com
 
 
 
 * try different features such as pitch, loudness, and spectral flux
 * UI feedback for touchdown events, only act on up
 
 *
 */

#import <mach/mach.h>
#import <mach/mach_host.h>
#include "pkmAudioWindow.h"
#include "ofApp.h"

int button1_x = 50;
int button1_y = 250;
int button2_x = 190;
int button2_y = 250;
int button3_x = 330;
int button3_y = 250;
int button_width = 110;
int button_height = 57;

const int checkbox1_x = 60;
const int checkbox1_y = 75;
const int checkbox_size = 25;
bool checkbox1 = true;

int slider0_x = 60;
int slider0_y = 105;
int slider1_x = 60;
int slider1_y = 1045;
int slider2_x = 60;
int slider2_y = 185;

int slider_width = 360;

float slider0_position = 0;
float slider1_position = 0;
float slider2_position = 0;

const int animationtime = 300;
const int segmentationtime = 0;

const float MAX_GRAIN_LENGTH = 5.0;

int SCREEN_WIDTH = 320;
int SCREEN_HEIGHT = 480;

float height_ratio = 1.0;

const float maxVoices = 8;

#import "mach/mach.h"



vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

vm_size_t freeMemory(void) {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}

void logMemUsage(void) {
    // compute memory usage and log if different by >= 100k
    static long prevMemUsage = 0;
    long curMemUsage = usedMemory();
    long memUsageDiff = curMemUsage - prevMemUsage;
    
    if (memUsageDiff > 100000 || memUsageDiff < -100000) {
        prevMemUsage = curMemUsage;
        NSLog(@"Memory used %7.1f (%+5.0f), free %7.1f kb", curMemUsage/1000.0f, memUsageDiff/1000.0f, freeMemory()/1000.0f);
    }
}

app::~app()
{
#ifdef DO_RECORD
	audioOutputFileWriter.close();
	audioInputFileWriter.close();
#endif
	audioFileWriter.close();
    songReader.close();
#ifdef TARGET_OF_IPHONE
    fclose(fp);
#endif
	
	free(output);
	free(buffer);
	free(output_mono);
	free(current_frame);
    free(itunes_frame);
#ifndef DO_FILEINPUT
    audioDatabaseNormalizer->saveNormalization();
#endif
    
}

//--------------------------------------------------------------
void app::setup()
{
    SCREEN_WIDTH = ofGetHeight();
    SCREEN_HEIGHT = ofGetWidth();
    
    height_ratio = SCREEN_HEIGHT / (320.0f);
    
    slider0_x = SCREEN_WIDTH * 0.1;         slider0_y *= height_ratio;
    slider1_x = SCREEN_WIDTH * 0.1;         slider1_y *= height_ratio;
    slider2_x = SCREEN_WIDTH * 0.1;         slider2_y *= height_ratio;
    slider_width = SCREEN_WIDTH * 0.8;
    
    button_width = SCREEN_WIDTH * 0.25;     //button_height *= height_ratio;
    button1_x = SCREEN_WIDTH * 0.1;         button1_y *= height_ratio;
    button2_x = SCREEN_WIDTH * 0.375;       button2_y *= height_ratio;
    button3_x = SCREEN_WIDTH * 0.65;        button3_y *= height_ratio;
    
    cout << "w: " << SCREEN_WIDTH << " h: " << SCREEN_HEIGHT << endl;
    
	ofSetOrientation(OF_ORIENTATION_90_RIGHT);
    
    bDrawNeedsUpdate = true;
    bOutOfMemory = false;
    bLearning = true;              // memory mosaicing
	bSetup = false;
    bRealTime = true;
    bSemaphore = false;
    bCopiedBackground = false;
    bSyncopated = false;
	bPressed = false;
	bProcessingSong = false;
    bLearningInputForNormalization = true;
    bWaitingForUserToPickSong = bConvertingSong = bLoadedSong = false;
    bDetectedOnset = false;
    bInteractiveMode = false;
    bDrawHelp = 1;
    
    sampleRate = 44100;
    frameSize = 512;
    fftSize = 8192;
    frame = 0;
    currentFile = 0;
    inputSegmentsCounter = 0;
    
    bMovingSlider0 = bMovingSlider1 = bMovingSlider2 = false;
    
    buttonScreenSliders.loadImage("speckles.png");
    buttonScreenInteraction.loadImage("sliders.png");
    buttonInfo.loadImage("info.png");
    
    // setup envelopes
    pkmAudioWindow::initializeWindow(frameSize);
    
#ifdef TARGET_OF_IPHONE
    documentsDirectory = ofxiPhoneGetDocumentsDirectory();
	// delete previous files
    NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error = nil;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error]) {
        [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:file] error:&error];
    }
    
    // add a folder called audio
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/audio"];
    
    // Create folder
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
    
	// -------------- INITIALIZE DEBUG OUTPUT -----------
	// Setup file output for debug logging:
    char buf[256];
	sprintf(buf, "log_%2d%2d%4d_%2dh%2dm%2ds.log", ofGetDay(), ofGetMonth(), ofGetYear(),
			ofGetHours(), ofGetMinutes(), ofGetSeconds());
	NSString * filename = [[NSString alloc] initWithCString: buf];
	
	// redirects NSLog to a console.log file in the documents directory.
	NSString *logPath = [documentsDirectory stringByAppendingPathComponent:filename];
	fp = freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
	
	// initialize picker for itunes library
	itunesStream.allocate(sampleRate, frameSize, 1);
	
	
	// register touch events
	//ofRegisterTouchEvents(this);
	
	// iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
	
    myFBO.allocate(SCREEN_WIDTH, SCREEN_HEIGHT);
#else
	ofSetWindowShape(480, 320);
    myFBO.allocate(480, 320);
	ofSetFullscreen(false);
#endif
    
    ofxiOSGetOFWindow()->disableOrientationAnimation();
    ofxiOSGetOFWindow()->disableHardwareOrientation();
	ofxiOSGetOFWindow()->enableAntiAliasing(8);
    ofxiOSGetOFWindow()->enableRetina();
    
	// black
	ofBackground(0,0,0);
    ofSetFrameRate(30);
	
    smallBoldFont.loadFont("Dekar.ttf", 18, true);
    largeBoldFont.loadFont("Dekar.ttf", 36, true);
//    largeThinFont.loadFont("DekarLight.ttf", 36, true);
//    smallThinFont.loadFont("DekarLight.ttf", 16, true);
//    infoFont.loadFont("aller-light.ttf", 12, true, false);
    infoFont.loadFont("DekarLight.ttf", 14, true, false);
	
    background.loadImage("bg.png");
    
    button.loadImage("button.png");
    
    ringBuffer = new pkmCircularRecorder(fftSize, frameSize);
    alignedFrame = (float *)malloc(sizeof(float) * fftSize);
    
    zeroFrame = (float *)malloc(sizeof(float) * frameSize);
    memset(zeroFrame, 0, sizeof(float) * frameSize);
    
    current_frame = (float *)malloc(sizeof(float) * frameSize);
    itunes_frame = (float *)malloc(sizeof(float) * frameSize);
    buffer = (float *)malloc(sizeof(float) * frameSize);
    output = (float *)malloc(sizeof(float) * frameSize);
    output_mono = (float *)malloc(sizeof(float) * frameSize);
	
	// does onset detection for matching
    slider1_position = 0.05;
    spectralFlux = new pkmAudioSpectralFlux(frameSize, fftSize, sampleRate);
    spectralFlux->setOnsetThreshold(0.25);
    spectralFlux->setIIRAlpha(0.01);
	spectralFlux->setMinSegmentLength(MAX_GRAIN_LENGTH * sampleRate / frameSize * slider1_position);
    
	audioDatabase = new pkmAudioSegmentDatabase();
    int k = 3;
	audioDatabase->setK(k);
    audioDatabase->setMaxObjects(500);
	slider2_position = (k - 1)/(maxVoices - 1);
	
    audioFeature = new pkmAudioFeatures(sampleRate, fftSize);
//    dct.setup(fftSize);
    
    numFeatures = 24;
    featureFrame = pkm::Mat(1, numFeatures);
    
    audioDatabaseNormalizer = new pkmAudioFeatureNormalizer(numFeatures);
    currentNumFeatures = 0;
    
#ifndef DO_FILEINPUT
    audioDatabaseNormalizer->loadNormalization();
#endif
    
#ifdef DO_PLCA_SEPARATION
    // PLCA SETUP
    bLearnedPLCABackground  = false;
	
	foregroundComponents	= 5;
	backgroundComponents	= 5;
	foregroundIterations	= 100;
	backgroundIterations	= 100;
    
    plca = new pkmPLCA(fftSize, foregroundComponents, backgroundComponents, 1);
    //    plca->setHSparsity(0.2);
    //    plca->setWSparsity(0);
#endif
    
    foreground_features  = (float *)malloc(sizeof(float)*numFeatures);
    currentSegment = pkm::Mat(SAMPLE_RATE / frameSize * 5, frameSize, true);
    currentSegmentFeatures = pkm::Mat(SAMPLE_RATE / frameSize * 5, numFeatures, true);
    
    currentITunesSegment = pkm::Mat(SAMPLE_RATE / frameSize * 5, frameSize, true);
    currentITunesSegmentFeatures = pkm::Mat(SAMPLE_RATE / frameSize * 5, numFeatures, true);
    
	animationCounter = 0;
    segmentationCounter = segmentationtime;
	
    maxiSettings::setup(sampleRate, 1, frameSize);
    inputFollower.setAttack(20);
    inputFollower.setRelease(800);
    
    ifstream f;
	f.open(ofToDataPath("audio_database.mat").c_str());
	bMatching = f.is_open();
    f.close();
    
    if (!bMatching) {
        printf("Building database\n");
        setupBuilding();
    }
    
#ifdef DO_RECORD
#ifdef TARGET_OF_IPHONE
	string strDocumentsDirectory = ofxNSStringToString(documentsDirectory);
#else
	string strDocumentsDirectory = ofToDataPath("", true);
#endif
    
	string strFilename;
	stringstream str,str2;
	
	// setup output
	str << strDocumentsDirectory << "/" << "output_" << ofGetDay() << ofGetMonth() << ofGetYear()
	<< "_" << ofGetHours() << "_" << ofGetMinutes() << "_" << ofGetSeconds() << ".wav";
	strFilename = str.str();
	output_frame = 0;
	audioOutputFileWriter.open(strFilename, frameSize);
	
	// setup input
	str2 << strDocumentsDirectory << "/" << "input_" << ofGetDay() << ofGetMonth() << ofGetYear()
	<< "_" << ofGetHours() << "_" << ofGetMinutes() << "_" << ofGetSeconds() << ".wav";
	strFilename = str2.str();
	audioInputFileWriter.open(strFilename, frameSize);
#endif
    
//    setupMatching();
    
    
	ofEnableAlphaBlending();
	ofSetBackgroundAuto(false);
    ofBackground(0);
    
#ifdef DO_FILEINPUT
    
#else
    bLearningInputForNormalization = true;
    //	ofSetFrameRate(25);
	ofSoundStreamSetup(2, 1, this, sampleRate, frameSize, 1);
#endif
    
    bSetup = true;
}

void app::setupBuilding()
{
    // get the file names of every audio file
    
    string audio_dir = ofToDataPath("audio");
#ifdef TARGET_OF_IPHONE
    audio_dir = ofxiPhoneGetDocumentsDirectory() + string("audio");
#endif
    dirList.open(audio_dir.c_str());
    numFiles = dirList.listDir();
    if(numFiles == 0)
    {
        printf("[ERROR] No files found in %s\n", audio_dir.c_str());
        //        OF_EXIT_APP(0);
    }
    else {
        printf("[OK] Read %d files\n", numFiles);
    }
    audioFiles = dirList.getFiles();
    
    // process input files to segments
    for(vector<ofFile>::iterator it = audioFiles.begin(); it != audioFiles.end(); it++)
    {
        bLearnedPLCABackground = false;
        songReader.open(it->getAbsolutePath());
        long frame = 0;
        while(frame * frameSize < songReader.mNumSamples && !bOutOfMemory)
        {
            if(songReader.read(current_frame, frame*frameSize, frameSize))
            {
                // get audio features
//                audioFeature->compute36DimAudioFeaturesF(current_frame, foreground_features);
                audioFeature->computeLFCCF(current_frame, foreground_features, numFeatures);
                
                // check for onset
                bDetectedOnset = spectralFlux->detectOnset(audioFeature->getMagnitudes(), audioFeature->getMagnitudesLength());
                
                // do mosaicing
                processInputFrame();
                
                frame++;
            }
            else {
                printf("[ERROR]: Could not read audio file!\n");
            }
        }
        songReader.close();
        
        /*
         // end of file, let's normalize the features
         currentNumFeatures = audioDatabase->featureDatabase.rows;
         if (currentNumFeatures > lastNumFeatures) {
         pkm::Mat thisDatabase = audioDatabase->featureDatabase.rowRange(lastNumFeatures, currentNumFeatures, false);
         printf("Normalizing database of features for %s: \n", it->getFileName().c_str());
         thisDatabase.print();
         pkmAudioFeatureNormalizer::normalizeDatabase(thisDatabase);
         }
         lastNumFeatures = currentNumFeatures;
         */
    }
    
    //pkmAudioFeatureNormalizer::normalizeDatabase(audioDatabase->featureDatabase);
    //audioDatabase->buildIndex();
    //audioDatabase->save();
    //audioDatabase->saveIndex();
}

void app::setupMatching()
{
    
#ifdef DO_FILEINPUT
    
    // load up target
    printf("Matching target.wav\n");
    string inputFileName;
    if (inputAudioFileReader.open(ofToDataPath("target.wav")))
    {
        printf("[OK] Opened target.wav with %lu samples\n", inputAudioFileReader.mNumSamples);
    }
    else {
        printf("Failed to open target.wav, prompting user for target file.\n");
        if(ofxFileDialogOSX::openFile(inputFileName))
        {
            if(!inputAudioFileReader.open(inputFileName))
            {
                printf("Failed to open %s ... exiting.\n", inputFileName.c_str());
                OF_EXIT_APP(0);
            }
        }
        else
        {
            printf("Failed to open %s ... exiting.\n", inputFileName.c_str());
            OF_EXIT_APP(0);
        }
    }
    inputAudioFileFrame = 0;
    
    /*
     // calculate normalization of target
     
     while(inputAudioFileFrame*frameSize < inputAudioFileReader.mNumSamples)
     {
     //printf("inputAudioFileFrame: %ld\n", inputAudioFileFrame);
     inputAudioFileReader.read(current_frame, inputAudioFileFrame*frameSize, frameSize);
     inputAudioFileFrame++;
     //ringBuffer->insertFrame(current_frame);
     //if (ringBuffer->bRecorded) {
     //ringBuffer->copyAlignedData(alignedFrame);
     #ifdef DO_MEAN_MEL_FEATURE
     audioFeature->computeLFCCF(current_frame, foreground_features, numFeatures);
     #else
     audioFeature->computeLFCCF(current_frame, foreground_features, numFeatures);
     #endif
     
     bool isFeatureNan = false;
     for (int i = 0; i < numFeatures; i++) {
     isFeatureNan = isFeatureNan | isnan(foreground_features[i]) | (fabs(foreground_features[i]) > 20);
     }
     
     if (!isFeatureNan) {
     //printf(".");
     audioDatabaseNormalizer->addExample(foreground_features, numFeatures);
     }
     //}
     }
     audioDatabaseNormalizer->calculateNormalization();
     */
    
    audioOutput = pkm::Mat(inputAudioFileFrame, frameSize);
    
    inputAudioFileFrame = 0;
#endif
    
    //audioDatabase->load();
    //audioDatabase->loadIndex();
}

//--------------------------------------------------------------
void app::update()
{
#ifdef DO_FILEINPUT
    
    while(inputAudioFileFrame*frameSize < inputAudioFileReader.mNumSamples)
    {
        inputAudioFileReader.read(current_frame, inputAudioFileFrame*frameSize, frameSize);
        
        if (bLearning) {
            processInputFrame(current_frame, frameSize);
        }
        
        audioRequested(current_frame, frameSize, 1);
        
        inputAudioFileFrame++;
    }
    
    /*
     // compress result
     for (long i = 0; i < inputAudioFileFrame; i++) {
     for (int j = 0; j < frameSize; j++) {
     audioOutput.data[i*frameSize + j] = compressor.compressor(audioOutput.data[i*frameSize + j], 0.5);
     }
     // and save
     #ifdef DO_RECORD
     audioOutputFileWriter.write(audioOutput.row(i), i*frameSize, frameSize);
     #endif
     }
     */
    
    printf("[OK] Finished processing file.  Exiting.\n");
    OF_EXIT_APP(0);
#endif
    
#ifdef TARGET_OF_IPHONE
    if (bWaitingForUserToPickSong && itunesStream.isSelected())
    {
        bWaitingForUserToPickSong = false;
        bProcessingSong = false;
        bConvertingSong = true;
        itunesStream.setStreaming();
        printf("[OK]\n");
        bDrawNeedsUpdate = true;
        printf("Loaded user selected song!\n");
    }
    else if(bWaitingForUserToPickSong && itunesStream.didCancel())
    {
        bWaitingForUserToPickSong = false;
        printf("[OK]\n");
        bDrawNeedsUpdate = true;
        printf("User canceled!\n");
        
    }
    else if(bConvertingSong && itunesStream.isPrepared())
    {
        bConvertingSong = false;
        itunesFrame = 1;
        bProcessingSong = true;
        bDrawNeedsUpdate = true;
    }
#endif
    
    //cout << "size: " << audioDatabase->getSize() << endl;
}

// scrub memory using a cataRT display
// 2 dimensions... pca reprojection of the mfccs? kd-tree?

void app::drawInfo()
{
    
    ofSetColor(255, 255, 255, (float)(animationtime-animationCounter)/(animationtime/2.0f)*255.0f);
    smallBoldFont.drawString("this app resynthesizes your sonic world", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("this app resynthesizes your sonic world") / 2.0, 115);
    smallBoldFont.drawString("using the sound from your microphone and", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("using the sound from your microphone and") / 2.0, 145);
    smallBoldFont.drawString("songs you teach it from your iTunes Library", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("songs you teach it from your iTunes Library") / 2.0, 175);
    
    smallBoldFont.drawString("be sure to wear headphones", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("be sure to wear headphones") / 2.0, 215);
    smallBoldFont.drawString("unless you like feedback", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("unless you like feedback") / 2.0, 245);
    
}


void app::drawCheckboxes()
{
	ofNoFill();
    ofSetColor(180, 140, 140);
	
	smallBoldFont.drawString("syncopation", checkbox1_x, checkbox1_y + 45);
	
    ofSetColor(180, 180, 180);
	ofRect(checkbox1_x, checkbox1_y, checkbox_size, checkbox_size);
	if (checkbox1) {
		ofLine(checkbox1_x, checkbox1_y, checkbox1_x+25, checkbox1_y+25);
		ofLine(checkbox1_x+25, checkbox1_y, checkbox1_x, checkbox1_y+25);
	}
}

void app::drawSliders()
{
	ofNoFill();
	ofSetColor(180, 140, 140);
    
    smallBoldFont.drawString("synthesis", slider0_x, slider0_y + 25);
    if(!bProcessingSong)
        smallBoldFont.drawString("microphone", slider0_x + slider_width - smallBoldFont.stringWidth("microphone"), slider0_y + 25);
    else
        smallBoldFont.drawString("iTunes", slider0_x + slider_width - smallBoldFont.stringWidth("iTunes"), slider0_y + 25);
    
    smallBoldFont.drawString("0.0", slider1_x, slider1_y + 25);
    smallBoldFont.drawString(ofToString(MAX_GRAIN_LENGTH, 1), slider1_x + slider_width - smallBoldFont.stringWidth("1.0"), slider1_y + 25);
	
    smallBoldFont.drawString("1", slider2_x, slider2_y + 25);
    smallBoldFont.drawString(ofToString(maxVoices), slider2_x + slider_width - smallBoldFont.stringWidth(ofToString(maxVoices)), slider2_y + 25);
	
    ofFill();
    ofSetColor(255, 255, 255);
    
    smallBoldFont.drawString("mix", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("mix") / 2.0, slider0_y + 25);
    smallBoldFont.drawString("grain size (s)", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("grain size (s)") / 2.0, slider1_y + 25);
    smallBoldFont.drawString("number of voices", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("number of voices") / 2.0, slider2_y + 25);
    
    button.draw(slider0_position*slider_width + slider0_x - 10, slider0_y - 10, 20, 20);
    button.draw(slider1_position*slider_width + slider1_x - 10, slider1_y - 10, 20, 20);
    button.draw(slider2_position*slider_width + slider2_x - 10, slider2_y - 10, 20, 20);
    
	ofLine(slider0_x, slider0_y, slider0_x + slider_width, slider0_y);
    ofLine(slider1_x, slider1_y, slider1_x + slider_width, slider1_y);
    ofLine(slider2_x, slider2_y, slider2_x + slider_width, slider2_y);
}

void app::drawButtons()
{
	ofNoFill();
    ofSetColor(180, 140, 140);
    smallBoldFont.drawString("erase my", button1_x + (button_width - smallBoldFont.stringWidth("erase my")) / 2.0, button1_y + 0.45 * button_height);
    smallBoldFont.drawString("memory", button1_x + (button_width - smallBoldFont.stringWidth("memory")) / 2.0, button1_y + 0.75 * button_height);
    
    if(bProcessingSong)
    {
        smallBoldFont.drawString("stop", button2_x + (button_width - smallBoldFont.stringWidth("stop")) / 2.0, button2_y + 0.45 * button_height);
        smallBoldFont.drawString("processing", button2_x + (button_width - smallBoldFont.stringWidth("processing")) / 2.0, button2_y + 0.75 * button_height);
    }
    else
    {
        smallBoldFont.drawString("use", button2_x + (button_width - smallBoldFont.stringWidth("use")) / 2.0, button2_y + 0.45 * button_height);
        smallBoldFont.drawString("iTunes", button2_x + (button_width - smallBoldFont.stringWidth("a song")) / 2.0, button2_y + 0.75 * button_height);
    }
    
    if (bLearning) {
        smallBoldFont.drawString("stop", button3_x + (button_width - smallBoldFont.stringWidth("stop")) / 2.0, button3_y + 0.45 * button_height);
        smallBoldFont.drawString("learning", button3_x + (button_width - smallBoldFont.stringWidth("learning")) / 2.0, button3_y + 0.75 * button_height);
    }
    else {
        smallBoldFont.drawString("start", button3_x + (button_width - smallBoldFont.stringWidth("start")) / 2.0, button3_y + 0.45 * button_height);
        smallBoldFont.drawString("learning", button3_x + (button_width - smallBoldFont.stringWidth("learning")) / 2.0, button3_y + 0.75 * button_height);
    }
    
    ofSetColor(255);
    ofRect(button1_x, button1_y, button_width, button_height);
    ofRect(button2_x, button2_y, button_width, button_height);
	ofRect(button3_x, button3_y, button_width, button_height);
}

void app::drawWaveform()
{
    // waveform
    int h = SCREEN_HEIGHT;
    int w = SCREEN_WIDTH;
    float amplitude		= h / 2.0f;

    unsigned long numSamplesToRead = frameSize;
    float ratio = numSamplesToRead / (float)(w);
    float resolution = 4.0;
    // how many of them to keep for drawing
    int binSize = MAX(ratio * resolution, 1);
    
    // get the resampled audio file
    int numBins = numSamplesToRead / (float)binSize;
    int padding = 0;//w * 0.01;
    
    static vector<float> binnedSamples;
    numBins = numSamplesToRead / (float)binSize;
    if(binnedSamples.size() != numBins)
        binnedSamples.resize(numBins);
    
    float max;
    unsigned long bin_i = 0;
    
    for (unsigned long i = 0; i < numSamplesToRead; i += binSize) {
        vDSP_maxv(output_mono+i, 1, &max, binSize);
        binnedSamples[bin_i++] = max;
    }

    ofPushStyle();
    ofNoFill();
    ofPushMatrix();
    ofSetColor(140, 180, 180, 40);
    ofSetLineWidth(1.0);
    ofTranslate(padding, h / 2.0);
    ofEnableSmoothing();
    
    if(numBins > 0)
    {
        float width_step = (float)(w - padding*2) / (float)numBins;
        for (unsigned long i = 0; i < numBins; i++) {
            float h = binnedSamples[i]*amplitude;
            ofRect(i*width_step, -h, width_step, h*2);
//            ofRect(i*width_step, 0, width_step, h);
        }
    }
    ofDisableSmoothing();
    ofPopMatrix();
    ofPopStyle();
    
}

//--------------------------------------------------------------
void app::draw()
{
    
    ofEnableSmoothing();
    ofEnableAntiAliasing();
    
    
    if (bInteractiveMode) {
        drawInteractiveMode();

    }
    
    else {
        drawPassiveListeningMode();
        
        
    }
    
    
//    ofRect(0, 0, 50, 50);
//    ofCircle(25, 25, 25);
    
    ofEnableAlphaBlending();
    
    ofSetColor(140, 180, 180, 180);
    buttonInfo.draw(SCREEN_WIDTH - button_height / 2.0 - 10, 10, button_height / 2.0, button_height / 2.0);
    drawWaveform();
    
    ofSetColor(200, 200, 200);
    largeBoldFont.drawString("memory mosaic", SCREEN_WIDTH / 2.0 - largeBoldFont.stringWidth("memory mosaic") / 2.0, 40 * height_ratio);
    
    drawHelp();
    
    if (bOutOfMemory) {
        ofSetColor(0, 0, 0, 180);
        ofFill();
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofNoFill();
        ofSetColor(255, 255, 255);
        smallBoldFont.drawString("No more free memory for learning", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("No more free memory for learning") / 2.0, 290 * height_ratio);
    }
    
    else if (bConvertingSong) {
        ofSetColor(0, 0, 0, 180);
        ofFill();
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofNoFill();
        ofSetColor(255, 255, 255);
        smallBoldFont.drawString("Converting song for processing...", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("Converting song for processing...") / 2.0, 160 * height_ratio);
    }
    
    else if(bWaitingForUserToPickSong) {
        ofSetColor(0, 0, 0, 60);
        ofFill();
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofNoFill();
        ofSetColor(255, 255, 255);
        smallBoldFont.drawString("Loading iTunes Library...", SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth("Loading iTunes Library...") / 2.0, 160 * height_ratio);
    }
    ofDisableAlphaBlending();
    
    
    if (animationCounter < animationtime) {
        ofEnableAlphaBlending();
        ofSetColor(0, 0, 0, (float)(animationtime-animationCounter)/(animationtime/2.0f)*255.0f);
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        drawInfo();
        animationCounter++;
        ofDisableAlphaBlending();
    }
}

//--------------------------------------------------------------
void app::drawInteractiveMode() {
    
    if (bDrawNeedsUpdate)
    {
        myFBO.begin();
        ofBackground(0);
        ofEnableAlphaBlending();
        ofSetColor(255);
        
        audioDatabase->drawDatabase(ofGetWidth(), ofGetHeight());
        buttonScreenInteraction.draw(10, 10, button_height / 2, button_height / 2);
        
        ofDisableAlphaBlending();
        
        myFBO.end();
        bDrawNeedsUpdate = false;
    }
    
    ofBackground(0);
    ofSetColor(255);
    ofEnableAlphaBlending();
    myFBO.draw(0,0);
    ofDisableAlphaBlending();
}

void app::drawHelp()
{
    if(bInteractiveMode)
    {
        if (bDrawHelp == 1) {
            ofSetColor(0, 0, 0, 240);
            ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            
            
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  SCREEN_HEIGHT / 2.0 - 35 , SCREEN_WIDTH, 110);
            ofSetColor(255);
            string str = "Each circle represents a learned sound fragment";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 - 25 );
            str = "Touch any of the sound fragments to play them back";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 + 5);
            
            str = "Or go back to the previous screen to learn more sounds";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 + 65);
        }
        
    }
    else
    {
        if(bDrawHelp == 1)
        {
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  0, SCREEN_WIDTH, slider0_y - 25);
            ofSetColor(255);
            string str = "This slider controls the mix between the automatically";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y - 55);
            str = "created synthesis and the input (microphone or ITunes)";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y - 35);
            ofLine(button2_x + button_width / 2, slider0_y, SCREEN_WIDTH/2, slider0_y - 15);
            
            //                str = "of either the microphone or a song.";
            //                infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y + 35);
            
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  slider2_y + 45, SCREEN_WIDTH, 95);
            ofSetColor(255);
            str = "This slider controls the how many sounds are used";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider2_y + 65);
            str = "to try to synthesize the input sound";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider2_y + 85);
            ofLine(button2_x + button_width / 2, slider2_y + 30, SCREEN_WIDTH/2, slider2_y + 45);
            
            infoFont.drawString("1 of 3", SCREEN_WIDTH - 55, SCREEN_HEIGHT - 10);
            
        }
        else if(bDrawHelp == 2) {
            
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  0, SCREEN_WIDTH, button1_y - 10);
            ofSetColor(255);
            
            string str = "When learning is on, any new interesting sounds";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y - 25);
            str = "from the input are stored. These new sounds are used";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y - 5);
            str = "in the synthesis, or during interactive mode";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y + 15);
            ofLine(button3_x + 30 + button_width, slider0_y - 10,
                   button3_x + 40 + button_width, slider0_y - 10);
            ofLine(button3_x + 40 + button_width, slider0_y - 10,
                   button3_x + 40 + button_width, button3_y + button_height / 2);
            ofLine(button3_x + 40 + button_width, button3_y + button_height / 2,
                   button3_x + button_width, button3_y + button_height / 2);
            
            
            
            str = "Erasing the memory removes any learned segments";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y + 60);
            ofLine(button1_x - 35, slider0_y + 55,
                   button1_x - 20, slider0_y + 55);
            ofLine(button1_x - 35, slider0_y + 55,
                   button1_x - 35, button1_y + button_height / 2);
            ofLine(button1_x - 35, button1_y + button_height / 2,
                   button1_x - 10, button1_y + button_height / 2);
            
            
            str = "You can also pick a song from your ITunes Library";
            infoFont.drawString(str, SCREEN_WIDTH/2 - infoFont.stringWidth(str) / 2, slider0_y + 115);
            ofLine(button2_x + button_width / 2, button2_y, SCREEN_WIDTH/2, slider0_y + 125);
            
            
            infoFont.drawString("2 of 3", SCREEN_WIDTH - 55, SCREEN_HEIGHT - 10);
        }
        else if(bDrawHelp == 3) {
            
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  0, SCREEN_WIDTH, SCREEN_HEIGHT);
            ofSetColor(255);
            
            string str = "After learning a few sounds, you can also";
            infoFont.drawString(str, SCREEN_WIDTH / 2 - infoFont.stringWidth(str) / 2, slider0_y);
            str = "interactively play them with your touchscreen";
            infoFont.drawString(str, SCREEN_WIDTH / 2 - infoFont.stringWidth(str) / 2, slider0_y + 20);
            
            ofLine(10 + button_height / 4, 10 + button_height, 10 + button_height / 4, slider0_y + 10);
            ofLine(30 + button_height / 4, slider0_y + 10, 10 + button_height / 4, slider0_y + 10);
            
            buttonScreenSliders.draw(10, 10, button_height / 2, button_height / 2);
            
            infoFont.drawString("3 of 3", SCREEN_WIDTH - 55, SCREEN_HEIGHT - 10);
        }
    }
}


//--------------------------------------------------------------
void app::drawPassiveListeningMode()
{
    if (bDrawNeedsUpdate) {
        
        myFBO.begin();
        ofBackground(0);
        ofEnableAlphaBlending();
        ofTranslate(-7, 0, 0);
        ofFill();
        ofSetColor(200, 200, 200);
        
		drawButtons();
		drawSliders();
        
        ofDisableAlphaBlending();
        myFBO.end();
        
        bDrawNeedsUpdate = false;
    }
    
    
    ofBackground(0);
    ofSetColor(255);
    ofEnableAlphaBlending();
    myFBO.draw(0,0);
    
    
    int s = audioDatabase->getSize();
    if ( s < 32 )
        ofSetColor(s/32.0 * 64.0);
    else
        ofSetColor(255);
    buttonScreenSliders.draw(10, 10, button_height / 2, button_height / 2);
    
    ofSetColor(180, 140, 140);
    
    string numData = string("size: ") + ofToString(audioDatabase->getSize());
    smallBoldFont.drawString(numData,
                             SCREEN_WIDTH / 2.0 - smallBoldFont.stringWidth(numData) / 2.0,
                             70 * height_ratio);
    
    ofDisableAlphaBlending();
    
    

//    else if(segmentationCounter < segmentationtime) {
//        ofEnableAlphaBlending();
//        ofSetColor(255, 255, 255, (float)(segmentationtime-segmentationCounter)/(segmentationtime/2.0f)*40.0f);
//        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
//        segmentationCounter++;
//        ofDisableAlphaBlending();
//    }
}

//--------------------------------------------------------------
void app::audioOut(float * output, int bufferSize,
                   int ch)
{
    bSemaphore = true;
    vector<ofPtr<pkmAudioSegment> >::iterator it;
    
    vDSP_vclr(output_mono, 1, bufferSize);
    vDSP_vclr(buffer, 1, bufferSize);
    
    // if we detected a segment
    if((!bInteractiveMode && bDetectedOnset) ||
       (bInteractiveMode && bTouching))
    {
        // find matches
        vector<ofPtr<pkmAudioSegment> > newSegments;
        if (bInteractiveMode)
        {
            if(bTouching)
            {
                newSegments = audioDatabase->selectFromDatabase(touchX, touchY, SCREEN_WIDTH, SCREEN_HEIGHT);
                bTouching = false;
            }
        }
        else
            newSegments = audioDatabase->getNearestAudioSegments(foreground_features);

        int totalSegments = newSegments.size() + nearestAudioSegments.size();
        
        // if we are syncopated, we force fade out of old segments
        if (bSyncopated) {
            it = nearestAudioSegments.begin();
            while( it != nearestAudioSegments.end() )
            {
                
                //printf("frame: %d\n", ((*it)->onset + (*it)->frame*frameSize) / frameSize);
                // get frame
#ifdef DO_FILEBASED_SEGMENTS
                pkmEXTAudioFileReader reader;
                reader.open(ofToDataPath((*it)->filename), sampleRate);
                long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
                reader.read(buffer,
                            sampleStart,
                            (long)frameSize,
                            sampleRate);
                reader.close();
#else
                cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
#endif
                //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frameSize);
                (*it)->bPlaying = false;
                (*it)->frame = 0;
                it++;
                
                // mix in
                //vDSP_vsmul(buffer, 1, &level, buffer, 1, fadeLength);
#ifdef DO_REALTIME_FADING
                // fade out
                vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
#endif
                vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
                
            }
            
            nearestAudioSegments.clear();
        }
        // otherwise we playback old nearest neighbors as normal
        else
        {
            vector<ofPtr<pkmAudioSegment> >::iterator it = nearestAudioSegments.begin();
            while(it != nearestAudioSegments.end())
            {
                // get frame
#ifdef DO_FILEBASED_SEGMENTS
                pkmEXTAudioFileReader reader;
                reader.open(ofToDataPath((*it)->filename), sampleRate);
                long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
                reader.read(buffer,
                            sampleStart,
                            (long)frameSize,
                            sampleRate);
                reader.close();
#else
                cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
#endif
                //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frameSize);
                (*it)->frame++;
                
                // mix in
                //vDSP_vsmul(buffer, 1, &level, buffer, 1, frameSize);
                
                if (((*it)->onset + (*it)->frame*frameSize) >= (*it)->offset)
                {
#ifdef DO_REALTIME_FADING
                    // fade out
                    vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutBuffer, 1,
                              buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutLength);
#endif
                    (*it)->bPlaying = false;
                    (*it)->frame = 0;
                    it = nearestAudioSegments.erase(it);
                }
                else if((*it)->bNeedsReset)
                {
                    // fade out
                    vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutBuffer, 1,
                              buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutLength);
                    (*it)->frame = 0;
                    (*it)->bNeedsReset = false;
                    it++;
                }
                else
                    it++;
                
                vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
            }
        }
        
        totalSegments = nearestAudioSegments.size();
        
        // fade in new segments and store them for next frame
        it = newSegments.begin();
        while( it != newSegments.end() )
        {
#ifdef DO_FILEBASED_SEGMENTS
            pkmEXTAudioFileReader reader;
            reader.open(ofToDataPath((*it)->filename), sampleRate);
            long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
            reader.read(buffer,
                        sampleStart,  // should be 0...
                        (long)frameSize,
                        sampleRate);
            reader.close();
#else
            cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
            
//            cout << (*it)->index << endl;
            
            //audioDatabase->featureDatabase.printAbbrev();
#endif
            (*it)->frame++;
            (*it)->bPlaying = true;
            
#ifdef DO_REALTIME_FADING
            // fade in
            vDSP_vmul(buffer, 1,
                      pkmAudioWindow::rampInBuffer, 1,
                      buffer, 1,
                      pkmAudioWindow::rampInLength);
#endif
            
            // check if segment is ready for fade out, i.e. segment is only "frameSize" samples
            if (((*it)->onset + (*it)->frame*frameSize) >= (*it)->offset)
            {
#ifdef DO_REALTIME_FADING
                // fade out
                vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
#endif
                
                (*it)->bPlaying = false;
                (*it)->frame = 0;
                it = newSegments.erase(it);
            }
            // otherwise move to next segment
            else
            {
                it++;
            }
            
            // and mix in the faded segment to the stream
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
        }
        
        // store new segments
        nearestAudioSegments.insert(nearestAudioSegments.end(), newSegments.begin(), newSegments.end());
        
    }
    // no onset, continue playback of old nearest neighbors
    else
    {
        // loop through all previous neighbors
        vector<ofPtr<pkmAudioSegment> >::iterator it = nearestAudioSegments.begin();
        while(it != nearestAudioSegments.end())
        {
#ifdef DO_FILEBASED_SEGMENTS
            // get audio frame
            pkmEXTAudioFileReader reader;
            reader.open(ofToDataPath((*it)->filename), sampleRate);
            long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frameSize;
            reader.read(buffer,
                        sampleStart,
                        (long)frameSize,
                        sampleRate);
            reader.close();
#else
            cblas_scopy(frameSize, (*it)->buffer + (*it)->frame*frameSize, 1, buffer, 1);
#endif
            //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frameSize);
            
            (*it)->frame++;
            
            // finished playing audio segment?
            if ((*it)->onset + (*it)->frame*frameSize  >= (*it)->offset)
            {
#ifdef DO_REALTIME_FADING
                // fade out
                vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
#endif
                
                (*it)->bPlaying = false;
                (*it)->frame = 0;
                it = nearestAudioSegments.erase(it);
            }
            
            else if((*it)->bNeedsReset)
            {
                // fade out
                vDSP_vmul(buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frameSize - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
                (*it)->frame = 0;
                (*it)->bNeedsReset = false;
                it++;
            }
            
            // no, keep it for next frame
            else
                it++;
            
            // mix in
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
        }
    }
    
    
    // mix in input
    if (!bInteractiveMode) {
        if(bProcessingSong)
        {
            vDSP_vsmul(itunes_frame, 1, &slider0_position, buffer, 1, frameSize);
            float mixR = 1.0f - slider0_position;
            vDSP_vsmul(output_mono, 1, &mixR, output_mono, 1, frameSize);
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
        }
        else
        {
            vDSP_vsmul(current_frame, 1, &slider0_position, buffer, 1, frameSize);
            float mixR = 1.0f - slider0_position;
            vDSP_vsmul(output_mono, 1, &mixR, output_mono, 1, frameSize);
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frameSize);
        }
    }
    
	
#ifdef DO_RECORD
	audioInputFileWriter.write(current_frame, output_frame*frameSize, frameSize);
	audioOutputFileWriter.write(output_mono, output_frame*frameSize, frameSize);
	output_frame++;
#endif
    
    for (int i = 0; i < frameSize; i++)
    {
//        output_mono[i] = compressor.compressor(loresFilter.lores(output_mono[i], 8000, 1.0), 0.65, 0.75, 1.0, 0.995);
        output_mono[i] = compressor.compressor(output_mono[i], 0.65, 0.75, 1.0, 0.995);
    }
    
    float neg = -1.0f, pos = 1.0f;
    
    vDSP_vclip(output_mono, 1, &neg, &pos, output_mono, 1, frameSize);
	
	// mix to stereo
    cblas_scopy(frameSize, output_mono, 1, output, 2);
    cblas_scopy(frameSize, output_mono, 1, output+1, 2);
    
    bSemaphore = false;
}

void app::processITunesInputFrame()
{
    // check for max segment
    bool bMaxSegmentReached = currentITunesSegment.isCircularInsertionFull();
    
    // parse segment
    if(bDetectedOnset || bMaxSegmentReached)
    {
        int segmentSize = bMaxSegmentReached ? currentITunesSegment.rows : currentITunesSegment.current_row;
        
        pkm::Mat croppedFeature(segmentSize, numFeatures, currentITunesSegmentFeatures.data, false);
        pkm::Mat meanFeature = croppedFeature.mean();
        //meanFeature.print();
        if (true)//audioDatabase->bShouldAddSegment(meanFeature.data))
        {
            currentFile++;
            // fade in
            vDSP_vmul(currentITunesSegment.data, 1,
                      pkmAudioWindow::rampInBuffer, 1,
                      currentITunesSegment.data, 1,
                      pkmAudioWindow::rampInLength);
            // fade out
            vDSP_vmul(currentITunesSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutBuffer, 1,
                      currentITunesSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutLength);
            
#ifdef DO_FILEBASED_SEGMENTS
            pkmEXTAudioFileWriter writer;
            char buf[256];
            sprintf(buf, "%saudiofile_%08d.wav", documentsDirectory.c_str(), currentFile);
            if(!writer.open(ofToDataPath(buf), frameSize, sampleRate))
            {
                printf("[ERROR] Could not write file!\n");
                OF_EXIT_APP(0);
            }
            writer.write(currentITunesSegment.data, 0, segmentSize * frameSize);
            writer.close();
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(buf,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#else
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(currentITunesSegment.data,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#endif
            //            audioDatabase->addAudioSequence(audio_segment, currentITunesSegmentFeatures);
            //            audioDatabase->addAudioSegment(audio_segment, currentITunesSegmentFeatures.data, numFeatures);
//            audioDatabase->addAudioSegment(audio_segment, meanFeature.data, numFeatures);
            audioDatabase->addAudioSegment(audio_segment, croppedFeature.row(0), numFeatures);
            audioDatabase->buildIndex();
            audioDatabase->updateScreenMapping();
            
            //            logMemUsage();
            //            if (audioDatabase->featureDatabase.rows > 5) {
            //                pkmAudioFeatureNormalizer::normalizeDatabase(audioDatabase->featureDatabase);
            //            }
        }
        
        currentITunesSegment.resetCircularRowCounter();
        currentITunesSegmentFeatures.resetCircularRowCounter();
        
        bDrawNeedsUpdate = true;
    }
}



void app::processInputFrame()
{
    // check for max segment
    bool bMaxSegmentReached = currentSegment.isCircularInsertionFull();
    
    // parse segment
    if(bDetectedOnset || bMaxSegmentReached)
    {
        int segmentSize = bMaxSegmentReached ? currentSegment.rows : currentSegment.current_row;
        
        pkm::Mat croppedFeature(segmentSize, numFeatures, currentSegmentFeatures.data, false);
        pkm::Mat meanFeature = croppedFeature.mean();
        //meanFeature.print();
        if (true)//audioDatabase->bShouldAddSegment(meanFeature.data))
        {
            currentFile++;
            // fade in
            vDSP_vmul(currentSegment.data, 1,
                      pkmAudioWindow::rampInBuffer, 1,
                      currentSegment.data, 1,
                      pkmAudioWindow::rampInLength);
            // fade out
            vDSP_vmul(currentSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutBuffer, 1,
                      currentSegment.data + segmentSize * frameSize - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutLength);
            
#ifdef DO_FILEBASED_SEGMENTS
            pkmEXTAudioFileWriter writer;
            char buf[256];
            sprintf(buf, "%saudiofile_%08d.wav", documentsDirectory.c_str(), currentFile);
            if(!writer.open(ofToDataPath(buf), frameSize, sampleRate))
            {
                printf("[ERROR] Could not write file!\n");
                OF_EXIT_APP(0);
            }
            writer.write(currentSegment.data, 0, segmentSize * frameSize);
            writer.close();
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(buf,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#else
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(currentSegment.data,
                                                                      0,
                                                                      segmentSize * frameSize,
                                                                      currentFile ) );
#endif
//            audioDatabase->addAudioSequence(audio_segment, currentSegmentFeatures);
//            audioDatabase->addAudioSegment(audio_segment, currentSegmentFeatures.data, numFeatures);
//            audioDatabase->addAudioSegment(audio_segment, meanFeature.data, numFeatures);
            audioDatabase->addAudioSegment(audio_segment, croppedFeature.row(0), numFeatures);
            audioDatabase->buildIndex();
            audioDatabase->updateScreenMapping();
            
            //            logMemUsage();
            //            if (audioDatabase->featureDatabase.rows > 5) {
            //                pkmAudioFeatureNormalizer::normalizeDatabase(audioDatabase->featureDatabase);
            //            }
        }
        
        currentSegment.resetCircularRowCounter();
        currentSegmentFeatures.resetCircularRowCounter();
        
        bDrawNeedsUpdate = true;
    }
}


//--------------------------------------------------------------
void app::audioIn(float * buf, int size,
                  int ch)
{
    
//    vDSP_vclr(buf, 1, size*ch);
    
    if (animationCounter < animationtime || bInteractiveMode) {
        vDSP_vclr(buf, 1, size*ch);
        return;
    }
    
    if (!bOutOfMemory && bProcessingSong)
    {

        if(!itunesStream.getNextBuffer(itunes_frame))
            bProcessingSong = false;
        
//        for (int i = 0; i < size * ch; i++)
//        {
//            itunes_frame[i] = compressorInput.compressor(itunes_frame[i], 1.0, 1.0, 0.1, 0.4);
//        }

        ringBuffer->insertFrame(itunes_frame);

        if (ringBuffer->isRecorded())
        {
            ringBuffer->copyAlignedData(alignedFrame);
        
            // get audio features
//            audioFeature->compute36DimAudioFeaturesF(alignedFrame, foreground_features);
//            audioFeature->computeLFCCF(alignedFrame, foreground_features, numFeatures);
            audioFeature->compute24DimAudioFeaturesF(alignedFrame, foreground_features);
//            dct.dctII_1D(alignedFrame, foreground_features, numFeatures);
            
            // check for onset
            bDetectedOnset = spectralFlux->detectOnset(audioFeature->getMagnitudes(), audioFeature->getMagnitudesLength());
        }
        
        if(bDetectedOnset)
            segmentationCounter = 0;
        
        if (bLearning)
        {
            processITunesInputFrame();
        }
        else
        {
            currentITunesSegment.resetCircularRowCounter();
            currentITunesSegmentFeatures.resetCircularRowCounter();
        }
        // ring buffer for current segment
        currentITunesSegment.insertRowCircularly(itunes_frame);
        
        // ring buffer for audio features
        currentITunesSegmentFeatures.insertRowCircularly(foreground_features);
        //        }
    }
    else
    {
        cblas_scopy(size, buf, ch, current_frame, 1);
        
//        for (int i = 0; i < size * ch; i++)
//        {
//            current_frame[i] = compressorInput.compressor(current_frame[i], 1.0, 1.0, 0.1, 0.4);
//        }

        
        ringBuffer->insertFrame(current_frame);

        if (ringBuffer->isRecorded())
        {
            ringBuffer->copyAlignedData(alignedFrame);
        
            // get audio features
            //            audioFeature->compute36DimAudioFeaturesF(alignedFrame, foreground_features);
            //audioFeature->computeLFCCF(alignedFrame, foreground_features, numFeatures);
            audioFeature->compute24DimAudioFeaturesF(alignedFrame, foreground_features);
//            dct.dctII_1D(alignedFrame, foreground_features, numFeatures);
            
            // check for onset
            bDetectedOnset = spectralFlux->detectOnset(audioFeature->getMagnitudes(), audioFeature->getMagnitudesLength());
        }
        
        if(bDetectedOnset)
            segmentationCounter = 0;
        
        if (bLearning)
        {
            processInputFrame();
        }
        else
        {
            currentSegment.resetCircularRowCounter();
            currentSegmentFeatures.resetCircularRowCounter();
        }
        
        // ring buffer for current segment
        currentSegment.insertRowCircularly(current_frame);
        
        // ring buffer for audio features
        currentSegmentFeatures.insertRowCircularly(foreground_features);

    }
}

template <class T>
inline bool within(T xt, T yt,
				   T x, T y, T w, T h)
{
	return xt > x && xt < (x+w) && yt > y && yt < (y+h);
}


#ifdef TARGET_OF_IPHONE
//--------------------------------------------------------------
void app::touchDown(ofTouchEventArgs &touch)
{
    if(bDrawHelp)
        return;
    else if (bInteractiveMode) {
        bTouching = true;
        touchX = touch.x;
        touchY = touch.y;
        bDrawNeedsUpdate = true;
        
    }
    else {
        if(!bConvertingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
        {
            if(touch.y > slider0_y-20 && touch.y < slider0_y+20)
            {
                bMovingSlider0 = true;
                bMovingSlider1 = false;
                bMovingSlider2 = false;
            }
            else if(touch.y > slider1_y-20 && touch.y < slider1_y+20)
            {
                bMovingSlider0 = false;
                bMovingSlider1 = true;
                bMovingSlider2 = false;
            }
            else if(touch.y > slider2_y-20 && touch.y < slider2_y+20)
            {
                bMovingSlider0 = false;
                bMovingSlider1 = false;
                bMovingSlider2 = true;
            }
        }
    }
}

//--------------------------------------------------------------
void app::touchMoved(ofTouchEventArgs &touch){
    if(bDrawHelp)
        return;
    else if (bInteractiveMode) {
        
        bTouching = true;
        touchX = touch.x;
        touchY = touch.y;
        bDrawNeedsUpdate = true;
        
    }
    else {
        
        if(!bConvertingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
        {
            
            if(bMovingSlider0)
            {
                slider0_position = MIN(1.0f, MAX(0.0f, (touch.x - slider0_x) / (float)slider_width));
                bDrawNeedsUpdate = true;
                bMovingSlider0 = true;
                bMovingSlider1 = false;
                bMovingSlider2 = false;
            }
            else if(bMovingSlider1)
            {
                slider1_position = MIN(1.0, MAX(0.0, (touch.x - slider1_x) / (float)slider_width));
    //            spectralFlux->setOnsetThreshold((1.0f-slider1_position)*1.0f + 0.01f);
    //            spectralFlux->setMinSegmentLength(MAX_GRAIN_LENGTH * sampleRate / (float)frameSize * (float)slider1_position);  // half second
                bDrawNeedsUpdate = true;
                bMovingSlider0 = false;
                bMovingSlider1 = true;
                bMovingSlider2 = false;
            }
            else if(bMovingSlider2)
            {
                slider2_position = MIN(1.0, MAX(0.0, (touch.x - slider2_x) / (float)slider_width));
                audioDatabase->setK(round(slider2_position*maxVoices));
                bDrawNeedsUpdate = true;
                bMovingSlider0 = false;
                bMovingSlider1 = false;
                bMovingSlider2 = true;
            }
        }
        
        if(bDrawNeedsUpdate)
            ofSetFrameRate(30);
    }
}

//--------------------------------------------------------------
void app::touchUp(ofTouchEventArgs &touch)
{
    
   if( bDrawHelp )
   {
       bDrawNeedsUpdate = true;
       bDrawHelp++;
       if ((bInteractiveMode && bDrawHelp > 1) ||       // number of help screens for interactive mode
           (!bInteractiveMode && bDrawHelp > 3)) {      // number of help screens for menu mode
           bDrawHelp = 0;
       }
   }
    else if (touch.x > SCREEN_WIDTH - button_height - 10 && touch.y < button_height / 2.0 + 10)
    {
        bDrawHelp = 1;
        bDrawNeedsUpdate = true;
    }
    else if (bInteractiveMode) {
        
        if (touch.x < 50 && touch.y < 50) {
            bInteractiveMode = false;
            bTouching = false;
            bDrawNeedsUpdate = true;
            bSyncopated = false;
            return;
        }
        
        bTouching = false;
        touchX = touch.x;
        touchY = touch.y;
        
    }
    else {
        if(!bConvertingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
        {
//            if (audioDatabase->getSize() > 32) {
                if (touch.x < 50 && touch.y < 50) {
                    audioDatabase->buildScreenMapping();
                    bTouching = false;
                    bInteractiveMode = true;
                    bDrawNeedsUpdate = true;
                    bSyncopated = true;
                    return;
                }
//            }
            
            //printf("Checking buttons\n");
            if (within<int>(touch.x, touch.y, button1_x, button1_y, button_width, button_height)) {
                //printf("Button 1 pressed\n");
                audioDatabase->resetDatabase();
                
                bDrawNeedsUpdate = true;
                currentFile = 0;
            }
            else if(within<int>(touch.x, touch.y, button2_x, button2_y, button_width, button_height)) {
                //printf("Button 2 pressed\n");
                if(bProcessingSong)
                {
                    bProcessingSong = false;
                    bDrawNeedsUpdate = true;
                }
                else
                {
                    itunesStream.pickSong();
                    bWaitingForUserToPickSong = true;
                }
            }
            else if(within<int>(touch.x, touch.y, button3_x, button3_y, button_width, button_height)) {
                //printf("Button 3 pressed\n");
                bLearning = !bLearning;
                
    //            if (!bLearning) {
    //                audioDatabase->featureDatabase.print();
    //                audioDatabase->buildScreenMapping();
    //            }
                
                bDrawNeedsUpdate = true;
            }
            else if(bMovingSlider0)
            {
                slider0_position = MIN(1.0f, MAX(0.0f, (touch.x - slider0_x) / (float)slider_width));
                bDrawNeedsUpdate = true;
            }
            else if(bMovingSlider1)
            {
                slider1_position = MIN(1.0, MAX(0.0, (touch.x - slider1_x) / (float)slider_width));
                //            spectralFlux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
    //            spectralFlux->setMinSegmentLength(sampleRate / (float)frameSize * (float)slider1_position);  // half second
                bDrawNeedsUpdate = true;
            }
            else if(bMovingSlider2)
            {
                slider2_position = MIN(1.0, MAX(0.0, (touch.x - slider2_x) / (float)slider_width));
                audioDatabase->setK(round(slider2_position*maxVoices));
                bDrawNeedsUpdate = true;
            }
            //else if(within<int>(touch.x, touch.y, checkbox1_x, checkbox1_y, checkbox_size, checkbox_size))
            //{
            //	checkbox1 = !checkbox1;
            //	bSyncopated = !bSyncopated;
            //}
        }
        
        bMovingSlider0 = false;
        bMovingSlider1 = false;
        bMovingSlider2 = false;
    }
}

//--------------------------------------------------------------
void app::touchDoubleTap(ofTouchEventArgs &touch)
{
	
}

void app::touchCancelled(ofTouchEventArgs &touch)
{
	
}

void app::gotMemoryWarning()
{
    bOutOfMemory = true;
    bDrawNeedsUpdate = true;
    bLearning = false;
}
#else

void app::mousePressed(int x, int y, int button)
{
	printf("mouse pressed\n");
    if(!bConvertingSong && !bProcessingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
    {
		//printf("Checking buttons\n");
        if (within<int>(x, y, button1_x, button1_y, button_width, button_height)) {
            //printf("Button 1 pressed\n");
            audioDatabase->resetDatabase();
            bDrawNeedsUpdate = true;
            currentFile = 0;
        }
        else if(within<int>(x, y, button2_x, button2_y, button_width, button_height)) {
            //printf("Button 2 pressed\n");
			string filename;
			if(ofxFileDialogOSX::openFile(filename) == 1)
			{
				printf("Reading %s\n", filename.c_str());
				songReader.open(filename);
				bLoadedSong = true;
			}
        }
        else if(within<int>(x, y, button3_x, button3_y, button_width, button_height)) {
            //printf("Button 3 pressed\n");
            bLearning = !bLearning;
            bDrawNeedsUpdate = true;
        }
		else if(within<int>(x, y, slider0_x, slider0_y-20, slider_width, 40))
		{
			slider0_position =MIN(0.99f, MAX(0.01f, (x - slider0_x) / (float)slider_width));
            bDrawNeedsUpdate = true;
		}
		else if(within<int>(x, y, slider1_x, slider1_y-20, slider_width, 40))
		{
			slider1_position = (x - slider1_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
            //            spectralFlux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
//            spectralFlux->setMinSegmentLength(sampleRate / (float)frameSize * (float)slider1_position);  // half second
		}
		else if(within<int>(x, y, slider2_x, slider2_y-20, slider_width, 40))
		{
			slider2_position = (x - slider2_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
			audioDatabase->setK(slider2_position*15);
		}
		//else if(within<int>(x, y, checkbox1_x, checkbox1_y, checkbox_size, checkbox_size))
		//{
		//	checkbox1 = !checkbox1;
		//	bSyncopated = !bSyncopated;
		//}
    }
    
    
    if(bDrawNeedsUpdate)
        ofSetFrameRate(30);
	
}

//--------------------------------------------------------------
void app::mouseDragged(int x, int y, int button){
	
    printf("mouse moved\n");
    if(!bConvertingSong && !bProcessingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
    {
        if(within<int>(x, y, slider0_x, slider0_y-20, slider_width, 40))
        {
            slider0_position =MIN(0.99f, MAX(0.01f, (x - slider0_x) / (float)slider_width));
            bDrawNeedsUpdate = true;
        }
        else if(within<int>(x, y, slider1_x, slider1_y-20, slider_width, 40))
        {
            slider1_position = (x - slider1_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
            //            spectralFlux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
//            spectralFlux->setMinSegmentLength(sampleRate / (float)frameSize * (float)slider1_position);  // half second
        }
        else if(within<int>(x, y, slider2_x, slider2_y-20, slider_width, 40))
        {
            slider2_position = (x - slider2_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
            audioDatabase->setK(slider2_position*6.0f);
        }
    }
	
    
    if(bDrawNeedsUpdate)
        ofSetFrameRate(30);
}

void app::mouseReleased(int x, int y)
{
	printf("mouse released\n");
    
}

#endif
