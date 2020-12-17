//
//  ViewController.swift
//  GUPHMac
//
//  Created by billgateshxk on 2020/11/30.
//

import Cocoa

let MODE_GUPH = "user_post_tags"
let MODE_GLTU = "latest_tags_user"
let MODE_GULC = "user_likes_comments"
class ViewController: NSViewController {
    @IBOutlet var csrftokenTF: NSTextField!
    @IBOutlet var sessionidTF: NSTextField!
    @IBOutlet var qhTF: NSTextField!

    // GUPH
    @IBOutlet var usernameTF: NSTextView!

    // GLTU
    @IBOutlet var tagTF: NSTextField!

    // GULC
    @IBOutlet var usernameTF2: NSTextField!
    @IBOutlet var resultLabel: NSTextField!
    @IBOutlet var postCountTF: NSTextField!

    @IBOutlet var countTF: NSTextField!
    @IBOutlet var perPageTF: NSTextField!
    @IBOutlet var fileStartCountTF: NSTextField!

    @IBOutlet var datePC: NSDatePickerCell!
    @IBOutlet var notIncludeAFCB: NSButton!

    @IBOutlet var statusLabel: NSTextField!

    var end_cursor = ""
    var user_id = ""
    var userCountU = 0
    var userArr = [String]()
    var postList = [String]()
    var exportList = [String]()

    let userdefault = UserDefaults.standard
    let nGroup = DispatchGroup()

    var lastDate = TimeInterval()
    var isDatePassed = false
    
    var commentCountGULC = 0
    var likeCountGULC = 0
    var followerCountGULC = 0
    
    var userFollowerCountArr = Array<Int>.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if let csrftoken = userdefault.string(forKey: "csrftoken") {
            csrftokenTF.stringValue = csrftoken
        }
        if let sessionid = userdefault.string(forKey: "sessionid") {
            sessionidTF.stringValue = sessionid
        }
        if let query_hash = userdefault.string(forKey: "query_hash") {
            qhTF.stringValue = query_hash
        }
        applyCookie(self)

        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()
        var components = DateComponents()
        components.calendar = calendar
        let maxDate = calendar.date(byAdding: components, to: currentDate)!
        datePC.maxDate = maxDate

        components.year = -1
        datePC.dateValue = calendar.date(byAdding: components, to: currentDate)!
        statusLabel.stringValue = "Ready."
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func applyCookie(_ sender: Any) {
        userdefault.setValue(csrftokenTF.stringValue, forKey: "csrftoken")
        userdefault.setValue(sessionidTF.stringValue, forKey: "sessionid")
        userdefault.setValue(qhTF.stringValue, forKey: "query_hash")
        setCookieValue(csrftokenstr: csrftokenTF.stringValue, sessionidstr: sessionidTF.stringValue)
    }

    @IBAction func resetBTNP(_ sender: Any) {
        userCountU = 0
        statusLabel.stringValue = "Ready."
        usernameTF.string = ""
    }

    // MARK: - Latest Tags list user

