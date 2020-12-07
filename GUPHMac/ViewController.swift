//
//  ViewController.swift
//  GUPHMac
//
//  Created by billgateshxk on 2020/11/30.
//

import Cocoa

let POSTTAGS_MODE = "posttags"
let LATESETTAGS_MODE = "latesttags"

class ViewController: NSViewController {
    @IBOutlet weak var csrftokenTF: NSTextField!
    @IBOutlet weak var sessionidTF: NSTextField!
    
    @IBOutlet weak var usernameTF: NSTextView!
    @IBOutlet weak var qhTF: NSTextField!
    @IBOutlet weak var countTF: NSTextField!
    @IBOutlet weak var perPageTF: NSTextField!
    @IBOutlet weak var fileStartCountTF: NSTextField!
    
    @IBOutlet weak var tagTF: NSTextField!
    
    @IBOutlet weak var loadBTN: NSButton!
    
    @IBOutlet weak var statusLabel: NSTextField!
    
    var end_cursor = ""
    var user_id = ""
    var userCountU = 0
    var userArr = [String]()
    var postList = [String]()
    var exportList = [String]()
    
    let userdefault = UserDefaults.standard
    let nGroup = DispatchGroup()
    
    var userIDList = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let csrftoken = userdefault.string(forKey: "csrftoken"){
            self.csrftokenTF.stringValue = csrftoken
        }
        if let sessionid = userdefault.string(forKey: "sessionid"){
            self.sessionidTF.stringValue = sessionid
        }
        if let query_hash = userdefault.string(forKey: "query_hash"){
            self.qhTF.stringValue = query_hash
        }
        self.applyCookie(self)
        
        // Do any additional setup after loading the view.
        self.statusLabel.stringValue = "Ready."
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func applyCookie(_ sender: Any) {
        userdefault.setValue(self.csrftokenTF.stringValue, forKey: "csrftoken")
        userdefault.setValue(self.sessionidTF.stringValue, forKey: "sessionid")
        userdefault.setValue(self.qhTF.stringValue, forKey: "query_hash")
        setCookieValue(csrftokenstr: self.csrftokenTF.stringValue, sessionidstr: self.sessionidTF.stringValue)
    }
    
    @IBAction func resetBTNP(_ sender: Any) {
        userCountU = 0
        self.statusLabel.stringValue = "Ready."
        self.usernameTF.string = ""
    }
    
    // MARK: - Latest Tags list user
    
