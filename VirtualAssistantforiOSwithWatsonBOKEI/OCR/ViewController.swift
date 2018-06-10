//
//  ViewController.swift
//  Part2
//
//  Copyright © 2017 DrNeurosurg. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    //HOLDS OUR INPUT
    var  inputImage:CIImage?
    
    //RESULT FROM OVERALL RECOGNITION
    var  recognizedWords:[String] = [String]()

    //RESULT FROM RECOGNITION
    var recognizedRegion:String = String()
    

    //OCR-REQUEST
    lazy var ocrRequest: VNCoreMLRequest = {
        do {
            //THIS MODEL IS TRAINED BY ME FOR FONT "Inconsolata" (Numbers 0...9 and UpperCase Characters A..Z)
            let model = try VNCoreMLModel(for:OCR().model)
            return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
        } catch {
            fatalError("cannot load model")
        }
    }()
    
    //OCR-HANDLER
    func handleClassification(request: VNRequest, error: Error?)
    {
        guard let observations = request.results as? [VNClassificationObservation]
            else {fatalError("unexpected result") }
        guard let best = observations.first
            else { fatalError("cant get best result")}
        
        self.recognizedRegion = self.recognizedRegion.appending(best.identifier)
    }
    
    //TEXT-DETECTION-REQUEST
    lazy var textDetectionRequest: VNDetectTextRectanglesRequest = {
        return VNDetectTextRectanglesRequest(completionHandler: self.handleDetection)
    }()
    
    //TEXT-DETECTION-HANDLER
    func handleDetection(request:VNRequest, error: Error?)
    {
        guard let observations = request.results as? [VNTextObservation]
            else {fatalError("unexpected result") }
        
        // EMPTY THE RESULTS
        self.recognizedWords = [String]()
        
        //NEEDED BECAUSE OF DIFFERENT SCALES
        let  transform = CGAffineTransform.identity.scaledBy(x: (self.inputImage?.extent.size.width)!, y:  (self.inputImage?.extent.size.height)!)
        
        //A REGION IS LIKE A "WORD"
        for region:VNTextObservation in observations
        {
            guard let boxesIn = region.characterBoxes else {
                continue
            }
            
            //EMPTY THE RESULT FOR REGION
            self.recognizedRegion = ""

            //A "BOX" IS THE POSITION IN THE ORIGINAL IMAGE (SCALED FROM 0... 1.0)
            for box in boxesIn
            {
                //SCALE THE BOUNDING BOX TO PIXELS
                let realBoundingBox = box.boundingBox.applying(transform)

                //TO BE SURE
                guard (inputImage?.extent.contains(realBoundingBox))!
                    else { print("invalid detected rectangle"); return}

                //SCALE THE POINTS TO PIXELS
                let topleft = box.topLeft.applying(transform)
                let topright = box.topRight.applying(transform)
                let bottomleft = box.bottomLeft.applying(transform)
                let bottomright = box.bottomRight.applying(transform)
                
                //LET'S CROP AND RECTIFY
                let charImage = inputImage?
                    .cropped(to: realBoundingBox)
                    .applyingFilter("CIPerspectiveCorrection", parameters: [
                        "inputTopLeft" : CIVector(cgPoint: topleft),
                        "inputTopRight" : CIVector(cgPoint: topright),
                        "inputBottomLeft" : CIVector(cgPoint: bottomleft),
                        "inputBottomRight" : CIVector(cgPoint: bottomright)
                        ])
                
                //PREPARE THE HANDLER
                let handler = VNImageRequestHandler(ciImage: charImage!, options: [:])
                
                //SOME OPTIONS (TO PLAY WITH..)

                self.ocrRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill

                //FEED THE CHAR-IMAGE TO OUR OCR-REQUEST - NO NEED TO SCALE IT - VISION WILL DO IT FOR US !!
                do {
                    try handler.perform([self.ocrRequest])
                }  catch { print("Error")}
                
            }
            
            //APPEND RECOGNIZED CHARS FOR THAT REGION
            self.recognizedWords.append(recognizedRegion)
        }
        
        //THATS WHAT WE WANT - PRINT WORDS TO CONSOLE
        DispatchQueue.main.async {
            self.PrintWords(words: self.recognizedWords)
        }
    }
    
    func PrintWords(words:[String])
    {
        // VOILA'
//        print(recognizedWords)
        var text = ""
        for t in recognizedWords {
            text += t + "\n"
        }
        detectedText.text = text
    }
    
    func doOCR(ciImage:CIImage)
    {
        //PREPARE THE HANDLER
        let handler = VNImageRequestHandler(ciImage: ciImage, options:[:])
        
        //WE NEED A BOX FOR EACH DETECTED CHARACTER
        self.textDetectionRequest.reportCharacterBoxes = true
        self.textDetectionRequest.preferBackgroundProcessing = false
        
        //FEED IT TO THE QUEUE FOR TEXT-DETECTION
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try  handler.perform([self.textDetectionRequest])
            } catch {
                print ("Error")
            }
        }
        
    }

    // MARK: - IBouptlets

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detectedText: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    // MARK: IBAction

    @IBAction func pickImageClicked(_ sender: UIButton) {
        let alertController = createActionSheet()
        let action1 = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showImagePicker(withType: .camera)
        })
        let action2 = UIAlertAction(title: "Photos", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showImagePicker(withType: .photoLibrary)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        addActionsToAlertController(controller: alertController,
                                    actions: [action1, action2, cancelAction])
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: image picker

    func showImagePicker(withType type: UIImagePickerControllerSourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = type
        present(pickerController, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Couldn't load image")
        }
        let newImage = fixOrientation(image: image)
        self.imageView.image = newImage
        showActivityIndicator()
        DispatchQueue.global(qos: .userInteractive).async {
            self.detectText(image: newImage)
        }
    }

    // MARK: text detection

    func detectText(image: UIImage) {
        //WE NEED AN CIIMAGE - NO NEED TO SCALE
        let currentImage = image.noir
        imageView.image = currentImage
        inputImage = CIImage(image:currentImage)
        //LET'S DO IT
        self.doOCR(ciImage: inputImage!)
    }

    private func showActivityIndicator() {
        activityIndicator.startAnimating()
    }

    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }
}





