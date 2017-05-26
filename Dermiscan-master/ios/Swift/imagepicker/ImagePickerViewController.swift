// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import SwiftyJSON


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    let imagePicker = UIImagePickerController()
    let session = URLSession.shared
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var labelResults: UITextView!
    
    
    var googleAPIKey = "AIzaSyC0ogF8WpUQI9ZUYSu8_aRXrb0ulKJTQIY"
    var googleURL: URL
    {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    
    //Array of preset skin conditions
    var rashes: [String] = ["Intertrigo","Ringworm","Skin rash"]
    
    //Global Array of Rashes
    var labels: Array<String> = []
    
    //Global Array of scores
    var scores: Array<String> = []
    
    var condition: String = ""
    
    let treatment: [String:String] = [
        "Intertrigo" : "SYMPTOMS:\n Red or reddish-brown rash\n Raw, itchy, or oozing skin\n Foul odor\n Cracked or crusty skin\n\n TREATMENT:\n If you or your child has intertrigo, your doctor may suggest simply keeping the affected area dry and exposed to the air. You may control oozing with moist compresses of an astringent called Burow's solution. Then air-dry with a hair dryer set on cool. A barrier cream may be recommended to help protect skin from irritants. To treat intertrigo, your doctor may recommend short-term use of a topical steroid to reduce inflammation in the area. If the area is also infected, your doctor may prescribe an antifungal or antibiotic cream or ointment. Sometimes you need an oral medication.",
        "Ringworm" : "SYMPTOMS:\n The telltale sign is a red, scaly patch or bump that itches. Over time, the bump turns into a ring- or circle-shaped patch. It may turn into several rings. The inside of the patch is usually clear or scaly. The outside might be slightly raised and bumpy.Ringworm on your scalp tends to start out as a bump or small sore. It may turn flaky and scaly, and your scalp may feel tender and sore to the touch. You may notice that your hair starts to fall out in patches.\n\n TREATMENT:\n In most cases, you’ll have to use the medicines on your skin for 2 to 4 weeks to make sure you kill the fungus that causes ringworm. It also will lower its chance of coming back. If you have ringworm on your scalp or in many different places on your body, OTC treatments probably won’t be enough. Your doctor will have to write you a prescription. Keep an eye out for symptoms that get worse or don’t clear up after 2 weeks. If they don’t, call your doctor.",
        "Skin rash" : "SYMPTOMS:\n Heat rash looks like dots or tiny pimples. In young children, heat rash can appear on the head, neck, and shoulders. The rash areas can get irritated by clothing or scratching, and, in rare cases, a secondary skin infection may develop.\n\n TREATMENT:\n Most prickly heat rashes heal on their own. The following steps can help relieve symptoms.\n\n Start by removing or loosening your baby's clothing and move him or her to a cool, shady spot.\nLet the skin air-dry instead of using towels.\n Avoid ointments or other lotions, because they can irritate the skin.\nThe following tips can help prevent future episodes of the rash:\n\n Dress your child in as few clothes as possible during hot weather.\n Keep the skin cool and dry.\n Keep the sleeping area cool."
        
    ]
    
    @IBAction func loadImageButtonTapped(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        labelResults.isHidden = true
        spinner.hidesWhenStopped = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let destResultsTable: Results = segue.destination as! Results
        
        destResultsTable.labelResults = labels
        
        destResultsTable.scoreResults = scores
        
        destResultsTable.condition = condition
    }
}


/// Image processing

extension ViewController
{
    
    func analyzeResults(_ dataToParse: Data)
    {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute:
        {
            
            
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            
            self.spinner.stopAnimating()
            self.imageView.isHidden = false
            self.labelResults.isHidden = false
            
            // Check for errors
            if (errorObj.dictionaryValue != [:])
            {
                self.labelResults.text = "Error code \(errorObj["code"]): \(errorObj["message"])"
            }
            else
            {
                // Parse the response
                print(json)
                let responses: JSON = json["responses"][0]
                
                // Get Web label annotations
                let labelAnnotations: JSON = responses["webDetection"]["webEntities"]
                let numLabels: Int = labelAnnotations.count
                if numLabels > 0 {
                    var labelResultsText:String = "Diagnosis: "
                    self.labels.removeAll() //Empties array
                    for index in 0..<numLabels
                    {
                        let label = labelAnnotations[index]["description"].stringValue
                        let score = labelAnnotations[index]["score"].stringValue
                        self.labels.append(label)
                        self.scores.append(score)
                    }
                    
                    var found = false
                    
                    for i in 0 ..< numLabels
                    {
                        if found == true
                        {
                            break
                        }
                        else
                        {
                            for j in 0 ..< self.rashes.count
                            {
                                if self.labels[i] == self.rashes[j]
                                {
                                    labelResultsText += "\(self.rashes[j])\n\n"
                                    self.condition = self.rashes[j]
                                    labelResultsText += self.treatment["\(self.condition)"]!
                                    //self.condition = self.rashes[j]
                                    found = true
                                    break
                                }
                            }
                        }
                    }
                    
                    if labelResultsText == "Diagnosis: "
                    {
                        labelResultsText += "No diagnosis found"
                    }
                    
                    self.labelResults.text = labelResultsText
                }
                
                else
                {
                    self.labelResults.text = "No labels found"
                }
            }
        })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.isHidden = false // You could optionally display the image here by setting
            imageView.image = pickedImage
            spinner.startAnimating()
            labelResults.isHidden = true
            
            // Base64 encode the image and create the request
            let binaryImageData = base64EncodeImage(pickedImage)
            createRequest(with: binaryImageData)
            //queryRequest(with: binaryImageData)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data
    {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
}



/// Networking

extension ViewController {
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata?.count > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String)
    {
        // Create our request URL
        
        var request = URLRequest(url: googleURL)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features":[
                    [
                        "type": "LABEL_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "FACE_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "WEB_DETECTION",
                        "maxResults": 10
                    ]
                ]
            ]
        ]
        let jsonObject = JSON(jsonDictionary: jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest)
    {
        // run the request
        
        let task: URLSessionDataTask = session.dataTask(with: request)
        { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeResults(data)
        }
        
        task.resume()
    }
    
    
}


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}
