//
//  EmotionRecognition.swift
//  Slideshow
//  
//  Receives frames from FrameExtractor and analyzes each frame for an emotion.
//  Returns predominant emotion for use in ViewController.
//  Sends emotion to ViewController whenever emotion changes.
//
//  Created by Berthy Feng on 6/27/17.
//  Copyright © 2017 Berthy Feng. All rights reserved.
//

import Foundation
import AVFoundation

protocol EmotionRecognitionDelegate: class {
    func newFrame()
}

public class EmotionRecognition: FrameExtractorDelegate {
    weak var delegate: EmotionRecognitionDelegate?
    
    private var emotionRecognizer: EmotionRecognizer!    // emotion recognizer
    private var frameExtractor   : FrameExtractor!       // frame extractor
    private var stopwatch        : Stopwatch!            // stopwatch
    private var analyzingFrame   : Bool                  // analysis thread running
    private var scores           : [String : Int] = [:]  // keeps score of each recognized emotion
    private var previousEmotion  : String         = ""   // previous emotion
    
    
    public init() {
        analyzingFrame = false
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        emotionRecognizer = EmotionRecognizer()
        emotionRecognizer.setupAnalyzer("haarcascade_frontalface_default", "fishface_ckplus")
    }
    
    // reset scores for new image
    public func reset() {
        scores.removeAll()
    }
    
    
    // returns the emotion with the highest score
    public func getPredominantEmotion() -> String? {
        for (emotion, score) in scores {
            if (score == scores.values.max()) {
                return emotion
            }
        }
        return nil
    }
    
    
    // receives frames from FrameExtractor and analyzes each frame
    internal func captured(image: UIImage) {
        var info       = [AnyHashable : Any]() // [emotion : confidence]
        var emotion    = ""
        var confidence = 0
        
        // ping delegate with new frame
        self.delegate?.newFrame()
        
        // start new thread
        if (!analyzingFrame) {
            analyzingFrame = true
            DispatchQueue.main.async {
                info       = (self.emotionRecognizer.analyzeFrame(image)! as [AnyHashable : Any]?)!
                emotion    = (info["emotion"] as? String)!
                confidence = (info["confidence"] as? Int)!
                
                /*
                 * TO TRACK TIMELINE OF EMOTIONS, THIS METHOD SENDS EMOTION TO DELEGATE FUNCTION IF EMOTION HAS CHANGED
                 *
                if (emotion != self.previousEmotion) {
                    self.delegate?.emotionChange(differentEmotion: emotion)
                    self.previousEmotion = emotion
                }
                 *
                 *
                 */
                
                // update score
                if (self.scores[emotion] == nil) {
                    self.scores.updateValue(confidence, forKey: emotion)
                }
                else {
                    let previousScore = self.scores[emotion]
                    self.scores.updateValue(previousScore! + confidence, forKey: emotion)
                }
                
                // allow new thread to start
                self.analyzingFrame = false
            }
        }
    }
}
