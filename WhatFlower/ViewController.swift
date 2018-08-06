//
//  ViewController.swift
//  WhatFlower
//
//  Created by Aleksandr on 7/22/18.
//  Copyright © 2018 Aleksandr. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var viewImage: UIImageView!
    
    @IBOutlet weak var buttonCamera: UIBarButtonItem!
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
//        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        UIImagePickerControllerEditedImage for edited images
//        UIImagePickerControllerOriginalImage for not edited images
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            viewImage.image = userPickedImage
            
            guard let ciImage = CIImage(image: userPickedImage) else { fatalError("Could not convert UIImage into CIImage.") }
            detect(image: ciImage)
            imagePicker.dismiss(animated: true, completion: nil)
        }
    }

    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("Loading CoreML Model Failed.")}
        
        let request = VNCoreMLRequest(model: model) {(request, error) in
            guard let result = request.results as? [VNClassificationObservation] else { fatalError("Error while getting VNClassificationObservation") }
            
            if let firstResult = result.first {
                print("name of flower is: \(firstResult.identifier)")
                self.navigationItem.title = firstResult.identifier.capitalized
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func chooseImage(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
}

