//
//  UIImageHelper.swift
//  Part2
//
//  Created by DanielMandea on 6/9/18.
//  Copyright © 2018 DrNeurosurg. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    var noir: UIImage {
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectNoir")!
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        let output = currentFilter.outputImage!
        let cgImage = context.createCGImage(output, from: output.extent)!
        let processedImage = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)

        return processedImage
    }
}
