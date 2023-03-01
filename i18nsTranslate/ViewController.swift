//
//  ViewController.swift
//  i18nsTranslate
//
//  Created by J on 2023/2/22.
//

import Cocoa
import Alamofire
import SwiftyJSON

class ViewController: NSViewController {
    
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var btn: NSButton!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var apikeyTf: NSTextField!
    
    var apikey: String?
    var languages: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        textView.textStorage?.append(NSAttributedString(string: "自动\n手动", attributes: [.foregroundColor: NSColor.white]))
        
        textField.stringValue = "en,zh_TW"
        apikey = ""
        clearAllFiles()
        textField.delegate = self
        apikeyTf.delegate = self
        textView.delegate = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func clearAllFiles() {
        guard let path = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first else { return }
        let subpath = path.appending("/translation")
        if !FileManager.default.fileExists(atPath: subpath) {
            try? FileManager.default.createDirectory(atPath: subpath, withIntermediateDirectories: true)
        }
        if FileManager.default.fileExists(atPath: subpath), let files = try? FileManager.default.subpaths(atPath: subpath) {
            for file in files {
                try? FileManager.default.removeItem(atPath: subpath + "/\(file)")
            }
        }
    }

    @IBAction func btnAction(_ sender: NSButton) {
        guard let text = textView.textStorage?.string else { return }
        let originalArray = text.components(separatedBy: "\n")
        
        var allDic = [String: [String: [String: String]]]()
        for text in originalArray {
            translateAction(text, completionHandler: { dic in
                allDic[text] = dic
                for key in dic.keys {
                    guard let path = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first, let keys = dic[key]?.keys else { return }
                    
                    var string = ""
                    if FileManager.default.fileExists(atPath: path.appending("/translation/\(key).txt")) {
                        string = try! String(contentsOfFile: path.appending("/translation/\(key).txt"), encoding: .utf8)
                    }

                    if keys.count > 1 {
                        string += "\n"
                    }
                    for k in keys {
                        guard let value = dic[key]?[k] else { return }
                        string += "\"\(value)\"=\"\(k)\";\n"
                    }
                    if keys.count > 1 {
                        string += "\n"
                    }
                    try? (string as NSString).write(to: URL(fileURLWithPath: path.appending("/translation/\(key).txt")), atomically: true, encoding: NSUTF8StringEncoding)
                }
            })
            
        }
        
        guard let path = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path.appending("/translation"))
    }
    
    
    @IBAction func languageAction(_ sender: Any) {
        let url = URL(string: "https://i18ns.com/zh/languagecode.html")!
        if NSWorkspace.shared.open(url) {
            print("default browser was successfully opened")

        }
    }
    
    func translateAction(_ text: String, completionHandler: @escaping ([String: [String: String]]) -> Void){
        guard let apikey = apikey, let languages = languages, languages.count > 0 else { return }
        
        btn.isEnabled = false
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-access-token": apikey
        ]
        AF.request("https://i18ns.com/api/v1/search", method: .post, parameters: ["language": "zh", "content": text], encoder: JSONParameterEncoder.prettyPrinted, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                let json = try? JSON.init(data: data)
                guard let array = json?.arrayValue else { return }
                var lDic = [String: [String: String]]()
                for language in languages {
                    var dic = [String: String]()
                    for obj in array {
                        let translations = obj["translations"]
                        if let t = translations[language].array?.first?.string {
                            dic[t] = text
                        }
                    }
                    lDic[language] = dic
                }
                completionHandler(lDic)
            case .failure(let error):
                // Handle as previously error
                print(error)
            }
        }
    }
    
}

extension ViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let tf = obj.object as? NSTextField
        switch tf {
        case textField:
            self.languages = textField.stringValue.components(separatedBy: ",")
        case apikeyTf:
            self.apikey = apikeyTf.stringValue
        default: break
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        let tf = obj.object as? NSTextField
        switch tf {
        case textField:
            self.languages = textField.stringValue.components(separatedBy: ",")
        case apikeyTf:
            self.apikey = apikeyTf.stringValue
        default: break
        }
    }
}

extension ViewController: NSTextViewDelegate {
    func textDidChange(_ obj: Notification) {
        let tv = obj.object as? NSTextView
        if tv?.textStorage?.string == "" {
            btn.isEnabled = true
        }
    }
}
