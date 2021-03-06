/*
 *  app.h
 *  part of app
 *
 *  Created by Parag K Mital on 11/12/10.
 
 LICENCE
 
 app "The Software" © Parag K Mital, parag@pkmital.com
 
 The Software is and remains the property of Parag K Mital
 ("pkmital") The Licensee will ensure that the Copyright Notice set
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
 
 
 *
 */


#pragma once

#define TARGET_OF_IPHONE

//#define DO_RECORD
//#define DO_FILEINPUT
#define DO_REALTIME_FADING
//#define DO_FILEBASED_SEGMENTS
//#define DO_PLCA_SEPARATION

#include "ofMain.h"

#ifdef TARGET_OF_IPHONE
#include "ofxiOS.h"
#include "ofxiOSExtras.h"
#endif

#ifdef DO_PLCA_SEPARATION
#include "pkmPLCA.h"
#endif

//#include "ofxVectorMath.h"
//#include "ofxDirList.h"

#include <Accelerate/Accelerate.h>

#include "pkmEXTAudioFileReader.h"
#include "pkmEXTAudioFileWriter.h"
#include "pkmAudioSegmenter.h"
#include "pkmFFT.h"
#include "pkmAudioFile.h"
#include "pkmAudioFeatures.h"
#include "pkmAudioSegment.h"
#include "pkmAudioSegmentDatabase.h"
#include "pkmCircularRecorder.h"
#include "pkmAudioFeatureNormalizer.h"
#include "pkmAudioSpectralFlux.h"

#include "pkmDCT.h"

#ifdef TARGET_OF_IPHONE
#include "ofxiTunesLibraryStream.h"
#endif

#include "limiter.h"

#include "maximilian.h"
#include <string>
#include <vector>
#include <map>

using namespace std;

class app : public ofxiOSApp{
public:
    
    ~app                    ();
    
	void setup              ();
    void setupBuilding      ();
    void setupMatching      ();
    
	void update             ();
    
	void draw               ();
    void drawHelp           ();
	void drawInfo           ();
    void drawButtons        ();
    void drawWaveform       ();
    void drawSliders        ();
	void drawCheckboxes     ();
    
    void drawInteractionScreen();
    void drawOptions   ();
	
    void loadSong			();
	
#ifdef TARGET_OF_IPHONE
	void touchDown			(ofTouchEventArgs &touch);
	void touchMoved			(ofTouchEventArgs &touch);
	void touchUp			(ofTouchEventArgs &touch);
	void touchDoubleTap		(ofTouchEventArgs &touch);
	void touchCancelled		(ofTouchEventArgs &touch);
	//void exit             ();
	//void lostFocus        ();
	//void gotFocus         ();
	void gotMemoryWarning   ();
	void deviceOrientationChanged(int newOrientation)
    {
        if(ofxiOSGetGLView().frame.origin.x != 0
           || ofxiOSGetGLView().frame.size.width != [[UIScreen mainScreen] bounds].size.width){
            
            ofxiOSGetGLView().frame = CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width,[[UIScreen mainScreen] bounds].size.height);
        }
    }
#else
	void mouseDragged       (int x, int y, int button);
	void mousePressed       (int x, int y, int button);
	void mouseReleased      (int x, int y);
#endif
	
    void audioOut           (float *buf, int size, int ch);
    void audioIn            (float *buf, int size, int ch);
    void processInputFrame  ();
    void processITunesInputFrame();
    
    string                          documentsDirectory;
    string                          targetFilename;
    
#ifdef DO_RECORD
	pkmEXTAudioFileWriter           audioOutputFileWriter;
	pkmEXTAudioFileWriter           audioInputFileWriter;
#endif
    
#ifdef DO_FILEINPUT
	pkmEXTAudioFileReader           inputAudioFileReader;
    long                            inputAudioFileFrame;
#endif
    pkmCircularRecorder             *ring_buffer;
    float                           *aligned_frame;
    float                           *zeroFrame;
    int                             fftSize;
    
    int                             currentSampleNumber, frame_size, hopSize, frame, sampleRate, output_frame;
	float                           *current_frame, *itunes_frame, *buffer, *output_mono, *output;
    
	
    ofFbo                           fbo, fbo2, fbo3;
    ofImage                         background;
    ofImage                         button;
    
	ofDirectory                     dirList;
	int                             currentFile, numFiles;
	vector<ofFile>                  audioFiles;
    map<string, int>                audioLUT;
	
    ofTrueTypeFont                  large_bold_font;
    ofTrueTypeFont                  small_bold_font;
    ofTrueTypeFont                  info_font;
    
    float                           *foreground_features;
    int                             numFeatures;
	int								animationCounter, segmentationCounter;
    FILE *fp;
	pkmAudioSegmentDatabase         *audio_database;
    int                             current_num_features; // size of database
    pkmAudioSpectralFlux            *spectral_flux;
    pkmAudioSegment                 *audio_segment;
	pkmAudioFeatures                *audio_feature;
    pkmDCT                          dct;
    pkmAudioFeatureNormalizer       *audio_database_normalizer;
    vector<ofPtr<pkmAudioSegment> > nearest_audio_segments;
    
    pkm::Mat                        current_segment, current_itunes_segment;
    pkm::Mat                        current_segment_features, current_itunes_segment_features;
    
#ifdef DO_PLCA_SEPARATION
    pkmPLCA                         *plca;
    int                             foregroundComponents;
	int                             backgroundComponents;
	int                             foregroundIterations;
    int                             backgroundIterations;
#endif
    
    maxiDyn                         compressor;
	
    pkmEXTAudioFileReader           songReader;
#ifdef TARGET_OF_IPHONE
    ofxiTunesLibraryStream          itunes_stream;
#endif
    
    ofImage                         buttonMenuSliders, buttonScreenInteraction, buttonInfo;
    
    bool                            bWaitingForUserToPickSong,
                                    bConvertingSong,
                                    bLoadedSong,
                                    bProcessingSong;
    
    bool                            bMovingSlider0, bMovingSlider1, bMovingSlider2;
    
	bool                            bSetup,
                                    bPressed,
                                    bOutOfMemory,
                                    bLearning,
                                    bSyncopated,
                                    bCopiedBackground,
                                    bMatching,
                                    bVocoder,
                                    bRealTime,
                                    bSemaphore,
                                    bLearnedPLCABackground,
                                    bLearningInputForNormalization,
                                    bDrawNeedsUpdate,
                                    bDetectedOnset,
                                    bInteractiveMode,
                                    bDrawOptions;
    
    map<int, bool>                  bTouching, bUntouched;
    map<int, float>                 touchX, touchY;
    
    int                             bDrawHelp;
    
};

