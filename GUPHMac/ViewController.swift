//
//  ViewController.swift
//  GUPHMac
//
//  Created by billgateshxk on 2020/11/30.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var csrftokenTF: NSTextField!
    @IBOutlet weak var sessionidTF: NSTextField!
    
    @IBOutlet weak var usernameTF: NSTextField!
    @IBOutlet weak var qhTF: NSTextField!
    @IBOutlet weak var countTF: NSTextField!
    
    @IBOutlet weak var loadBTN: NSButton!
    @IBOutlet weak var exportBTN: NSButton!
    
    @IBOutlet weak var statusLabel: NSTextField!
    
    var end_cursor = ""
    var user_id = ""
    
    var postList = Array<Any>.init()
    var tagList = Array<Any>.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.statusLabel.stringValue = "Ready."
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func applyCookie(_ sender: Any) {
        setCookieValue(csrftokenstr: self.csrftokenTF.stringValue, sessionidstr: self.sessionidTF.stringValue)
    }
    
    @IBAction func loadBTNP(_ sender: Any) {
        //clean up each time
        postList = Array<Any>.init()
        tagList = Array<Any>.init()
        
        self.statusLabel.stringValue = "Loading list..."
        getUser(username: self.usernameTF.stringValue) { (isSuccessed, value) in
            if isSuccessed! {
                let json = value as! Dictionary<String, Any>
                let graphql = json["graphql"] as! Dictionary<String, Any>
                let user = graphql["user"] as! Dictionary<String, Any>
                let edge_owner_to_timeline_media = user["edge_owner_to_timeline_media"] as! Dictionary<String, Any>
                
                //set cursor for loading next page
                let page_info = edge_owner_to_timeline_media["page_info"] as! Dictionary<String, Any>
                self.end_cursor = page_info["end_cursor"] as! String
                
                self.user_id = user["id"] as! String
                
                let edges = edge_owner_to_timeline_media["edges"] as! Array<Any>
                
                for item in edges {
                    let edge = item as! Dictionary<String, Any>
                    let node = edge["node"] as! Dictionary<String, Any>
                    let shortcode = node["shortcode"] as! String
                    //print(shortcode)
                    self.postList.append(shortcode)
                }
                
                if (page_info["has_next_page"] != nil) == true && self.postList.count < self.countTF.intValue {
                    self.loadNextPage()
                }else{
                    self.statusLabel.stringValue = "Load list competed."
                    print(self.postList)
                    self.loadAllPostContent()
                }
                
                
            }
        }
    }
    
    func loadNextPage()  {
        if self.qhTF.stringValue.lengthOfBytes(using: .utf8) > 0 && self.postList.count < self.countTF.intValue{
            getNextPage(query_hash: self.qhTF.stringValue, variables: self.nextPageVariables(userid: self.user_id, end_cursor: self.end_cursor)) { (isSuccessed, value) in
                if isSuccessed! {
                    let json = value as! Dictionary<String, Any>
                    let data = json["data"] as! Dictionary<String, Any>
                    let user = data["user"] as! Dictionary<String, Any>
                    let edge_owner_to_timeline_media = user["edge_owner_to_timeline_media"] as! Dictionary<String, Any>
                    //set cursor for loading next page
                    let page_info = edge_owner_to_timeline_media["page_info"] as! Dictionary<String, Any>
                    self.end_cursor = page_info["end_cursor"] as! String
                    
                    let edges = edge_owner_to_timeline_media["edges"] as! Array<Any>
                    for item in edges {
                        let edge = item as! Dictionary<String, Any>
                        let node = edge["node"] as! Dictionary<String, Any>
                        let shortcode = node["shortcode"] as! String
                        //print(shortcode)
                        self.postList.append(shortcode)
                    }
                        if (page_info["has_next_page"] != nil) == true {
                            //sleep(1)
                            self.loadNextPage()
                        }
                }
            }
        }
        else{
            self.statusLabel.stringValue = "Load list competed."
            print(self.postList)
            self.loadAllPostContent()
        }
    }
    
    func nextPageVariables(userid:String,end_cursor:String) -> String {
        let str =  "{\"id\":\"\(userid)\",\"first\":12,\"after\":\"\(end_cursor)\"}".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        //print(str!)
        return str!
    }
    
    func loadAllPostContent()  {
        self.statusLabel.stringValue = "Loading content of posts..."
        for item in self.postList {
            let scode = item as! String
            sleep(1)
            getPostContent(shortCode: scode) { (isSuccessed, result) in
                if isSuccessed! {
                    let json = result as! Dictionary<String,Any>
                    let graphql = json["graphql"] as! Dictionary<String, Any>
                    let shortcode_media = graphql["shortcode_media"] as! Dictionary<String, Any>
                    let edge_media_to_caption = shortcode_media["edge_media_to_caption"] as! Dictionary<String, Any>
                    let edges = edge_media_to_caption["edges"] as! Array<Any>
                    if edges.count > 0 {
                        let edge = edges[0] as! Dictionary<String, Any>
                        let node = edge["node"] as! Dictionary<String, Any>
                        let text = node["text"] as! String
                        
                        //print(text)
                        for item in text.findHashTags() {
                            self.tagList.append(item)
                            print(item)
//                            self.statusLabel.stringValue = "Adding tags..."
                        }
                        
                    }
                    
                }else{
                    print("load failed:\(result as! String)")
                }
            }
        }
        self.statusLabel.stringValue = "Load all post data competed."
        
    }
    
    @IBAction func exportBTNP(_ sender: Any) {
        self.statusLabel.stringValue = "Exporting data..."
        var csvString = ""
        for tag in self.tagList{
            csvString += tag as! String
            csvString += "\n"
        }
        
        print(csvString)
        
        let mySave = NSSavePanel()
            mySave.nameFieldLabel = "export.csv"
                mySave.begin { (result) -> Void in
                    
                    if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                        let filename = mySave.url
                        
                        do {
                            try csvString.write(to: filename!, atomically: true, encoding: String.Encoding.utf8)
                            self.statusLabel.stringValue = "Export data competed."
                        } catch {
                            print("failed to write file (bad permissions, bad filename etc.)")
                        }

                    } else {
                        //NSBeep()
                    }
                }
    }
}

extension String {
    func findHashTags() -> [String] {
        var arr_hasStrings:[String] = []
        
        let regex = try? NSRegularExpression(pattern: "#[^\\s!@#$%^&*()=+.\\/,\\[{\\]};:'\"?><]+", options: [])
        if let matches = regex?.matches(in: self, options:[], range:NSMakeRange(0, self.count)) {
            for match in matches {
                arr_hasStrings.append(NSString(string: self).substring(with: NSRange(location:match.range.location, length: match.range.length )))
            }
        }
        return arr_hasStrings
    }
}
