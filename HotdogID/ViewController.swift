//
//  ViewController.swift
//  HotdogID
//
//  Created by Karim Wael on 7/29/20.
//  Copyright © 2020 Karim Wael. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController,  UINavigationControllerDelegate {
    //MARK:Vars
    let IMG = UIImageView()
    lazy var detectionRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for: HotdogsID_1().model)
            let request = VNCoreMLRequest(model: model, completionHandler: {[weak self] request, err in
                self?.processDetections(for: request, error: err)
                //request.process
            })
            request.imageCropAndScaleOption = .scaleFit
            return request
        }catch{
            fatalError("failed to load VML:\(error)")
        }
    }()
    
    let testpic : UIButton={
        let t = UIButton()
        t.setTitle("Test", for: .normal)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.addTarget(self, action: #selector(Handletest), for: .touchDown)
        return t
    }()
//MARK: Functions
    private func upDet(for image:UIImage){
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        guard let ciImage = CIImage(image: image) else{fatalError("Unable to create \(CIImage.self) from \(image)")}
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do{
                try handler.perform([self.detectionRequest])
            }catch{
                print("Failed to perform dettection.\n \(error.localizedDescription)")
            }
        }
    }
    private func processDetections(for request: VNRequest, error: Error?){
        print("hi2.0")
        DispatchQueue.main.async {
            guard let results = request.results else{
                print("Unable To detect anything.\n\(error!.localizedDescription)")
                return
            }
            let detections = results as! [VNRecognizedObjectObservation]
            self.drawDetectionsOnPreview(detections: detections)
        }
    }
    func drawDetectionsOnPreview(detections: [VNRecognizedObjectObservation]){
        guard let image = self.IMG.image else{return}
        let imageSize =  image.size
        let scale : CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        image.draw(at:CGPoint.zero)
        
        for detection in detections {
            print(detection.labels.map({"\($0.identifier) confidence: \($0.confidence)"}).joined(separator: "\n"))
            print("--------------")
            
            let boundingBox = detection.boundingBox
            let xr = Double(boundingBox.minX*image.size.width)
            let rectangle = CGRect(x: xr , y: Double((1.0-boundingBox.minY-boundingBox.height)*image.size.height), width: Double(boundingBox.width*image.size.width), height: Double(boundingBox.height*image.size.height))
            UIColor(red: 0, green: 1, blue: 0, alpha: 0.4).setFill()
            UIRectFillUsingBlendMode(rectangle, CGBlendMode.normal)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsGetImageFromCurrentImageContext()
        self.IMG.image = newImage
    }
    
//MARK:Set-ups
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HI")
        IMG.translatesAutoresizingMaskIntoConstraints = false
        //IMG.backgroundColor = UIColor.red
        view.addSubview(IMG)
        IMG.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        IMG.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        IMG.widthAnchor.constraint(equalToConstant: 300).isActive = true
        IMG.heightAnchor.constraint(equalToConstant: 300).isActive = true
        view.addSubview(testpic)
        testpic.topAnchor.constraint(equalTo: IMG.bottomAnchor,constant: 8).isActive = true
        testpic.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //testpic.backgroundColor = UIColor.red
        testpic.setTitleColor(UIColor.systemBlue, for: .normal)
        // Do any additional setup after loading the view.
    }
//MARK: Handlers
    @objc func Handletest(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        present(vc,animated: true)
    }

}
//MARK: Extensions
extension ViewController: UIImagePickerControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        self.IMG.image = image
        upDet(for: image)
    }
}