    @IBAction func loadTagBTNP(_ sender: Any) {
        exportList = [String]()
        if self.tagTF.stringValue.lengthOfBytes(using: .utf8) <= 0{
            return
        }
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Loading latest tags..."
        }
        self.nGroup.enter()
        getTagList(tag: self.tagTF.stringValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) { (isSuccessed, value) in
            if !isSuccessed!{
                return
            }
            let json = value as! Dictionary<String, Any>
            let graphql = json["graphql"] as! Dictionary<String, Any>
            
            let hashtag = graphql["hashtag"] as! Dictionary<String, Any>
            let edge_hashtag_to_media = hashtag["edge_hashtag_to_media"] as! Dictionary<String, Any>
            let edges = edge_hashtag_to_media["edges"] as! Array<Any>
            for item in edges {
                let edge = item as! Dictionary<String, Any>
                let node = edge["node"] as! Dictionary<String, Any>
                let shortcode = node["shortcode"] as! String
                print("\(shortcode)")
                
                self.postList.append(shortcode)
                
                let owner = node["owner"] as! Dictionary<String, Any>
                let userid = owner["id"] as! String
                self.userIDList.append(userid)
            }
            
            let page_info = edge_hashtag_to_media["page_info"] as! Dictionary<String, Any>
            let has_next_page = page_info["has_next_page"] as! Bool
            
            
            if has_next_page == true && self.postList.count < self.countTF.intValue {
                self.end_cursor = page_info["end_cursor"] as! String
                
                self.loadNextPage(mode: LATESETTAGS_MODE)
            }else{
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
                }
                
                print("load default post compete:\(self.postList)")
            }
            self.nGroup.leave()
            
        }
        self.nGroup.notify(queue: .main) {
            DispatchQueue.main.async {
            self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
            }
                print("Finished all post list requests.")
            print(self.userIDList)
            self.loadAllPostContent(mode: LATESETTAGS_MODE)
            }
    }
    
    
    
    
    
    // MARK: - User post tags
    
    @IBAction func loadBTNP(_ sender: Any) {
        //clean up each time
        postList = [String]()
        exportList = [String]()
        
        
        self.userArr = self.usernameTF.string.components(separatedBy: "\n")
        //print(self.userArr)
        if userCountU >= self.userArr.count {
            self.statusLabel.stringValue = "No more user to load."
            return
        }
        
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Loading user posts..."
        }
        let user = self.userArr[userCountU]
        
        if user.lengthOfBytes(using: .utf8) > 0 {
            self.exportList.append("\(user)")
            self.nGroup.enter()
            getUser(username: user) { (isSuccessed, value) in
                if isSuccessed! {
                    let json = value as! Dictionary<String, Any>
                    let graphql = json["graphql"] as! Dictionary<String, Any>
                    let user = graphql["user"] as! Dictionary<String, Any>
                    
                    let edge_follow = user["edge_follow"] as! Dictionary<String, Any>
                    let user_following = edge_follow["count"] as! NSNumber
                    
                    let edge_followed_by = user["edge_followed_by"] as! Dictionary<String, Any>
                    let user_follower = edge_followed_by["count"] as! NSNumber
                    
                    self.exportList.append(user_following.stringValue)
                    self.exportList.append(user_follower.stringValue)
                    
                    let edge_owner_to_timeline_media = user["edge_owner_to_timeline_media"] as! Dictionary<String, Any>
                    
                    let postCount = edge_owner_to_timeline_media["count"] as! NSNumber
                    self.exportList.append(postCount.stringValue)
                    
                    let username = user["username"] as! String
                    let userLink = "https://www.instagram.com/\(username)/"
                    self.exportList.append(userLink)

                    //set cursor for loading next page
                    let page_info = edge_owner_to_timeline_media["page_info"] as! Dictionary<String, Any>
                    
                    
                    let edges = edge_owner_to_timeline_media["edges"] as! Array<Any>
                    
                    for item in edges {
                        let edge = item as! Dictionary<String, Any>
                        let node = edge["node"] as! Dictionary<String, Any>
                        let shortcode = node["shortcode"] as! String
                        print("\(shortcode)")
                        
                        self.postList.append(shortcode)
                    }
                    let has_next_page = page_info["has_next_page"] as! Bool
                    if has_next_page == true && self.postList.count < self.countTF.intValue {
                        self.end_cursor = page_info["end_cursor"] as! String
                        self.user_id = user["id"] as! String
                        
                        self.loadNextPage(mode: POSTTAGS_MODE)
                    }else{
                        DispatchQueue.main.async {
                        self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
                        }
                        print("load 12 post compete:\(self.postList)")
                    }
                    self.nGroup.leave()
                    
                }
            }
        }
        
        self.nGroup.notify(queue: .main) {
            DispatchQueue.main.async {
            self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
            }
                print("Finished all post list requests.")
            self.loadAllPostContent(mode: POSTTAGS_MODE)
            }
    }
    
    func loadNextPage(mode:String)  {
        if self.qhTF.stringValue.lengthOfBytes(using: .utf8) > 0 && self.postList.count < self.countTF.intValue{
            sleep(1)
            self.nGroup.enter()
            var nPV = ""
            if mode == POSTTAGS_MODE {
                nPV = self.nextPageVariables(userid: self.user_id, end_cursor: self.end_cursor)
            }else if mode == LATESETTAGS_MODE{
                nPV = self.nextTagPageVariables(tag: self.tagTF.stringValue, end_cursor: self.end_cursor)
            }
            getNextPage(query_hash: self.qhTF.stringValue, variables:nPV ) { (isSuccessed, value) in
                if isSuccessed! {
                    let json = value as! Dictionary<String, Any>
                    let data = json["data"] as! Dictionary<String, Any>
                    
                    var page_info = Dictionary<String, Any>.init()
                    var edges = Array<Any>.init()
                    
                    if mode == POSTTAGS_MODE {
                        let dic = data["user"] as! Dictionary<String, Any>
                        let edge_owner_to_timeline_media = dic["edge_owner_to_timeline_media"] as! Dictionary<String, Any>
                        //set cursor for loading next page
                        page_info = edge_owner_to_timeline_media["page_info"] as! Dictionary<String, Any>
                        
                        edges = edge_owner_to_timeline_media["edges"] as! Array<Any>
                    }else if mode == LATESETTAGS_MODE{
                        let dic = data["hashtag"] as! Dictionary<String, Any>
                        let edge_hashtag_to_media = dic["edge_hashtag_to_media"]as! Dictionary<String, Any>
                           //set cursor for loading next page
                           page_info = edge_hashtag_to_media["page_info"] as! Dictionary<String, Any>
                        
                        edges = edge_hashtag_to_media["edges"] as! Array<Any>
                    }
                    
                    
                    
                    
                    
                    for item in edges {
                        let edge = item as! Dictionary<String, Any>
                        let node = edge["node"] as! Dictionary<String, Any>
                        let shortcode = node["shortcode"] as! String
                        //print(shortcode)
                        print("\(shortcode)")
                        self.postList.append(shortcode)
                        
                        let owner = node["owner"] as! Dictionary<String, Any>
                        let userid = owner["id"] as! String
                        self.userIDList.append(userid)
                    }
                    
                    let has_next_page = page_info["has_next_page"] as! Bool
                        if has_next_page == true && self.postList.count < self.countTF.intValue {
                            if let cursor = page_info["end_cursor"]{
                                self.end_cursor = cursor as! String
                            }
                            self.loadNextPage(mode:mode)
                        }
                    self.nGroup.leave()
                }
            }
        }
        else{
            DispatchQueue.main.async {
            self.statusLabel.stringValue = "Load all list competed."
            }
            print("load all post compete:\(self.postList)")
            
        }
        
    }
    func nextTagPageVariables(tag:String,end_cursor:String) -> String {
        let str =  "{\"tag_name\":\"\(tag)\",\"first\":\(self.perPageTF.stringValue),\"after\":\"\(end_cursor)\"}".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        //print(str!)
        return str!
    }
    func nextPageVariables(userid:String,end_cursor:String) -> String {
        let str =  "{\"id\":\"\(userid)\",\"first\":\(self.perPageTF.stringValue),\"after\":\"\(end_cursor)\"}".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        //print(str!)
        return str!
    }
    
    
    func loadAllPostContent(mode:String) {
        
        print("postListCount:\(self.postList.count)")
        
        //postList[user][posts]
        for scode in self.postList {
                self.nGroup.enter()
            DispatchQueue.main.async {
                self.statusLabel.stringValue = "Loading content of posts..."
            }
                sleep(1)
                getPostContent(shortCode: scode) { (isSuccessed, result) in
                    if isSuccessed! {
                        let json = result as! Dictionary<String,Any>
                        let graphql = json["graphql"] as! Dictionary<String, Any>
                        let shortcode_media = graphql["shortcode_media"] as! Dictionary<String, Any>
                        
                            if mode == POSTTAGS_MODE {
                                let edge_media_to_caption = shortcode_media["edge_media_to_caption"] as! Dictionary<String, Any>
                                let edges = edge_media_to_caption["edges"] as! Array<Any>
                                if edges.count > 0 {
                                    let edge = edges[0] as! Dictionary<String, Any>
                                    let node = edge["node"] as! Dictionary<String, Any>
                                let text = node["text"] as! String
                                //print(text)
                                let tags = self.findHashTags(str: text)
                                for item in tags {
                                    print("\(item)")
                                    self.exportList.append(item)
                                }
                            }
                            }else if mode == LATESETTAGS_MODE{
                                let owner = shortcode_media["owner"] as! Dictionary<String, Any>
                                let username = owner["username"] as! String
                                self.exportList.append(username)
                            }
                            
                            
                       
                        self.nGroup.leave()
                    }else{
                        print("load failed:\(result as! String)")
                    }
                
            }
        }
        DispatchQueue.main.async {
        self.statusLabel.stringValue = "\(self.exportList.count) loaded. Exporting..."
        }
        self.nGroup.notify(queue: .main) {
                print("Finished all post data requests.")
            self.exportFile()
            }
    }
    
    
    func exportFile() {
        self.statusLabel.stringValue = "Exporting \(self.exportList.count) data..."
        
        
        var fileStrData:String = ""
//        for user in self.userArr {
//            //each username
//            fileStrData += "\"" + user + "\""
//            //add "," except last one
//            if user != userArr[userArr.count-1]{
//                fileStrData += ","
//            }
//        }
//        fileStrData += "\n"

        print(self.exportList)
        
        for tag in self.exportList{
            fileStrData += tag
            fileStrData += "\n"
        }
        
        //find largest array count in tagList
//        var maxCount = 0
//        for tags in exportList {
//            if tags.count > maxCount {
//                maxCount = tags.count
//            }
//        }
//
//        //taglist[user][tag]
//        for t in 0 ... maxCount{
//
//            for u in 0 ... self.exportList.count {
//
//                if u < self.exportList.count  {
//
//                    if t < self.exportList[u].count {
//                        let tag = self.exportList[u][t]
//
//                        fileStrData += "\"" + tag + "\","
////                        if tag !=  self.exportList[u][self.exportList[u].count-1]{
////                            fileStrData += ","
////                        }
//
//                        //print(fileStrData)
//                    }else{
//                        fileStrData += ","
//                    }
//
//                }else{
//                    fileStrData += ","
//                }
//
//
//            }
//            fileStrData += "\n"
//        }
        
        print(fileStrData)

        let mySave = NSSavePanel()
        mySave.nameFieldStringValue = "\(self.fileStartCountTF.stringValue).csv"
                mySave.begin { (result) -> Void in

                    if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                        let filename = mySave.url

                        do {
                            try fileStrData.write(to: filename!, atomically: true, encoding: .utf8)
                            DispatchQueue.main.async {
                            self.statusLabel.stringValue = "Export data competed."
                            }
                        } catch {
                            print("failed to write file (bad permissions, bad filename etc.)")
                        }

                    } else {
                        //NSBeep()
                    }
                }
        let fileCount = Int(self.fileStartCountTF.stringValue)
        self.fileStartCountTF.stringValue = "\(fileCount! + 1)"
        
        self.userCountU += 1
    }
    
    func findHashTags(str:String) -> [String]{
        let pattern = "#[^\\s!@#$%^&*()=+.\\/,\\[{\\]};:'\"?><]+"
        do {
                let regex = try NSRegularExpression(pattern: pattern)
                let results = regex.matches(in: str,
                                            range: NSRange(str.startIndex..., in: str))
                
            return results.map {
                        String(str[Range($0.range, in: str)!])
                    }
                
            } catch let error {
                print("invalid regex: \(error.localizedDescription)")
                return []
            }
    }
}