    @IBAction func loadTagBTNP(_ sender: Any) {
        exportList = [String]()
        if tagTF.stringValue.lengthOfBytes(using: .utf8) <= 0 {
            return
        }
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Loading latest tags..."
        }
        nGroup.enter()
        getTagList(tag: tagTF.stringValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) { isSuccessed, value in
            if !isSuccessed! {
                self.nGroup.leave()
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
            }

            let page_info = edge_hashtag_to_media["page_info"] as! Dictionary<String, Any>
            let has_next_page = page_info["has_next_page"] as! Bool

            if has_next_page == true && self.postList.count < self.countTF.intValue {
                self.end_cursor = page_info["end_cursor"] as! String

                self.loadNextPage(mode: MODE_GLTU)
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
                }

                print("load default post compete:\(self.postList)")
            }
            self.nGroup.leave()
        }
        nGroup.notify(queue: .main) {
            DispatchQueue.main.async {
                self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
            }
            print("Finished all post list requests.")
            self.loadAllPostContent(mode: MODE_GLTU)
        }
    }

    // MARK: - User recent post like & comment count

    @IBAction func loadGULC(_ sender: Any) {
        // clean up each time
        postList = [String]()
        self.commentCountGULC = 0
        self.likeCountGULC = 0
        self.followerCountGULC = 0
        
        if usernameTF2.stringValue.lengthOfBytes(using: .utf8) <= 0 {
            return
        }
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Loading user latest posts..."
        }
        
        var commentCountArr = Array<Int>.init()
        var likeCountArr = Array<Int>.init()

        nGroup.enter()
        getUser(username: usernameTF2.stringValue) { isSuccessed, value in
            if !isSuccessed! {
                self.nGroup.leave()
                return
            }
            let json = value as! Dictionary<String, Any>
            let graphql = json["graphql"] as! Dictionary<String, Any>
            let user = graphql["user"] as! Dictionary<String, Any>
            
            let edge_followed_by = user["edge_followed_by"] as! Dictionary<String, Any>
            let user_follower = edge_followed_by["count"] as! NSNumber
            self.followerCountGULC = Int(truncating: user_follower)
            
            
            
            
            let edge_owner_to_timeline_media = user["edge_owner_to_timeline_media"] as! Dictionary<String, Any>

            // set cursor for loading next page
            let page_info = edge_owner_to_timeline_media["page_info"] as! Dictionary<String, Any>

            let edges = edge_owner_to_timeline_media["edges"] as! Array<Any>

            for item in edges {
                let edge = item as! Dictionary<String, Any>
                let node = edge["node"] as! Dictionary<String, Any>
                
                
                let edge_media_preview_like = node["edge_media_preview_like"] as! Dictionary<String, Any>
                let likecount = edge_media_preview_like["count"] as! Int
                likeCountArr.append(likecount)
                
                let edge_media_to_comment = node["edge_media_to_comment"] as! Dictionary<String, Any>
                let commentcount = edge_media_to_comment["count"] as! Int
                commentCountArr.append(commentcount)
                
                let shortcode = node["shortcode"] as! String
                print("\(shortcode)")
                self.postList.append(shortcode)
            }
            let has_next_page = page_info["has_next_page"] as! Bool
            if has_next_page == true && self.postList.count < self.countTF.intValue {
                self.end_cursor = page_info["end_cursor"] as! String
                self.user_id = user["id"] as! String

                self.loadNextPage(mode: MODE_GULC)
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
                }
                print("load 12 post compete:\(self.postList)")
            }
            self.nGroup.leave()
        }
        nGroup.notify(queue: .main) {
            DispatchQueue.main.async {
                self.statusLabel.stringValue = "\(self.postList.count) post loaded."
            }
            print("Finished all post list requests.")
            //self.loadAllPostContent(mode: MODE_GULC)
            
            var i = 0
            for comment in commentCountArr{
                if i < self.postCountTF.intValue {
                    self.commentCountGULC += comment
                    self.likeCountGULC += likeCountArr[i]
                }
                i += 1
            }
            
            let result:Double = Double(self.likeCountGULC + self.commentCountGULC)/Double(self.followerCountGULC)
            print(result)
            self.resultLabel.stringValue = "( Like(\(self.likeCountGULC)) + Comment(\(self.commentCountGULC)) ) / Follower(\(self.followerCountGULC)) = \(result)"
            self.resultLabel.isEditable = true
        }
    }

    // MARK: - User post tags

    @IBAction func loadBTNP(_ sender: Any) {
        // clean up each time
        postList = [String]()
        exportList = [String]()

        userArr = usernameTF.string.components(separatedBy: "\n")
        // print(self.userArr)
        if userCountU >= userArr.count {
            statusLabel.stringValue = "No more user to load."
            return
        }

        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Loading user posts..."
        }
        let user = userArr[userCountU]

        if user.lengthOfBytes(using: .utf8) > 0 {
            exportList.append("\(user)")
            nGroup.enter()
            getUser(username: user) { isSuccessed, value in
                if isSuccessed! {
                    self.nGroup.leave()
                    return
                }

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

                // set cursor for loading next page
                let page_info = edge_owner_to_timeline_media["page_info"] as! Dictionary<String, Any>

                let edges = edge_owner_to_timeline_media["edges"] as! Array<Any>

                for item in edges {
                    let edge = item as! Dictionary<String, Any>
                    let node = edge["node"] as! Dictionary<String, Any>

                    let taken_at_timestamp = node["taken_at_timestamp"] as! TimeInterval

                    let pointTS = self.datePC.dateValue.timeIntervalSince1970

                    if pointTS >= taken_at_timestamp && self.notIncludeAFCB.state == .on {
                        // post was took before the setting time
                        // let takenDate = Date(timeIntervalSince1970: self.lastDate)
                        // self.exportList.append("##\(takenDate)")
                        self.nGroup.leave()
                        return

                    } else {
                        let shortcode = node["shortcode"] as! String
                        print("\(shortcode)")
                        self.postList.append(shortcode)
                        self.lastDate = taken_at_timestamp
                    }
                }
                let has_next_page = page_info["has_next_page"] as! Bool
                if has_next_page == true && self.postList.count < self.countTF.intValue {
                    self.end_cursor = page_info["end_cursor"] as! String
                    self.user_id = user["id"] as! String

                    self.loadNextPage(mode: MODE_GUPH)
                } else {
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
                    }
                    print("load 12 post compete:\(self.postList)")
                }
                self.nGroup.leave()
            }
        }

        nGroup.notify(queue: .main) {
            DispatchQueue.main.async {
                self.statusLabel.stringValue = "\(self.postList.count) post loaded.  Reading each posts..."
            }
            print("Finished all post list requests.")
            self.loadAllPostContent(mode: MODE_GUPH)
        }
    }

    func loadNextPage(mode: String) {
        if qhTF.stringValue.lengthOfBytes(using: .utf8) > 0 && postList.count < countTF.intValue {
            sleep(1)
            nGroup.enter()
            var nPV = ""
            if mode == MODE_GUPH || mode == MODE_GULC{
                nPV = nextPageVariables(userid: user_id, end_cursor: end_cursor)
            } else if mode == MODE_GLTU {
                nPV = nextTagPageVariables(tag: tagTF.stringValue, end_cursor: end_cursor)
            }
            getNextPage(query_hash: qhTF.stringValue, variables: nPV) { isSuccessed, value in
                if isSuccessed! {
                    let json = value as! Dictionary<String, Any>
                    let data = json["data"] as! Dictionary<String, Any>

                    var page_info = Dictionary<String, Any>.init()
                    var edges = Array<Any>.init()

                    if mode == MODE_GUPH || mode == MODE_GULC {
                        let dic = data["user"] as! Dictionary<String, Any>
                        let edge_owner_to_timeline_media = dic["edge_owner_to_timeline_media"] as! Dictionary<String, Any>
                        // set cursor for loading next page
                        page_info = edge_owner_to_timeline_media["page_info"] as! Dictionary<String, Any>

                        edges = edge_owner_to_timeline_media["edges"] as! Array<Any>

                    } else if mode == MODE_GLTU {
                        let dic = data["hashtag"] as! Dictionary<String, Any>
                        let edge_hashtag_to_media = dic["edge_hashtag_to_media"] as! Dictionary<String, Any>
                        // set cursor for loading next page
                        page_info = edge_hashtag_to_media["page_info"] as! Dictionary<String, Any>

                        edges = edge_hashtag_to_media["edges"] as! Array<Any>
                    }

                    for item in edges {
                        let edge = item as! Dictionary<String, Any>
                        let node = edge["node"] as! Dictionary<String, Any>
                        
                        if mode == MODE_GUPH {
                            let taken_at_timestamp = node["taken_at_timestamp"] as! TimeInterval

                            let pointTS = self.datePC.dateValue.timeIntervalSince1970

                            if pointTS >= taken_at_timestamp && self.notIncludeAFCB.state == .on {
                                // post was took before the setting time
                                // let takenDate = Date(timeIntervalSince1970: self.lastDate)
                                // self.exportList.append("##\(takenDate)")
                                self.nGroup.leave()
                                return

                            } else {
                                let shortcode = node["shortcode"] as! String
                                print("\(shortcode)")
                                self.postList.append(shortcode)
                                self.lastDate = taken_at_timestamp
                            }
                        }else{
                            let shortcode = node["shortcode"] as! String
                            print("\(shortcode)")
                            self.postList.append(shortcode)
                        }
                        
                    }

                    let has_next_page = page_info["has_next_page"] as! Bool
                    if has_next_page == true && self.postList.count < self.countTF.intValue {
                        if let cursor = page_info["end_cursor"] {
                            self.end_cursor = cursor as! String
                        }
                        self.loadNextPage(mode: mode)
                    }
                    self.nGroup.leave()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.statusLabel.stringValue = "Load all list competed."
            }
            print("load all post compete:\(postList)")
        }
    }

    func nextTagPageVariables(tag: String, end_cursor: String) -> String {
        let str = "{\"tag_name\":\"\(tag)\",\"first\":\(perPageTF.stringValue),\"after\":\"\(end_cursor)\"}".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        // print(str!)
        return str!
    }

    func nextPageVariables(userid: String, end_cursor: String) -> String {
        let str = "{\"id\":\"\(userid)\",\"first\":\(perPageTF.stringValue),\"after\":\"\(end_cursor)\"}".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        // print(str!)
        return str!
    }

    func loadAllPostContent(mode: String) {
        print("postListCount:\(postList.count)")

        // postList[user][posts]
        for scode in postList {
            nGroup.enter()
            DispatchQueue.main.async {
                self.statusLabel.stringValue = "Loading content of posts..."
            }
            sleep(1)
            getPostContent(shortCode: scode) { isSuccessed, result in
                if isSuccessed! {
                    let json = result as! Dictionary<String, Any>
                    let graphql = json["graphql"] as! Dictionary<String, Any>
                    let shortcode_media = graphql["shortcode_media"] as! Dictionary<String, Any>

                    if mode == MODE_GUPH {
                        if self.notIncludeAFCB.state == .off {
                            let taken_at_timestamp = shortcode_media["taken_at_timestamp"] as! TimeInterval

                            let pointTS = self.datePC.dateValue.timeIntervalSince1970

                            if pointTS >= taken_at_timestamp && self.isDatePassed == false {
                                let takenDate = Date(timeIntervalSince1970: self.lastDate)
                                self.exportList.append("##\(takenDate)")
                                self.isDatePassed = true
                            }
                            self.lastDate = taken_at_timestamp
                        }

                        let edge_media_to_caption = shortcode_media["edge_media_to_caption"] as! Dictionary<String, Any>
                        let edges = edge_media_to_caption["edges"] as! Array<Any>
                        if edges.count > 0 {
                            let edge = edges[0] as! Dictionary<String, Any>
                            let node = edge["node"] as! Dictionary<String, Any>
                            let text = node["text"] as! String
                            // print(text)
                            let tags = self.findHashTags(str: text)
                            for item in tags {
                                print("\(item)")
                                self.exportList.append(item)
                            }
                        }
                    } else if mode == MODE_GLTU {
                        let owner = shortcode_media["owner"] as! Dictionary<String, Any>
                        let username = owner["username"] as! String
                        self.exportList.append(username)
                        
                        let edge_followed_by = owner["edge_followed_by"] as! Dictionary<String, Any>
                        let user_follower = edge_followed_by["count"] as! Int
                        self.userFollowerCountArr.append(user_follower)
                    }

                    self.nGroup.leave()
                } else {
                    print("load failed:\(result as! String)")
                }
            }
        }
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "\(self.exportList.count) loaded. Exporting..."
        }
        nGroup.notify(queue: .main) {
            print("Finished all post data requests.")
            self.exportFile(mode: mode)
            
        }
    }

    func exportFile(mode:String) {
        statusLabel.stringValue = "Exporting \(exportList.count) data..."

        var fileStrData: String = ""

        print("exportList:\(exportList)")
        var i = 0
        for tag in exportList {
            fileStrData += tag
            if mode == MODE_GLTU {
                fileStrData += ","
                fileStrData += String(self.userFollowerCountArr[i])
                i+=1
            }
            
            fileStrData += "\n"
        }

        if notIncludeAFCB.state == .on {
            let takenDate = Date(timeIntervalSince1970: lastDate)
            fileStrData += "##\(takenDate)"
        }

        print(fileStrData)

        let mySave = NSSavePanel()
        mySave.nameFieldStringValue = "\(fileStartCountTF.stringValue).csv"
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
                // NSBeep()
            }
        }
        let fileCount = Int(fileStartCountTF.stringValue)
        fileStartCountTF.stringValue = "\(fileCount! + 1)"

        userCountU += 1
    }

    func findHashTags(str: String) -> [String] {
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
