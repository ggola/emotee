//
//  ViewController.swift
//  e-motions
//
//  Created by Giulio Gola on 13/06/2019.
//  Copyright © 2019 Giulio Gola. All rights reserved.
//

import UIKit
import Vision
import CoreML
import ChameleonFramework

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        setupViews()
    }
    
    private func setupViews() {
        self.navigationController?.navigationBar.barTintColor = UIColor.flatPlum()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        cameraButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(cameraTapped))
        self.navigationItem.rightBarButtonItem = cameraButton
        
        self.view.addSubview(backgroundPicture)
        backgroundPicture.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        backgroundPicture.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        backgroundPicture.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        backgroundPicture.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        self.view.addSubview(darkenView)
        darkenView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        darkenView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        darkenView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        darkenView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        self.view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        label.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
        label.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        self.view.addSubview(facePicture)
        facePicture.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        facePicture.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        facePicture.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        facePicture.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
    private var cameraButton: UIBarButtonItem = {
        var b = UIBarButtonItem()
        b.isEnabled = true
        return b
    }()
    
    private let facePicture: UIImageView = {
        let f = UIImageView()
        f.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        f.backgroundColor = UIColor.clear
        f.clipsToBounds = true
        f.contentMode = UIView.ContentMode.scaleAspectFill
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()
    
    private let darkenView: UIView = {
        let f = UIView()
        f.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        f.backgroundColor = UIColor.black
        f.alpha = 0.8
        f.clipsToBounds = true
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()
    
    private let label: UILabel = {
        let l = UILabel()
        l.text = "How do you feel?"
        l.textColor = UIColor.white
        l.font = UIFont(name: "HelveticaNeue-Bold", size: 25)
        l.numberOfLines = 0
        l.sizeToFit()
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let backgroundPicture: UIImageView = {
        let f = UIImageView()
        f.image = UIImage(named: "backgroundPic")
        f.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        f.clipsToBounds = true
        f.contentMode = UIView.ContentMode.scaleAspectFill
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()
    
    // Camera button tapped: choose photo source
    @objc func cameraTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Choose source type", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .camera
            self.imagePicker.cameraCaptureMode = .photo
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Photos", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Image picker delegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        cameraButton.isEnabled = false
        if let imagePicked = info[.editedImage] as? UIImage {
            facePicture.image = imagePicked
            imagePicker.dismiss(animated: true, completion: nil)
            // Detect image
            if let ciimage = CIImage(image: imagePicked) {
                detect(image: ciimage)
            } else {
                print("Error casting CIImage from UIImage")
                self.navigationItem.title = "Please try again"
            }
        } else {
            imagePicker.dismiss(animated: true, completion: nil)
            print("Error picking the UIImage with ImagePicker")
            self.navigationItem.title = "Please try again"
            cameraButton.isEnabled = true
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // Detect emotion
    private func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FaceEmotionsClassifier().model) else {fatalError("Error loading flower model")}
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if error == nil {
                guard let results = request.results as? [VNClassificationObservation] else {fatalError("Error casting results")}
                for result in results {
                    print("Face emotion: \(result.identifier) \(result.confidence * 100)%")
                }
                var emotionsList = [String]()
                if let firstResult = results.first {
                    // Confirm detection only if confidence is high
                    if firstResult.confidence >= 0.4 {
                        emotionsList.append(firstResult.identifier.lowercased())
                        // Check if other relevant emotions are available
                        for r in 1..<results.count {
                            if results[r].confidence >= 0.3 {
                                emotionsList.append(results[r].identifier.lowercased())
                            }
                        }
                        // Construct emotion label
                        let resultLabel = self.setEmotionLabel(forEmotions: emotionsList)
                        DispatchQueue.main.async {
                            self.setUI(withTitle: "You look \(resultLabel)")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.setUI(withTitle: "Can't really tell...")
                        }
                    }
                } else {
                    print("First item is nil")
                    DispatchQueue.main.async {
                        self.setUI(withTitle: "Please try again")
                    }
                }
            } else {
                print("Error processing model request")
                DispatchQueue.main.async {
                    self.setUI(withTitle: "Please try again")
                }
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print("Error handling the request \(error.localizedDescription)")
        }
    }
    
    func setEmotionLabel(forEmotions emotionsList: [String]) -> String {
        var resultLabel = ""
        for emotion in 1...emotionsList.count {
            if emotion < emotionsList.count {
                resultLabel += emotionsList[emotion - 1] + " or "
            } else if emotion == emotionsList.count {
                resultLabel += emotionsList[emotion - 1]
            }
        }
        return resultLabel
    }
    
    func setUI(withTitle title: String) {
        self.navigationItem.title = title
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white, .font : UIFont(name: "HelveticaNeue-Medium", size: 18)!]
        self.cameraButton.isEnabled = true
    }
}
