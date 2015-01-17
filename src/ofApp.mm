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
 
 * Create paths from touch and loop them... have multiple loops concurrent... 
 
 * Speed/warping based on velocity/movement of touch
 * Show grid over selected sound fragment, x/y dimensions changing pitch/time stretch... 
 * Pan/Zoom over segments to get better control
 
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
int slider1_y = 145;
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
float scale_factor = 1.0f;

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
    audio_database_normalizer->saveNormalization();
#endif
    
}

//--------------------------------------------------------------
void app::setup()
{
    ofSetOrientation(OF_ORIENTATION_90_RIGHT);
    
    
//    ofxiOSGetOFWindow()->disableOrientationAnimation();
//    ofxiOSGetOFWindow()->disableHardwareOrientation();
    ofxiOSGetOFWindow()->enableAntiAliasing(8);
    ofxiOSGetOFWindow()->enableRetina();
    ofxiOSGetOFWindow()->enableOrientationAnimation();
    
    if(ofxiOSGetOFWindow()->isRetinaEnabled())
        scale_factor = 2.0;
    
    SCREEN_WIDTH = ofGetWidth();
    SCREEN_HEIGHT = ofGetHeight();
    
    if(SCREEN_WIDTH < SCREEN_HEIGHT)
        std::swap(SCREEN_WIDTH, SCREEN_HEIGHT);
    
    ofSetCircleResolution(30);
    
//    ofSetWindowShape(SCREEN_WIDTH, SCREEN_HEIGHT);

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
    
//	ofSetOrientation(OF_ORIENTATION_90_RIGHT);
    
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
    bDrawOptions = true;
    bDrawHelp = 0;
    
    sampleRate = 44100;
    frame_size = 512;
    fftSize = 8192;
    frame = 0;
    currentFile = 0;
    
    bMovingSlider0 = bMovingSlider1 = bMovingSlider2 = false;
    
    buttonScreenInteraction.loadImage("speckles.png");
    buttonMenuSliders.loadImage("sliders.png");
    buttonInfo.loadImage("help.png");
    
    // setup envelopes
    pkmAudioWindow::initializeWindow(frame_size);
    
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
	itunes_stream.allocate(sampleRate, frame_size, 1);
	
	
	// register touch events
	//ofRegisterTouchEvents(this);
	
	// iPhoneAlerts will be sent to this.
	// ofxiPhoneAlerts.addListener(this);
	
    fbo.allocate(SCREEN_WIDTH, SCREEN_HEIGHT, GL_RGBA);
    fbo2.allocate(SCREEN_WIDTH, SCREEN_HEIGHT, GL_RGBA);
    fbo3.allocate(SCREEN_WIDTH, SCREEN_HEIGHT, GL_RGBA);
#else
	ofSetWindowShape(480, 320);
    fbo.allocate(480, 320);
	ofSetFullscreen(false);
#endif
    
	// black
	ofBackground(0,0,0);
    ofSetFrameRate(30);
	//, bool _bFullCharacterSet, bool _makeContours, float _simplifyAmt, int _dpi
    small_bold_font.loadFont("Dekar.ttf", 15, true, false, true, 0.0);
    large_bold_font.loadFont("Dekar.ttf", 36, true, false, true, 0.0);
    info_font.loadFont("DekarLight.ttf", 14, true, false, true, 0.0);
	
    background.loadImage("bg.png");
    
    button.loadImage("button.png");
    
    ring_buffer = new pkmCircularRecorder(fftSize, frame_size);
    aligned_frame = (float *)malloc(sizeof(float) * fftSize);
    
    zeroFrame = (float *)malloc(sizeof(float) * frame_size);
    memset(zeroFrame, 0, sizeof(float) * frame_size);
    
    current_frame = (float *)malloc(sizeof(float) * frame_size);
    itunes_frame = (float *)malloc(sizeof(float) * frame_size);
    buffer = (float *)malloc(sizeof(float) * frame_size);
    output = (float *)malloc(sizeof(float) * frame_size);
    output_mono = (float *)malloc(sizeof(float) * frame_size);
	
	// does onset detection for matching
    slider1_position = 0.05;
    spectral_flux = new pkmAudioSpectralFlux(frame_size, fftSize, sampleRate);
    spectral_flux->setOnsetThreshold(0.25);
    spectral_flux->setIIRAlpha(0.01);
	spectral_flux->setMinSegmentLength(MAX_GRAIN_LENGTH * sampleRate / frame_size * slider1_position);
    
	audio_database = new pkmAudioSegmentDatabase();
    int k = 3;
	audio_database->setK(k);
    audio_database->setMaxObjects(500);
	slider2_position = (k - 1)/(maxVoices - 1);
	
    audio_feature = new pkmAudioFeatures(sampleRate, fftSize);
//    dct.setup(fftSize);
    
    numFeatures = 24;
    audio_database_normalizer = new pkmAudioFeatureNormalizer(numFeatures);
    current_num_features = 0;
    
#ifndef DO_FILEINPUT
    audio_database_normalizer->loadNormalization();
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
    current_segment = pkm::Mat(SAMPLE_RATE / frame_size * 5, frame_size, true);
    current_segment_features = pkm::Mat(SAMPLE_RATE / frame_size * 5, numFeatures, true);
    
    current_itunes_segment = pkm::Mat(SAMPLE_RATE / frame_size * 5, frame_size, true);
    current_itunes_segment_features = pkm::Mat(SAMPLE_RATE / frame_size * 5, numFeatures, true);
    
	animationCounter = 0;
    segmentationCounter = segmentationtime;
	
    maxiSettings::setup(sampleRate, 1, frame_size);
    
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
	audioOutputFileWriter.open(strFilename, frame_size);
	
	// setup input
	str2 << strDocumentsDirectory << "/" << "input_" << ofGetDay() << ofGetMonth() << ofGetYear()
	<< "_" << ofGetHours() << "_" << ofGetMinutes() << "_" << ofGetSeconds() << ".wav";
	strFilename = str2.str();
	audioInputFileWriter.open(strFilename, frame_size);
#endif
    
//    setupMatching();
    
    
	ofEnableAlphaBlending();
	ofSetBackgroundAuto(false);
    ofBackground(0);

    
#ifdef DO_FILEINPUT
    
#else
    bLearningInputForNormalization = true;
    //	ofSetFrameRate(25);
	ofSoundStreamSetup(2, 1, this, sampleRate, frame_size, 1);
    
    NSString *category = AVAudioSessionCategoryPlayAndRecord;
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeakerr;
    NSError *averror = nil;
    if ( ![[AVAudioSession sharedInstance] setCategory:category withOptions:options error:&averror] ) {
        NSLog(@"Couldn't set audio session category: %@", averror);
    }
    

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
        while(frame * frame_size < songReader.mNumSamples && !bOutOfMemory)
        {
            if(songReader.read(current_frame, frame*frame_size, frame_size))
            {
                // get audio features
//                audio_feature->compute36DimAudioFeaturesF(current_frame, foreground_features);
                audio_feature->computeLFCCF(current_frame, foreground_features, numFeatures);
                
                // check for onset
                bDetectedOnset = spectral_flux->detectOnset(audio_feature->getMagnitudes(), audio_feature->getMagnitudesLength());
                
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
         current_num_features = audio_database->featureDatabase.rows;
         if (current_num_features > lastNumFeatures) {
         pkm::Mat thisDatabase = audio_database->featureDatabase.rowRange(lastNumFeatures, current_num_features, false);
         printf("Normalizing database of features for %s: \n", it->getFileName().c_str());
         thisDatabase.print();
         pkmAudioFeatureNormalizer::normalizeDatabase(thisDatabase);
         }
         lastNumFeatures = current_num_features;
         */
    }
    
    //pkmAudioFeatureNormalizer::normalizeDatabase(audio_database->featureDatabase);
    //audio_database->buildIndex();
    //audio_database->save();
    //audio_database->saveIndex();
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
     
     while(inputAudioFileFrame*frame_size < inputAudioFileReader.mNumSamples)
     {
     //printf("inputAudioFileFrame: %ld\n", inputAudioFileFrame);
     inputAudioFileReader.read(current_frame, inputAudioFileFrame*frame_size, frame_size);
     inputAudioFileFrame++;
     //ring_buffer->insertFrame(current_frame);
     //if (ring_buffer->bRecorded) {
     //ring_buffer->copyAlignedData(aligned_frame);
     #ifdef DO_MEAN_MEL_FEATURE
     audio_feature->computeLFCCF(current_frame, foreground_features, numFeatures);
     #else
     audio_feature->computeLFCCF(current_frame, foreground_features, numFeatures);
     #endif
     
     bool isFeatureNan = false;
     for (int i = 0; i < numFeatures; i++) {
     isFeatureNan = isFeatureNan | isnan(foreground_features[i]) | (fabs(foreground_features[i]) > 20);
     }
     
     if (!isFeatureNan) {
     //printf(".");
     audio_database_normalizer->addExample(foreground_features, numFeatures);
     }
     //}
     }
     audio_database_normalizer->calculateNormalization();
     */
    
    
    inputAudioFileFrame = 0;
#endif
    
    //audio_database->load();
    //audio_database->loadIndex();
}

//--------------------------------------------------------------
void app::update()
{
#ifdef DO_FILEINPUT
    
    while(inputAudioFileFrame*frame_size < inputAudioFileReader.mNumSamples)
    {
        inputAudioFileReader.read(current_frame, inputAudioFileFrame*frame_size, frame_size);
        
        if (bLearning) {
            processInputFrame(current_frame, frame_size);
        }
        
        audioRequested(current_frame, frame_size, 1);
        
        inputAudioFileFrame++;
    }
    
    
    printf("[OK] Finished processing file.  Exiting.\n");
    OF_EXIT_APP(0);
#endif
    
#ifdef TARGET_OF_IPHONE
    if (bWaitingForUserToPickSong && itunes_stream.isSelected())
    {
        bWaitingForUserToPickSong = false;
        bProcessingSong = false;
        bConvertingSong = true;
        itunes_stream.setStreaming();
        printf("[OK]\n");
        bDrawNeedsUpdate = true;
        printf("Loaded user selected song!\n");
    }
    else if(bWaitingForUserToPickSong && itunes_stream.didCancel())
    {
        bWaitingForUserToPickSong = false;
        printf("[OK]\n");
        bDrawNeedsUpdate = true;
        printf("User canceled!\n");
        
    }
    else if(bConvertingSong && itunes_stream.isPrepared())
    {
        bConvertingSong = false;
        bProcessingSong = true;
        bDrawNeedsUpdate = true;
    }
#endif
    
    //cout << "size: " << audio_database->getSize() << endl;
}

// scrub memory using a cataRT display
// 2 dimensions... pca reprojection of the mfccs? kd-tree?

void app::drawInfo()
{
    
    ofSetColor(255, 255, 255, (float)(animationtime-animationCounter)/(animationtime/2.0f)*255.0f);
    small_bold_font.drawString("this app resynthesizes your sonic world", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("this app resynthesizes your sonic world") / 2.0, 95);
    small_bold_font.drawString("using the sound from your microphone and", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("using the sound from your microphone and") / 2.0, 125);
    small_bold_font.drawString("songs you teach it from your iTunes Library", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("songs you teach it from your iTunes Library") / 2.0, 155);
    
    small_bold_font.drawString("be sure to wear headphones", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("be sure to wear headphones") / 2.0, 215);
    small_bold_font.drawString("unless you like feedback", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("unless you like feedback") / 2.0, 245);
    
}


void app::drawCheckboxes()
{
	ofNoFill();
    ofSetColor(180, 140, 140);
	
	small_bold_font.drawString("syncopation", checkbox1_x, checkbox1_y + 45);
	
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
    
    small_bold_font.drawString("synthesis", slider0_x, slider0_y + 25);
    if(!bProcessingSong)
        small_bold_font.drawString("microphone", slider0_x + slider_width - small_bold_font.stringWidth("microphone"), slider0_y + 25);
    else
        small_bold_font.drawString("iTunes", slider0_x + slider_width - small_bold_font.stringWidth("iTunes"), slider0_y + 25);
    
    small_bold_font.drawString("0.0", slider1_x, slider1_y + 25);
    small_bold_font.drawString(ofToString(MAX_GRAIN_LENGTH, 1), slider1_x + slider_width - small_bold_font.stringWidth("5.0"), slider1_y + 25);
	
    small_bold_font.drawString("1", slider2_x, slider2_y + 25);
    small_bold_font.drawString(ofToString(maxVoices), slider2_x + slider_width - small_bold_font.stringWidth(ofToString(maxVoices)), slider2_y + 25);
	
    ofFill();
    ofSetColor(255, 255, 255);
    
    small_bold_font.drawString("mix", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("mix") / 2.0, slider0_y + 25);
    small_bold_font.drawString("grain size (s)", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("grain size (s)") / 2.0, slider1_y + 25);
    small_bold_font.drawString("number of voices", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("number of voices") / 2.0, slider2_y + 25);
    
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
    small_bold_font.drawString("erase my", button1_x + (button_width - small_bold_font.stringWidth("erase my")) / 2.0, button1_y + 0.45 * button_height);
    small_bold_font.drawString("memory", button1_x + (button_width - small_bold_font.stringWidth("memory")) / 2.0, button1_y + 0.75 * button_height);
    
    if(bProcessingSong)
    {
        small_bold_font.drawString("stop", button2_x + (button_width - small_bold_font.stringWidth("stop")) / 2.0, button2_y + 0.45 * button_height);
        small_bold_font.drawString("processing", button2_x + (button_width - small_bold_font.stringWidth("processing")) / 2.0, button2_y + 0.75 * button_height);
    }
    else
    {
        small_bold_font.drawString("use", button2_x + (button_width - small_bold_font.stringWidth("use")) / 2.0, button2_y + 0.45 * button_height);
        small_bold_font.drawString("iTunes", button2_x + (button_width - small_bold_font.stringWidth("a song")) / 2.0, button2_y + 0.75 * button_height);
    }
    
    if (bLearning) {
        small_bold_font.drawString("stop", button3_x + (button_width - small_bold_font.stringWidth("stop")) / 2.0, button3_y + 0.45 * button_height);
        small_bold_font.drawString("learning", button3_x + (button_width - small_bold_font.stringWidth("learning")) / 2.0, button3_y + 0.75 * button_height);
    }
    else {
        small_bold_font.drawString("start", button3_x + (button_width - small_bold_font.stringWidth("start")) / 2.0, button3_y + 0.45 * button_height);
        small_bold_font.drawString("learning", button3_x + (button_width - small_bold_font.stringWidth("learning")) / 2.0, button3_y + 0.75 * button_height);
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

    unsigned long numSamplesToRead = frame_size;
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
    ofSetColor(140, 180, 180, 60);
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
    
    
    ofBackground(0);
    ofSetColor(255);
    ofEnableAlphaBlending();
    
    bDrawNeedsUpdate = true;

    fbo3.begin();
    ofBackground(0);
    
    
    int s = audio_database->getSize();
    if ( s < 32 )
        ofSetColor(s/32.0 * 64.0);
    else
        ofSetColor(255);
    
    if(bDrawOptions)
    {
        drawOptions();
        fbo.draw(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        
    }
    else
    {
        drawInteractionScreen();
        fbo2.draw(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        
    }
    
    
    ofSetColor(180, 140, 140);
    
    string numData = string("size: ") + ofToString(audio_database->getSize());
    small_bold_font.drawString(numData,
                             SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth(numData) / 2.0,
                             70 * height_ratio);
    
    ofDisableAlphaBlending();

    
    
//    ofRect(0, 0, 50, 50);
//    ofCircle(25, 25, 25);
    
    ofEnableAlphaBlending();
    
    ofSetColor(180, 140, 140);
    buttonInfo.draw(SCREEN_WIDTH - button_height / 2.0 - 10, 10, button_height / 2.0, button_height / 2.0);
    drawWaveform();
    
    ofSetColor(240, 240, 240);
    large_bold_font.drawString("memory mosaic", SCREEN_WIDTH / 2.0 - large_bold_font.stringWidth("memory mosaic") / 2.0, 40 * height_ratio);
    
    drawHelp();
    
    if (bOutOfMemory) {
        ofSetColor(0, 0, 0, 180);
        ofFill();
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofNoFill();
        ofSetColor(255, 255, 255);
        small_bold_font.drawString("No more free memory for learning", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("No more free memory for learning") / 2.0, 290 * height_ratio);
    }
    
    else if (bConvertingSong) {
        ofSetColor(0, 0, 0, 180);
        ofFill();
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofNoFill();
        ofSetColor(255, 255, 255);
        small_bold_font.drawString("Converting song for processing...", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("Converting song for processing...") / 2.0, 160 * height_ratio);
    }
    
    else if(bWaitingForUserToPickSong) {
        ofSetColor(0, 0, 0, 60);
        ofFill();
        ofRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ofNoFill();
        ofSetColor(255, 255, 255);
        small_bold_font.drawString("Loading iTunes Library...", SCREEN_WIDTH / 2.0 - small_bold_font.stringWidth("Loading iTunes Library...") / 2.0, 160 * height_ratio);
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
    
//    ofRect(0, 0, SCREEN_WIDTH*scale_factor, SCREEN_HEIGHT*scale_factor);
    
    fbo3.end();
    
    fbo3.draw(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
//    cout << "w: " << SCREEN_WIDTH << " h: " << SCREEN_HEIGHT << endl;

}

//--------------------------------------------------------------
void app::drawInteractionScreen() {
    
    if (bDrawNeedsUpdate)
    {
        if (bDetectedOnset)
            audio_database->updateScreenMapping();
        
        fbo2.begin();
        ofBackground(0);
        ofEnableAlphaBlending();
        ofSetColor(255);
        
        audio_database->drawDatabase(SCREEN_WIDTH, SCREEN_HEIGHT);
        
        ofDisableAlphaBlending();
        
        buttonMenuSliders.draw(10, 10, button_height / 2, button_height / 2);
        
        fbo2.end();
        bDrawNeedsUpdate = false;
    }
    
    
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
            
            ofFill();
            ofSetColor(255, 255, 255);
            string str = "Each circle represents a learned sound fragment.";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 - 65 );
            str = "Touch anywhere on the screen";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 - 35);
            str = "to interactively play back the sounds.";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 - 5);
            
            str = "Or go back to the previous screen";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 + 65);
            str = "to learn more sounds.";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, SCREEN_HEIGHT / 2.0 + 95);
            
        }
        
    }
    else
    {
        if(bDrawHelp == 1)
        {
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  0, SCREEN_WIDTH, slider0_y - 25);
            ofSetColor(255);
            string str = "This slider controls the mix between";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y - 75);
            str = "the automatically created synthesis";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y - 55);
            str = "and the input (microphone or ITunes)";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y - 35);
            
            ofLine(button2_x + button_width / 2, slider0_y, SCREEN_WIDTH/2, slider0_y - 15);
            
            //                str = "of either the microphone or a song.";
            //                info_font.drawString(str, SCREEN_WIDTH/2 - info_font.stringWidth(str) / 2, slider0_y + 35);
            
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  slider2_y + 45, SCREEN_WIDTH, 95);
            ofSetColor(255);
            str = "This slider controls the how many sounds";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider2_y + 65);
            str = "to try to synthesize the input sound";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider2_y + 85);
            ofLine(button2_x + button_width / 2, slider2_y + 30, SCREEN_WIDTH/2, slider2_y + 45);
            
            small_bold_font.drawString("1 of 3", SCREEN_WIDTH - 55, SCREEN_HEIGHT - 10);
            
        }
        else if(bDrawHelp == 2) {
            
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  0, SCREEN_WIDTH, button1_y - 10);
            ofSetColor(255);
            
            string str = "When learning is on, any new";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y - 45);
            str = "interesting sounds from the input are";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y - 25);
            str = "stored and represented by a new circle.";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y - 5);
            str = "These sound segments are used for synthesis.";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y + 15);
            
            ofLine(button3_x + 30 + button_width, slider0_y - 10,
                   button3_x + 40 + button_width, slider0_y - 10);
            ofLine(button3_x + 40 + button_width, slider0_y - 10,
                   button3_x + 40 + button_width, button3_y + button_height / 2);
            ofLine(button3_x + 40 + button_width, button3_y + button_height / 2,
                   button3_x + button_width, button3_y + button_height / 2);
            
            
            
            str = "Erasing the memory removes any learned segments";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y + 60);
            ofLine(button1_x - 35, slider0_y + 55,
                   button1_x - 20, slider0_y + 55);
            ofLine(button1_x - 35, slider0_y + 55,
                   button1_x - 35, button1_y + button_height / 2);
            ofLine(button1_x - 35, button1_y + button_height / 2,
                   button1_x - 10, button1_y + button_height / 2);
            
            
            str = "You can also pick a song from your ITunes Library";
            small_bold_font.drawString(str, SCREEN_WIDTH/2 - small_bold_font.stringWidth(str) / 2, slider0_y + 115);
            ofLine(button2_x + button_width / 2, button2_y, SCREEN_WIDTH/2, slider0_y + 125);
            
            
            small_bold_font.drawString("2 of 3", SCREEN_WIDTH - 55, SCREEN_HEIGHT - 10);
            
        }
        else if(bDrawHelp == 3) {
            
            ofSetColor(0, 0, 0, 240);
            ofRect(0,  0, SCREEN_WIDTH, SCREEN_HEIGHT);
            ofSetColor(255);
            
            string str = "After learning a few sounds, you can also";
            small_bold_font.drawString(str, SCREEN_WIDTH / 2 - small_bold_font.stringWidth(str) / 2, slider0_y);
            str = "interactively play them with your touchscreen";
            small_bold_font.drawString(str, SCREEN_WIDTH / 2 - small_bold_font.stringWidth(str) / 2, slider0_y + 20);
            
            ofLine(10 + button_height / 4, 10 + button_height, 10 + button_height / 4, slider0_y + 10);
            ofLine(30 + button_height / 4, slider0_y + 10, 10 + button_height / 4, slider0_y + 10);
            
            buttonScreenInteraction.draw(10, 10, button_height / 2, button_height / 2);
            
            small_bold_font.drawString("3 of 3", SCREEN_WIDTH - 55, SCREEN_HEIGHT - 10);
        }
    }
}


