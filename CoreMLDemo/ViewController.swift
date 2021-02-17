//
//  ViewController.swift
//  CoreMLDemo
//
//  Created by Ram on 16/02/21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var selectImageBtn: UIButton!
    
    //
    @IBOutlet weak var dataLbl: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        selectImageBtn.addTarget(self, action: #selector(ImageBtn), for: UIControl.Event.touchUpInside)
    }

    //Creating Action to this button
    @objc func ImageBtn()
    {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true, completion: nil)
    }
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for: SqueezeNet(configuration: .init()).model)
            let request = VNCoreMLRequest(model: model) {request, _ in
                if let classifications = request.results as? [VNClassificationObservation] {
                    let topClassifications = classifications.prefix(5)
                    let description = topClassifications.map { classification in
                        return String(format: "%.1f%% %@", classification.confidence * 100, classification.identifier)
                    }
                    DispatchQueue.main.async {
                        self.dataLbl.text = "Classification:\n" + description.joined(separator: "\n")
                    }
                }
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load vision ML Model : \(error)")
        }
    }()
//function
    func classifyImage(_ image:UIImage){
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {return}
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image)")}
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do{
                try handler.perform([self.classificationRequest])
            }catch {
                print("failed to perform classification \(error.localizedDescription)")
            }
        }
    }
}

extension ViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imgView.image = image
            classifyImage(image)
            dismiss(animated: true, completion: nil)
        }
    }
}
