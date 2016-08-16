//
//  WebViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 02/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    @IBOutlet var webView: UIWebView?
    @IBOutlet var spinner: UIActivityIndicatorView?
    
    var serverIsReachable: Signal<Bool>?
    var forceLocalLoad: Bool = false

    var page: String? {
        didSet {
            if isViewLoaded() {
                reload()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        reload()
    }
    
    var loadFromWeb: Bool {
        return !forceLocalLoad && serverIsReachable?.latestValue.get == true
    }
    
    func reload() {
        var url: NSURL? = nil
        if let page = page where loadFromWeb {
            url = NSURL(string: "support/\(page).html", relativeToURL: Configuration.scotTrafficBaseURL)
        } else {
            if let path = NSBundle.mainBundle().pathForResource(page, ofType: "html", inDirectory: "www") {
                url = NSURL(fileURLWithPath: path)
            }
        }
        if let url = url {
            let urlRequest = NSMutableURLRequest(URL: url)
            urlRequest.cachePolicy = .ReloadIgnoringLocalAndRemoteCacheData
            webView?.loadRequest(urlRequest)
            spinner?.startAnimating()
        } else {
            spinner?.stopAnimating()
        }
    }
}

extension WebViewController: UIWebViewDelegate {
    // -- MARK: UIWebViewDelegate

    func webViewDidFinishLoad(webView: UIWebView) {
        spinner?.stopAnimating()
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        guard let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? NSURL else {
            print("webView failed load but no failing URL: \(error)")
            return
        }
        
        if let host = failingURL.host where host == "platform.twitter.com" {
            return
        }
        
        if let host = failingURL.host where loadFromWeb && host.hasSuffix("scottraffic.co.uk") {
            forceLocalLoad = true
            reload()

        } else {
            UIApplication.sharedApplication().openURL(failingURL)
        }
    }
}
