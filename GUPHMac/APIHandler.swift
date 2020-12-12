//
//  APIHandler.swift
//  GUPHMac
//
//  Created by billgateshxk on 2020/11/30.
//

import Foundation
import Alamofire
//let getUserInfoURL = "https://www.instagram.com/\(username)/?__a=1"
//let getUserPostURL = "https://www.instagram.com/p/\(post_id)/?__a=1"
//let getTagListURL ="https://www.instagram.com/explore/tags/\(tag)/?__a=1"

let mainURL = "https://www.instagram.com/"
let cookieDomian = ".instagram.com"
var csrftoken = ""
var sessionid = ""
var requestManager = Alamofire.Session.default


var cookieProps = Array<Any>.init()

func setCookieValue(csrftokenstr:String,sessionidstr:String){
    csrftoken = csrftokenstr
    sessionid = sessionidstr
    cookieProps = [
        [
        HTTPCookiePropertyKey.domain: cookieDomian,
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "csrftoken",
        HTTPCookiePropertyKey.value: csrftoken
       ],[HTTPCookiePropertyKey.domain: cookieDomian,
         HTTPCookiePropertyKey.path: "/",
         HTTPCookiePropertyKey.name: "sessionid",
         HTTPCookiePropertyKey.value: sessionid
        ]
    ]
}

func getUser(username:String, completion: @escaping (Bool?, Any?) -> Void) {
    let urlstr = mainURL + "\(username)/?__a=1"
    
    conServ(serviceURL: urlstr) { (isSuccessed, value) in
        completion(isSuccessed, value);
    }
}

func getNextPage(query_hash:String, variables:String, completion: @escaping (Bool?, Any?) -> Void) {
    let urlstr = mainURL + "graphql/query/?query_hash=\(query_hash)&variables=\(variables)"
    
    conServ(serviceURL: urlstr) { (isSuccessed, value) in
        completion(isSuccessed, value);
    }
}

func getPostContent(shortCode:String, completion: @escaping (Bool?, Any?) -> Void) {
    let urlstr = mainURL + "p/\(shortCode)/?__a=1"
    //print("loading userCount:\(userCount)")
    conServ(serviceURL: urlstr) { (isSuccessed, value) in
        completion(isSuccessed, value);
    }
}

func getTagList(tag:String, completion: @escaping (Bool?, Any?) -> Void){
    let urlstr = mainURL + "explore/tags/\(tag)/?__a=1"
    conServ(serviceURL: urlstr) { (isSuccessed, value) in
        completion(isSuccessed, value);
    }
}


func conServ(serviceURL: String, completion: @escaping (Bool?, Any?) -> Void) {
    print("serviceURL:\(serviceURL)")
    for item in cookieProps {
        if let cookie = HTTPCookie(properties: item as! [HTTPCookiePropertyKey : Any]) {
            AF.session.configuration.httpCookieStorage?.setCookie(cookie)
        }
    }
    
    AF.request(serviceURL, method: .get, encoding:JSONEncoding.default).responseJSON{
        response in
        //print(response)
        
        switch response.result {
        case .success(let value):
            
            completion(true, value)
            break
        case .failure(let error):
            // error handling
            print(error)
            completion(false, error.localizedDescription)
            break
        }
    }
}