//--------------------------------------------------------------
void app::drawOptions()
{
    if (bDrawNeedsUpdate) {
        
        fbo.begin();
        ofBackground(0);
        ofEnableAlphaBlending();
//        ofPushMatrix();
//        ofTranslate(-7, 0, 0);
//        ofPopMatrix();
        ofFill();
        ofSetColor(255);
        
		drawButtons();
		drawSliders();
        
        buttonScreenInteraction.draw(10, 10, button_height / 2, button_height / 2);
        
        ofDisableAlphaBlending();
        fbo.end();
        
        bDrawNeedsUpdate = false;
    }
    

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
    if(bufferSize < frame_size && bufferSize > 0)
    {
        cout << "[WARNING]!!! Frame size changed!!! Not sure how this shit will work now..." << endl;
        cout << "frame_size: " << bufferSize << endl;
        ring_buffer->setFrameSize(bufferSize);
        spectral_flux->setFrameSize(bufferSize);
        itunes_stream.setFrameSize(bufferSize);
        
        current_segment = pkm::Mat(SAMPLE_RATE / frame_size * 5, bufferSize, true);
        current_itunes_segment = pkm::Mat(SAMPLE_RATE / frame_size * 5, bufferSize, true);
        
        frame_size = bufferSize;
    }
    
    bSemaphore = true;
    vector<ofPtr<pkmAudioSegment> >::iterator it;
    
    vDSP_vclr(output_mono, 1, bufferSize);
    vDSP_vclr(buffer, 1, bufferSize);
    
    // if we detected a segment
    if((!bInteractiveMode && bDetectedOnset) ||
       bInteractiveMode)
    {
        // find matches
        vector<ofPtr<pkmAudioSegment> > newSegments;
        if (bInteractiveMode)
        {
            for (int i = 0; i < 2; i++) {

                if(bTouching[i])
                {
                    vector<ofPtr<pkmAudioSegment> > this_segments = audio_database->selectFromDatabase(touchX[i], touchY[i], SCREEN_WIDTH, SCREEN_HEIGHT);
                    for (vector<ofPtr<pkmAudioSegment> >::iterator it = this_segments.begin(); it != this_segments.end(); it++) {
                        newSegments.push_back(*it);
                    }
                    bTouching[i] = false;
                }
                else if(bUntouched[i])
                {
                    audio_database->unSelectFromDatabase(touchX[i], touchY[i], SCREEN_WIDTH, SCREEN_HEIGHT);
                    bUntouched[i] = false;
                }
            }
        }
        else
            newSegments = audio_database->getNearestAudioSegments(foreground_features);

        int totalSegments = newSegments.size() + nearest_audio_segments.size();
        
        // if we are syncopated, we force fade out of old segments
        if (bSyncopated) {
            it = nearest_audio_segments.begin();
            while( it != nearest_audio_segments.end() )
            {
                
                //printf("frame: %d\n", ((*it)->onset + (*it)->frame*frame_size) / frame_size);
                // get frame
#ifdef DO_FILEBASED_SEGMENTS
                pkmEXTAudioFileReader reader;
                reader.open(ofToDataPath((*it)->filename), sampleRate);
                long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frame_size;
                reader.read(buffer,
                            sampleStart,
                            (long)frame_size,
                            sampleRate);
                reader.close();
#else
                cblas_scopy(frame_size, (*it)->buffer + (*it)->frame*frame_size, 1, buffer, 1);
#endif
                //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frame_size);
                (*it)->bNeedsReset = false;
                (*it)->bPlaying = false;
                (*it)->frame = 0;
                it++;
                
#ifdef DO_REALTIME_FADING
                // mix in
                //vDSP_vsmul(buffer, 1, &level, buffer, 1, fadeLength);
                // fade out
                vDSP_vmul(buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
#endif
                vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frame_size);
                
            }
            
            nearest_audio_segments.clear();
        }
        // otherwise we playback old nearest neighbors as normal
        else
        {
            vector<ofPtr<pkmAudioSegment> >::iterator it = nearest_audio_segments.begin();
            while(it != nearest_audio_segments.end())
            {
                // get frame
#ifdef DO_FILEBASED_SEGMENTS
                pkmEXTAudioFileReader reader;
                reader.open(ofToDataPath((*it)->filename), sampleRate);
                long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frame_size;
                reader.read(buffer,
                            sampleStart,
                            (long)frame_size,
                            sampleRate);
                reader.close();
#else
                cblas_scopy(frame_size, (*it)->buffer + (*it)->frame*frame_size, 1, buffer, 1);
#endif
                //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frame_size);
                (*it)->frame++;
                
                // mix in
                //vDSP_vsmul(buffer, 1, &level, buffer, 1, frame_size);
                
                if (((*it)->onset + (*it)->frame*frame_size) >= (*it)->offset ||
                    (*it)->bNeedsReset)
                {
#ifdef DO_REALTIME_FADING
                    // fade out
                    vDSP_vmul(buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutBuffer, 1,
                              buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutLength);
#endif
                    (*it)->bNeedsReset = false;
                    (*it)->bPlaying = false;
                    (*it)->frame = 0;
                    it = nearest_audio_segments.erase(it);
                }
                else if((*it)->bNeedsReset)
                {
                    // fade out
                    vDSP_vmul(buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutBuffer, 1,
                              buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                              pkmAudioWindow::rampOutLength);
                    (*it)->frame = 0;
                    (*it)->bNeedsReset = false;
                    it++;
                }
                else
                    it++;
                
                vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frame_size);
            }
        }
        
        totalSegments = nearest_audio_segments.size();
        
        // fade in new segments and store them for next frame
        it = newSegments.begin();
        while( it != newSegments.end() )
        {
            if (random() % 2)
            {
    #ifdef DO_FILEBASED_SEGMENTS
                pkmEXTAudioFileReader reader;
                reader.open(ofToDataPath((*it)->filename), sampleRate);
                long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frame_size;
                reader.read(buffer,
                            sampleStart,  // should be 0...
                            (long)frame_size,
                            sampleRate);
                reader.close();
    #else
                cblas_scopy(frame_size, (*it)->buffer + (*it)->frame*frame_size, 1, buffer, 1);
                
    //            cout << (*it)->index << endl;
                
                //audio_database->featureDatabase.printAbbrev();
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
            }
            // check if segment is ready for fade out, i.e. segment is only "frame_size" samples
            if (((*it)->onset + (*it)->frame*frame_size) >= (*it)->offset ||
                (*it)->bNeedsReset)
            {
#ifdef DO_REALTIME_FADING
                // fade out
                vDSP_vmul(buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
#endif
                (*it)->bNeedsReset = false;
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
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frame_size);
        }
        
        // store new segments
        nearest_audio_segments.insert(nearest_audio_segments.end(), newSegments.begin(), newSegments.end());
        
    }
    // no onset, continue playback of old nearest neighbors
    else
    {
        // loop through all previous neighbors
        vector<ofPtr<pkmAudioSegment> >::iterator it = nearest_audio_segments.begin();
        while(it != nearest_audio_segments.end())
        {
#ifdef DO_FILEBASED_SEGMENTS
            // get audio frame
            pkmEXTAudioFileReader reader;
            reader.open(ofToDataPath((*it)->filename), sampleRate);
            long sampleStart = (long)(*it)->onset + (long)(*it)->frame*frame_size;
            reader.read(buffer,
                        sampleStart,
                        (long)frame_size,
                        sampleRate);
            reader.close();
#else
            cblas_scopy(frame_size, (*it)->buffer + (*it)->frame*frame_size, 1, buffer, 1);
#endif
            //printf("%s: %ld, %ld\n", (*it)->filename.c_str(), sampleStart, (long)frame_size);
            
            if((*it)->frame == 0)
            {
#ifdef DO_REALTIME_FADING
                // fade in
                vDSP_vmul(buffer, 1,
                          pkmAudioWindow::rampInBuffer, 1,
                          buffer, 1,
                          pkmAudioWindow::rampInLength);
#endif
            }
            
            (*it)->frame++;
            
            // finished playing audio segment?
            if ((*it)->onset + (*it)->frame*frame_size  >= (*it)->offset ||
                (*it)->bNeedsReset)
            {
#ifdef DO_REALTIME_FADING
                // fade out
                vDSP_vmul(buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
#endif
                (*it)->bNeedsReset = false;
                (*it)->bPlaying = false;
                (*it)->frame = 0;
                it = nearest_audio_segments.erase(it);
            }
            
            else if((*it)->bNeedsReset)
            {
                // fade out
                vDSP_vmul(buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutBuffer, 1,
                          buffer + frame_size - pkmAudioWindow::rampOutLength, 1,
                          pkmAudioWindow::rampOutLength);
                (*it)->frame = 0;
                (*it)->bNeedsReset = false;
                it++;
            }
            
            // no, keep it for next frame
            else
                it++;
            
            // mix in
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frame_size);
        }
    }
    
    
    // mix in input
    if (!bInteractiveMode) {
        if(bProcessingSong)
        {
            vDSP_vsmul(itunes_frame, 1, &slider0_position, buffer, 1, frame_size);
            float mixR = 1.0f - slider0_position;
            vDSP_vsmul(output_mono, 1, &mixR, output_mono, 1, frame_size);
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frame_size);
        }
        else
        {
            vDSP_vsmul(current_frame, 1, &slider0_position, buffer, 1, frame_size);
            float mixR = 1.0f - slider0_position;
            vDSP_vsmul(output_mono, 1, &mixR, output_mono, 1, frame_size);
            vDSP_vadd(buffer, 1, output_mono, 1, output_mono, 1, frame_size);
        }
    }
    
	
