//
//  UIButtonExtension.swift
//  SpeechCam
//
//  Created by Darryl Beronque on 3/6/18.
//  Copyright © 2018 Darryl Beronque. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    func animateCamBtn() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.6
        pulse.fromValue = 0.95
        pulse.toValue = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = 200
        pulse.initialVelocity = 0.3
        pulse.damping = 1.0
        
        layer.add(pulse, forKey: "pulse")
    }
    
    func disableAnimation() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.6
        pulse.fromValue = 1.0
        pulse.toValue = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = 5
        pulse.initialVelocity = 0.3
        pulse.damping = 1.0
        
        layer.add(pulse, forKey: "pulse")
    }
    
}
