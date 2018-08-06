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
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Constants
    let WIKI_URL = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var viewImage: UIImageView!
    
    @IBOutlet weak var textLabel: UILabel!
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
                let flowerName = firstResult.identifier.capitalized
                self.navigationItem.title = flowerName
                
                let params : [String : String] = [
                    "format" : "json",
                    "action" : "query",
                    "prop" : "extracts",
                    "exintro" : "",
                    "explaintext" : "",
                    "titles" : flowerName,
                    "indexpageids" : "",
                    "redirects" : "1",
                    ]
                
                self.getWikiPage(url: self.WIKI_URL, parameters: params)
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

    func getWikiPage(url: String, parameters: [String:String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Success! Got the wiki data")
                
                let wikiJSON : JSON = JSON(response.result.value!)
                print(wikiJSON)
                self.updateWikiData(json: wikiJSON)
            } else {
                print("Error \(response.result.error)")
            }
        }
    }
    
    func updateWikiData(json: JSON) {
        let pageId = json["query"]["pageids"][0].string
       
        let text = json["query"]["pages"][pageId!]["extract"]
        
        print(text)
        textLabel.text = text.string
    }

    @IBAction func chooseImage(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
}