#ifdef DO_RECORD
	audioInputFileWriter.write(current_frame, output_frame*frame_size, frame_size);
	audioOutputFileWriter.write(output_mono, output_frame*frame_size, frame_size);
	output_frame++;
#endif
    
    for (int i = 0; i < frame_size; i++)
    {
        output_mono[i] = compressor.compressor(output_mono[i], 0.65, 0.75, 1.0, 0.995);
    }
    
    float neg = -1.0f, pos = 1.0f;
    
    vDSP_vclip(output_mono, 1, &neg, &pos, output_mono, 1, frame_size);
	
	// mix to stereo
    cblas_scopy(frame_size, output_mono, 1, output, 2);
    cblas_scopy(frame_size, output_mono, 1, output+1, 2);
    
    bSemaphore = false;
}

void app::processITunesInputFrame()
{
    // check for max segment
    bool bMaxSegmentReached = current_itunes_segment.isCircularInsertionFull();
    
    // parse segment
    if(bDetectedOnset || bMaxSegmentReached)
    {
        int segment_frame_nums = bMaxSegmentReached ? current_itunes_segment.rows : current_itunes_segment.current_row;
        
        pkm::Mat croppedFeature(segment_frame_nums, numFeatures, current_itunes_segment_features.data, false);
        pkm::Mat meanFeature = croppedFeature.mean();
        //meanFeature.print();
        if (true)//audio_database->bShouldAddSegment(meanFeature.data))
        {
            currentFile++;
#ifndef DO_REALTIME_FADING
            // fade in
            vDSP_vmul(current_itunes_segment.data, 1,
                      pkmAudioWindow::rampInBuffer, 1,
                      current_itunes_segment.data, 1,
                      pkmAudioWindow::rampInLength);
            // fade out
            vDSP_vmul(current_itunes_segment.data + segment_frame_nums * frame_size - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutBuffer, 1,
                      current_itunes_segment.data + segment_frame_nums * frame_size - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutLength);
#endif
            
#ifdef DO_FILEBASED_SEGMENTS
            pkmEXTAudioFileWriter writer;
            char buf[256];
            sprintf(buf, "%saudiofile_%08d.wav", documentsDirectory.c_str(), currentFile);
            if(!writer.open(ofToDataPath(buf), frame_size, sampleRate))
            {
                printf("[ERROR] Could not write file!\n");
                OF_EXIT_APP(0);
            }
            writer.write(current_itunes_segment.data, 0, segment_frame_nums * frame_size);
            writer.close();
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(buf,
                                                                      0,
                                                                      segment_frame_nums * frame_size,
                                                                      currentFile ) );
#else
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(current_itunes_segment.data,
                                                                      0,
                                                                      segment_frame_nums * frame_size,
                                                                      currentFile ) );
#endif
            //            audio_database->addAudioSequence(audio_segment, current_itunes_segment_features);
            //            audio_database->addAudioSegment(audio_segment, current_itunes_segment_features.data, numFeatures);
//            audio_database->addAudioSegment(audio_segment, meanFeature.data, numFeatures);
            audio_database->addAudioSegment(audio_segment, croppedFeature.row(0), numFeatures);
            audio_database->buildIndex();
            
            //            logMemUsage();
            //            if (audio_database->featureDatabase.rows > 5) {
            //                pkmAudioFeatureNormalizer::normalizeDatabase(audio_database->featureDatabase);
            //            }
        }
        
        current_itunes_segment.resetCircularRowCounter();
        current_itunes_segment_features.resetCircularRowCounter();
        
        bDrawNeedsUpdate = true;
    }
}



