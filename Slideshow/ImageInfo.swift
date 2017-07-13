//
//  ImageInfo.swift
//  Slideshow
//
//  Stores the metadata associated with a given image.
//
//  Created by Berthy Feng on 6/27/17.
//  Copyright © 2017 Berthy Feng. All rights reserved.
//

import Foundation

public struct ImageInfo {
    public var imageName        : String       // name of image
    public var timeSpentViewing : TimeInterval // total time spent on this image
    public var numberOfTimesSeen: Int          // number of times image has been seen
    public var emotion          : String       // predominant emotion
    
    public init() {
        imageName = ""
        timeSpentViewing = 0.0
        numberOfTimesSeen = 0
        emotion = ""
    }
}
