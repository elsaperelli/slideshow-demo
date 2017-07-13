//
//  OpenCVWrapper.mm
//  EmotionRecognizerDemo
//
//  Created by Berthy Feng on 6/16/17.
//  Copyright © 2017 Berthy Feng. All rights reserved.
//

#import "EmotionRecognizer.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <iostream>
#import <fstream>

#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/objdetect.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/face.hpp>
#include <opencv2/face/facerec.hpp>

using namespace std;
using namespace cv;
using namespace cv::face;

@implementation EmotionRecognizer

// constants
double   SCALE_FACTOR  = 1.05;
int      MIN_NEIGHBORS = 3;
cv::Size MIN_SIZE      = cv::Size(30, 30);
cv::Size IMG_SIZE      = cv::Size(350, 350);
NSArray  *emotions     = @[@"neutral", @"anger", @"disgust", @"happy", @"sadness", @"surprise"];

CascadeClassifier   faceCascade;
Ptr<FaceRecognizer> fishface;

// helper function to extract faces from given grayscale image
-(vector<cv::Rect>) extractFaces: (cv::Mat) gray
{
    vector<cv::Rect> faces;
    faceCascade.detectMultiScale(gray, faces, SCALE_FACTOR, MIN_NEIGHBORS, CV_HAAR_FIND_BIGGEST_OBJECT, MIN_SIZE);
    return faces;
}

// helper function to convert from UIImage to cv::Mat
// credit: http://bit.ly/2rRCAPb
-(cv::Mat) imageToMat: (UIImage *) image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpace);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4);  // 8 bits per component, 4 channels
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    
    // check whether the UIImage is grayscale already
    if (numberOfComponents == 1) {
        cvMat = cv::Mat(rows, cols, CV_8UC1);  // 8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    }
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, bitmapInfo);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

// run analysis on given number of frames
-(NSDictionary *) analyzeFrame: (UIImage *) image
{
    cv::Mat          frame;        // current frame
    cv::Mat          gray;         // grayscale version of current frame
    vector<cv::Rect> faces;        // faces detected in given frame
    cv::Rect         roi;          // region of interest surrounding face
    cv::Mat          resizedGray;  // resized grayscale frame
    
    int    emotion    = -1;   // estimated emotion
    double confidence = 0.0;  // confidence level of emotion estimate
    
    NSDictionary *estimate;  // result dictionary
    
    // convert to grayscale
    frame = [self imageToMat: image];
    cvtColor(frame, gray, CV_BGR2GRAY);
    
    // detect faces
    faces = [self extractFaces: gray];
    
    // no face detected
    if (faces.size() == 0) {
        estimate = @{@"emotion":@"no face detected", @"confidence":[NSNumber numberWithDouble:-1.0]};
        return estimate;
    }
    
    // take first face
    for (int i = 0; i < 1; i++) {
        // set fields of region of interest
        roi.x = faces[i].x;
        roi.y = faces[i].y;
        roi.width = faces[i].width;
        roi.height = faces[i].height;
        // isolate ROI
        gray = gray(roi);
        // resize
        resize(gray, resizedGray, IMG_SIZE);
    }
    
    // predict emotion and confidence level
    fishface->predict(resizedGray, emotion, confidence);
    estimate = @{@"emotion":emotions[emotion], @"confidence":[NSNumber numberWithDouble: confidence]};
    return estimate;
}

// set up classifier, recognizer, and webcam
// http://bit.ly/2tzlkjJ
-(void) setupAnalyzer:(NSString *)faceCascadeName :(NSString *)fisherDatasetName
{
    NSBundle * appBundle = [NSBundle mainBundle];
    NSString * fileType = @"xml";
    
    // load face classifier
    cout << "loading face classifier..." << endl;
    NSString * cascadePathInBundle = [appBundle pathForResource:faceCascadeName ofType:fileType];
    String cascadePath = string([cascadePathInBundle UTF8String]);
    faceCascade.load(cascadePath);
    
    // load face recognizer
    cout << "loading face recognizer..." << endl;
    NSString * datasetPathInBundle = [appBundle pathForResource:fisherDatasetName ofType:fileType];
    String fisherDatasetPath = string([datasetPathInBundle UTF8String]);
    fishface = createFisherFaceRecognizer();
    fishface -> load(fisherDatasetPath);
}

@end
