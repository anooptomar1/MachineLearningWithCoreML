//
//  EmotionVisualizerView.swift
//  FacialEmotionDetection
//
//  Created by Joshua Newnham on 03/03/2018.
//  Copyright © 2018 PacktPub. All rights reserved.
//

import UIKit

class EmotionVisualizerView: UIView {
    
    func update(labelConference:[String:Float]){
        for (key, value) in labelConference{
            print("\(key) \(value)")
        }
    }
    
}