void app::processInputFrame()
{
    // check for max segment
    bool bMaxSegmentReached = current_segment.isCircularInsertionFull();
    
    // parse segment
    if(bDetectedOnset || bMaxSegmentReached)
    {
        int segment_frame_nums = bMaxSegmentReached ? current_segment.rows : current_segment.current_row;
        
        pkm::Mat croppedFeature(segment_frame_nums, numFeatures, current_segment_features.data, false);
        pkm::Mat meanFeature = croppedFeature.mean();
        //meanFeature.print();
        if (true)//audio_database->bShouldAddSegment(meanFeature.data))
        {
            currentFile++;
#ifndef DO_REALTIME_FADING
            // fade in
            vDSP_vmul(current_segment.data, 1,
                      pkmAudioWindow::rampInBuffer, 1,
                      current_segment.data, 1,
                      pkmAudioWindow::rampInLength);
            // fade out
            vDSP_vmul(current_segment.data + segment_frame_nums * frame_size - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutBuffer, 1,
                      current_segment.data + segment_frame_nums * frame_size - pkmAudioWindow::rampOutLength, 1,
                      pkmAudioWindow::rampOutLength);
#endif
            
#ifdef DO_FILEBASED_SEGMENTS
            pkmEXTAudioFileWriter writer;
            char buf[256];
            sprintf(buf, "%saudiofile_%08d.wav", documentsDirectory.c_str(), currentFile);
            if(!writer.open(ofToDataPath(buf), frame_size, sampleRate))
            {
                printf("[ERROR] Could not write file!\n");
                OF_EXIT_APP(0);
            }
            writer.write(current_segment.data, 0, segment_frame_nums * frame_size);
            writer.close();
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(buf,
                                                                      0,
                                                                      segment_frame_nums * frame_size,
                                                                      currentFile ) );
#else
            ofPtr<pkmAudioSegment> audio_segment( new pkmAudioSegment(current_segment.data,
                                                                      0,
                                                                      segment_frame_nums * frame_size,
                                                                      currentFile ) );
#endif
//            audio_database->addAudioSequence(audio_segment, current_segment_features);
//            audio_database->addAudioSegment(audio_segment, current_segment_features.data, numFeatures);
//            audio_database->addAudioSegment(audio_segment, meanFeature.data, numFeatures);
            audio_database->addAudioSegment(audio_segment, croppedFeature.row(0), numFeatures);
            audio_database->buildIndex();
            
            //            logMemUsage();
            //            if (audio_database->featureDatabase.rows > 5) {
            //                pkmAudioFeatureNormalizer::normalizeDatabase(audio_database->featureDatabase);
            //            }
        }
        
        current_segment.resetCircularRowCounter();
        current_segment_features.resetCircularRowCounter();
        
        bDrawNeedsUpdate = true;
    }
}


