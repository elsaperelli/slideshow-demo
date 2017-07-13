//
//  FrameExtractor.swift
//  EmotionRecognizerDemo
//
//  Accesses iOS device camera and processes frames to send to delegate(s).
//  MAJOR CREDS: http://bit.ly/2rS6AdV
//
//  Created by Berthy Feng on 6/20/17.
//  Copyright © 2017 Berthy Feng. All rights reserved.
//

import Foundation
import AVFoundation

protocol FrameExtractorDelegate: class {
    func captured(image: UIImage)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: FrameExtractorDelegate?
    
    private let FRAME_DROP_RATE = 30 // number of frames between each saved frame
    private let context = CIContext()
    private let captureSession = AVCaptureSession()
    private let sessionQueue   = DispatchQueue(label: "session queue")
    private let position = AVCaptureDevicePosition.front
    private let quality  = AVCaptureSessionPresetMedium
    
    private var permissionGranted = false
    private var counter = 0
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            // the user has previously granted access to camera
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            // the user has previously denied access
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        guard let captureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) else { return }
        
        // configure device input
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        
        // configure device output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        // configure orientation
        guard let connection = videoOutput.connection(withMediaType: AVFoundation.AVMediaTypeVideo) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
        
    }
    
    // convert from image sample buffer to UIImage
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        // transform sample buffer into a CVImageBuffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        // transform CVImageBuffer to a CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        // create a CGImage from CIContext
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        // transform CGImage to a UIImage
        return UIImage(cgImage: cgImage)
    }
    
    // call every time a new frame becomes available
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        counter = counter + 1
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        // save to photo album at specified rate
        /*if (counter == FRAME_DROP_RATE) {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil) // save to album
            counter = 0
        }*/
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(image: uiImage)
        }
    }
}
