//
//  ViewController.swift
//  FacialEmotionDetection
//
//  Created by Joshua Newnham on 26/02/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {

    /**
     Reference to our views CapturePreviewView (Camera stream)
    */
    @IBOutlet weak var previewView: CapturePreviewView!
    
    /**
     Reference to our view responsible for displaying the current users emotion
    */    
    @IBOutlet weak var viewVisualizer: EmotionVisualizerView!
    
    /*
     Label notifying the user no face was detected (prompting them to face the camera towards their, or someone elses, face.
    */
    @IBOutlet weak var statusLabel: UILabel!
    
    /**
     Utility class that encapsulates setting up and tearing down the video capture; we'll start recording
     and assign the ViewController as a delegate to receive captured images from the video stream.
     */
    let videoCapture : VideoCapture = VideoCapture()
    
    /**
     Utility class encapsulating methods for data pre-processing
    */
    let imageProcessor : ImageProcessor = ImageProcessor()
    
    let model = ExpressionRecognitionModelRaw()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoCapture.delegate = self
        
        videoCapture.asyncInit { (success) in
            if success{
                // Assign the capture session instance being previewed
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
                // You use the videoGravity property to influence how content is viewed relative to the layer bounds;
                // in this case setting it to full the screen while respecting the aspect ratio.
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
                
                self.videoCapture.startCapturing()
            } else{
                fatalError("Failed to init VideoCapture")
            }
        }
        
        imageProcessor.delegate = self
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer:CVPixelBuffer?, timestamp:CMTime){
        // Unwrap the parameter pixxelBuffer; exit early if nil
        guard let pixelBuffer = pixelBuffer else{
            print("WARNING: onFrameCaptured; null pixelBuffer")
            return
        }
        
        // extract faces
        self.imageProcessor.getFaces(
            pixelBuffer: pixelBuffer)
    }
}

// MARK: - VisionRequest callback

extension ViewController{
    
    func onVisionRequestComplete(request: VNRequest, error: Error?) {
        /*
         A request can be given a hander which is called once
         the inference has been performed; the resutls is of type VNRequest
         and includes a results variable including ... the results of the
         inference - if no error has occured.
         
         The results, in our case, are observations (array of VNClassificationObservation); this datatype is returned by VNCoreMLRequests that are using a model performing
         classification (like our expression recognition model).
         */
        guard let observations = request.results as? [VNClassificationObservation] else{ return }
        
        /*
         Each observation consists of a label and confidence level;
         observations are sorted by confidence - let's map these to a dictionary
         and pass them to the visualizer.
         */
        let emotions = observations.reduce([String:Float]()) { (result, observation) -> [String:Float] in
            var result = result
            result[observation.identifier] = observation.confidence
            return result
        }
        
        print("-------")
        for (k,v) in emotions{
            print("\(k) \(v)")
        }
        
//        DispatchQueue.main.sync {
//            viewVisualizer.update(labelConference: emotions)
//        }
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController : ImageProcessorDelegate{
    
    func onImageProcessorCompleted(status: Int, faces:[MLMultiArray]?){
        guard let faces = faces else{ return }
        
        self.statusLabel.isHidden = faces.count > 0
        
        guard faces.count > 0 else{
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            for faceData in faces{

                let prediction = try? self.model.prediction(image: faceData)

                if let classPredictions = prediction?.classLabelProbs{
                    DispatchQueue.main.sync {
                        self.viewVisualizer.update(labelConference: classPredictions)
                    }
                }
            }
        }
    }
}

