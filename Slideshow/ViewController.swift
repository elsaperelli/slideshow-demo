//
//  ViewController.swift
//  Slideshow
//
//  Created by Berthy Feng on 6/27/17.
//  Copyright © 2017 Berthy Feng. All rights reserved.
//

import UIKit

class ViewController: UIViewController, EmotionRecognitionDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    // dictionaries and lists
    private var emotionValues: [String: Double]! // emotion to number
    private var imageNames   : [String]!         // names of images
    private var tags         : [[String]]!       // image to tags
    
    // stacks to track previous and next images
    private var backStack   : Stack<Int>! // previous images
    private var forwardStack: Stack<Int>! // next images

    // objects
    private var stopwatch         : Stopwatch!          // stopwatch to track elapsed time per image
    private var emotionRecognition: EmotionRecognition! // emotion recognition engine
    private var frameExtractor    : FrameExtractor!     // frame extractor
    
    // session information
    private let profile_id = 1                                                // profile id number
    private let token      = "Token b191fab4fb809c395b7dc347d7b23b90bcc16dd6" // authentication token
    
    // image-specific variables
    private var frameCount  : Int  = 0     // track number of frames for this image
    private var like        : Bool = false // has the image been liked?
    private var currentIndex: Int  = 0     // index of image
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fill dictionaries
        emotionValues = ["neutral": 0.0, "no face detected": 0.0, "happy": 1.0, "surprise": 0.5, "sadness": -1.0, "disgust": -1.0, "anger": -1.0]
        imageNames    = ["flowers", "people", "waves", "bread", "cat", "coffee", "frog", "milk", "raspberries", "surfer", "tree", "turtle", "baby", "cupcakes", "dog", "frogs", "spider"]
        tags          = [["nature", "flower"]]
        
        // initialize emotion recognition
        emotionRecognition = EmotionRecognition()
        emotionRecognition.delegate = self
        
        // initialize stacks
        backStack    = Stack<Int>()
        forwardStack = Stack<Int>()
        
        // initialize stopwatch
        stopwatch = Stopwatch()
        
        // set correct paths for images
        let bundle = Bundle.main
        for (index, filename) in imageNames.enumerated() {
            let path = bundle.path(forResource: filename, ofType: "jpg")
            imageNames[index] = path!
        }
        
        // start with image
        imageView.image = UIImage(named: imageNames[currentIndex])
    }
    
    // user has pressed the "like" button on this image
    @IBAction func like(_ sender: UIButton) {
        like = true
    }

    // user wants to see next image
    @IBAction func nextImage(_ sender: UIButton) {
        // process the image that was just seen
        let elapsedTime = stopwatch.elapsedTimeInterval()
        let emotion     = emotionRecognition.getPredominantEmotion()!
        
        // send image data
        updateImageInfo(elapsedTime: elapsedTime, emotion: emotion, index: currentIndex)
        
        like       = false   // reset like
        frameCount = 0       // reset frame count
        
        // get index of next image
        var nextIndex: Int
        // if forward stack is empty, get random index
        if (forwardStack.isEmpty) {
            nextIndex = Int(arc4random_uniform(UInt32(imageNames.count)))
            while (nextIndex == currentIndex) {
                nextIndex = Int(arc4random_uniform(UInt32(imageNames.count)))
            }
        }
        // else get index from forward stack
        else {
            nextIndex = forwardStack.pop()!
        }
        
        // reset
        stopwatch.reset()
        emotionRecognition.reset()
        
        // update imageView
        imageView.image = UIImage(named: imageNames[nextIndex])
        
        backStack.push(currentIndex)  // push on to back stack
        currentIndex = nextIndex      // update current index
    }
    
    // user wants to see previous image
    @IBAction func prevImage(_ sender: UIButton) {
        // process the image that was just seen
        let elapsedTime = stopwatch.elapsedTimeInterval()
        let emotion     = emotionRecognition.getPredominantEmotion()!
        
        // send image data
        updateImageInfo(elapsedTime: elapsedTime, emotion: emotion, index: currentIndex)
        
        like       = false  // reset like
        frameCount = 0      // reset frame count
        
        // get index
        if (backStack.isEmpty) { return }  // do nothing if back stack is empty
        let prevIndex = backStack.pop()    // get index from back stack
        
        // reset
        stopwatch.reset()
        emotionRecognition.reset()
        
        // update imageView
        imageView.image = UIImage(named: imageNames[prevIndex!])
        
        forwardStack.push(currentIndex)  // push on to forward stack
        currentIndex = prevIndex!        // update current index
    }
    
    // collect data associated with image and send to server
    func updateImageInfo(elapsedTime: TimeInterval, emotion: String, index: Int) {
        // set up dictionary
        var imageData: [String: Any]   = ["like": true, "emotion": emotionValues[emotion]!, "time": elapsedTime, "tags": ""]
        var tagData  : [[String: Any]] = []
        for tag in tags[index] {
            let newTagDict: [String: Any] = ["name": tag, "frames": frameCount]
            tagData.append(newTagDict)
        }
        imageData.updateValue(tagData, forKey: "tags")

        // serialize as JSON
        let json = try? JSONSerialization.data(withJSONObject: imageData, options: .prettyPrinted)
        
        print(String(data: json!, encoding: String.Encoding.utf8)!) // FOR DEBUGGING
        
        // create HTTP request
        var request = URLRequest(url: URL(string: String(format: "http://52.14.65.114/api/profiles/%d/image_session", profile_id))!)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = json
        
        // run task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "no data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        task.resume()
    }
    
    // receives new frame ping from EmotionRecognition
    func newFrame() {
        frameCount = frameCount + 1
    }
}