//--------------------------------------------------------------
void app::audioIn(float * buf, int size,
                  int ch)
{
    if(size < frame_size && size > 0)
    {
        cout << "[WARNING]!!! Frame size changed!!! Not sure how this shit will work now..." << endl;
        cout << "frame_size: " << size << endl;
        ring_buffer->setFrameSize(size);
        spectral_flux->setFrameSize(size);
        itunes_stream.setFrameSize(size);
        
        
        current_segment = pkm::Mat(SAMPLE_RATE / frame_size * 5, size, true);
        current_itunes_segment = pkm::Mat(SAMPLE_RATE / frame_size * 5, size, true);
        
        frame_size = size;
    }
//    vDSP_vclr(buf, 1, size*ch);
    
    if (animationCounter < animationtime || bInteractiveMode) {
        vDSP_vclr(buf, 1, size*ch);
        return;
    }
    
    if (!bOutOfMemory && bProcessingSong)
    {

        if(!itunes_stream.getNextBuffer(itunes_frame))
            bProcessingSong = false;
        
//        for (int i = 0; i < size * ch; i++)
//        {
//            itunes_frame[i] = compressorInput.compressor(itunes_frame[i], 1.0, 1.0, 0.1, 0.4);
//        }

        ring_buffer->insertFrame(itunes_frame);

        if (ring_buffer->isRecorded())
        {
            ring_buffer->copyAlignedData(aligned_frame);
        
            // get audio features
//            audio_feature->compute36DimAudioFeaturesF(aligned_frame, foreground_features);
//            audio_feature->computeLFCCF(aligned_frame, foreground_features, numFeatures);
            audio_feature->compute24DimAudioFeaturesF(aligned_frame, foreground_features);
//            dct.dctII_1D(aligned_frame, foreground_features, numFeatures);
            
            // check for onset
            bDetectedOnset = spectral_flux->detectOnset(audio_feature->getMagnitudes(), audio_feature->getMagnitudesLength());
        }
        
        if(bDetectedOnset)
        {
//            audio_database->buildScreenMapping();
            segmentationCounter = 0;
        }
        
        if (bLearning)
        {
            processITunesInputFrame();
        }
        else
        {
            current_itunes_segment.resetCircularRowCounter();
            current_itunes_segment_features.resetCircularRowCounter();
        }
        // ring buffer for current segment
        current_itunes_segment.insertRowCircularly(itunes_frame);
        
        // ring buffer for audio features
        current_itunes_segment_features.insertRowCircularly(foreground_features);
        //        }
    }
    else
    {
        cblas_scopy(size, buf, ch, current_frame, 1);
        
//        for (int i = 0; i < size * ch; i++)
//        {
//            current_frame[i] = compressorInput.compressor(current_frame[i], 1.0, 1.0, 0.1, 0.4);
//        }

        
        ring_buffer->insertFrame(current_frame);

        if (ring_buffer->isRecorded())
        {
            ring_buffer->copyAlignedData(aligned_frame);
        
            // get audio features
            //            audio_feature->compute36DimAudioFeaturesF(aligned_frame, foreground_features);
            //audio_feature->computeLFCCF(aligned_frame, foreground_features, numFeatures);
            audio_feature->compute24DimAudioFeaturesF(aligned_frame, foreground_features);
//            dct.dctII_1D(aligned_frame, foreground_features, numFeatures);
            
            // check for onset
            bDetectedOnset = spectral_flux->detectOnset(audio_feature->getMagnitudes(), audio_feature->getMagnitudesLength());
        }
        
        if(bDetectedOnset)
        {
//            audio_database->buildScreenMapping();
            segmentationCounter = 0;
        }
        
        if (bLearning)
        {
            processInputFrame();
        }
        else
        {
            current_segment.resetCircularRowCounter();
            current_segment_features.resetCircularRowCounter();
        }
        
        // ring buffer for current segment
        current_segment.insertRowCircularly(current_frame);
        
        // ring buffer for audio features
        current_segment_features.insertRowCircularly(foreground_features);

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
        bTouching[touch.id] = true;
        bUntouched[touch.id] = false;
        touchX[touch.id] = touch.x;
        touchY[touch.id] = touch.y;
        bDrawNeedsUpdate = true;
    }
    else if (bDrawOptions){
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
        
        bTouching[touch.id] = true;
        touchX[touch.id] = touch.x;
        touchY[touch.id] = touch.y;
        bDrawNeedsUpdate = true;
        
    }
    else if (bDrawOptions){
        
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
//            spectral_flux->setOnsetThreshold((1.0f-slider1_position)*1.0f + 0.01f);
            spectral_flux->setMinSegmentLength(MAX_GRAIN_LENGTH * sampleRate / (float)frame_size * (float)slider1_position);  // half second
                bDrawNeedsUpdate = true;
                bMovingSlider0 = false;
                bMovingSlider1 = true;
                bMovingSlider2 = false;
            }
            else if(bMovingSlider2)
            {
                slider2_position = MIN(1.0, MAX(0.0, (touch.x - slider2_x) / (float)slider_width));
                audio_database->setK(round(slider2_position*maxVoices));
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
    
    bTouching[touch.id] = false;
    bUntouched[touch.id] = true;

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
    else if (touch.x < 50 && touch.y < 50) {
        bDrawOptions = !bDrawOptions;
        bInteractiveMode = !bDrawOptions;
        bSyncopated = false;
        
        bDrawNeedsUpdate = true;
        
        audio_database->buildScreenMapping();
        
        touchX[touch.id] = touch.x;
        touchY[touch.id] = touch.y;
        
    }
//    else if(touch.x < 100 && touch.y < 50) {
//        bInteractiveMode = !bInteractiveMode;
//
//        bTouching = bInteractiveMode;
//        bSyncopated = bInteractiveMode;
//        bDrawNeedsUpdate = true;
//
//        touchX = touch.x;
//        touchY = touch.y;
//        
//    }
    else if (bDrawOptions){
        if(!bConvertingSong && !bWaitingForUserToPickSong && !bOutOfMemory)
        {
//            if (audio_database->getSize() > 32) {
//                if (touch.x < 50 && touch.y < 50) {
//                    audio_database->buildScreenMapping();
//                    bTouching = false;
//                    bInteractiveMode = true;
//                    bDrawNeedsUpdate = true;
//                    bSyncopated = true;
//                    return;
//                }
//            }
            
            //printf("Checking buttons\n");
            if (within<int>(touch.x, touch.y, button1_x, button1_y, button_width, button_height)) {
                //printf("Button 1 pressed\n");
                audio_database->resetDatabase();
                
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
                    itunes_stream.pickSong();
                    bWaitingForUserToPickSong = true;
                }
            }
            else if(within<int>(touch.x, touch.y, button3_x, button3_y, button_width, button_height)) {
                //printf("Button 3 pressed\n");
                bLearning = !bLearning;
                
    //            if (!bLearning) {
    //                audio_database->featureDatabase.print();
    //                audio_database->buildScreenMapping();
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
                //            spectral_flux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
    //            spectral_flux->setMinSegmentLength(sampleRate / (float)frame_size * (float)slider1_position);  // half second
                bDrawNeedsUpdate = true;
            }
            else if(bMovingSlider2)
            {
                slider2_position = MIN(1.0, MAX(0.0, (touch.x - slider2_x) / (float)slider_width));
                audio_database->setK(round(slider2_position*maxVoices));
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
            audio_database->resetDatabase();
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
            //            spectral_flux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
//            spectral_flux->setMinSegmentLength(sampleRate / (float)frame_size * (float)slider1_position);  // half second
		}
		else if(within<int>(x, y, slider2_x, slider2_y-20, slider_width, 40))
		{
			slider2_position = (x - slider2_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
			audio_database->setK(slider2_position*15);
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
            //            spectral_flux->setOnsetThreshold((1.0f-slider1_position)*3.5f + 0.01f);
//            spectral_flux->setMinSegmentLength(sampleRate / (float)frame_size * (float)slider1_position);  // half second
        }
        else if(within<int>(x, y, slider2_x, slider2_y-20, slider_width, 40))
        {
            slider2_position = (x - slider2_x) / (float)slider_width;
            bDrawNeedsUpdate = true;
            audio_database->setK(slider2_position*6.0f);
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
