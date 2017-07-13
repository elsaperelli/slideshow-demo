//
//  OpenCVWrapper.h
//  EmotionRecognizerDemo
//
//  Created by Berthy Feng on 6/16/17.
//  Copyright © 2017 Berthy Feng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

@interface EmotionRecognizer : NSObject { }

-(void) setupAnalyzer: (NSString*) faceCascadeName : (NSString*) fisherDatasetName;

-(NSDictionary *) analyzeFrame: (UIImage*) image;

@end
