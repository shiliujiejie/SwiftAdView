//
//  WebViewController.swift
//  WKWebViewJSForSwift
//
//  Created by 小星星 on 2018/8/16.
//  Copyright © 2018年 yangxin. All rights reserved.
//

import UIKit
import WebKit

class WebKitController: UIViewController {
    
    private let titleKeyPath = "title"
    private let estimatedProgressKeyPath = "estimatedProgress"
    private let kScreenHeight = UIScreen.main.bounds.size.height
    private let kScreenWdith = UIScreen.main.bounds.size.width
    
    private lazy var wkConfig: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        let script = WKUserScript.init(source: "", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        return config
    }()
    private lazy var refreshView: UIRefreshControl = {
        let ref = UIRefreshControl()
        ref.tintColor = UIColor.green
        ref.addTarget(self, action: #selector(refreshWebView), for: .valueChanged)
        return ref
    }()
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: kScreenWdith, height: kScreenHeight), configuration: wkConfig)
        webView.addObserver(self, forKeyPath: titleKeyPath, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: estimatedProgressKeyPath, options: .new, context: nil)
        webView.allowsBackForwardNavigationGestures = true
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
        }
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.backgroundColor = UIColor.white
        return webView
    }()
    private lazy final var progressBar: UIProgressView = {
        let progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.backgroundColor = .clear
        progressBar.trackTintColor = .clear
        progressBar.progressTintColor = .green
        return progressBar
    }()
    
    private var openUrl: URL?
    
    public var displaysWebViewTitle: Bool? = true
    
    deinit {
        print("vc is deinit")
        webView.removeObserver(self, forKeyPath: titleKeyPath, context: nil)
        webView.removeObserver(self, forKeyPath: estimatedProgressKeyPath, context: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(url: URL, _ displayTitle: Bool? = true) {
        displaysWebViewTitle = displayTitle
        openUrl = url
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        loadWebUrl()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.stopLoading()
    }
    
    /// layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
        
        let isIOS11 = ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 11, minorVersion: 0, patchVersion: 0))
        let top = isIOS11 ? CGFloat(0.0) : topLayoutGuide.length
        let insets = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        webView.scrollView.contentInset = insets
        webView.scrollView.scrollIndicatorInsets = insets
        
        view.bringSubviewToFront(progressBar)
        progressBar.frame = CGRect(x: view.frame.minX,
                                   y: topLayoutGuide.length,
                                   width: view.frame.size.width,
                                   height: 2)
    }
    
    private func setUpUI() {
        view.addSubview(webView)
        view.addSubview(progressBar)
        if #available(iOS 10.0, *) {
            webView.scrollView.refreshControl = refreshView
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                            target: self,
                                                            action: #selector(didTapActionButton(_:)))
    }
    
    /// 加载网页
    private func loadWebUrl() {
        //let resouce = Bundle.main.path(forResource: "test", ofType: "html")
        if openUrl != nil {
            webView.load(URLRequest(url: openUrl!))
        }
    }
    
    /// refresh
    @objc private func refreshWebView() {
        if #available(iOS 10.0, *) {
            self.webView.scrollView.refreshControl?.endRefreshing()
        }
        self.webView.reload()
    }
    
    @objc private func didTapActionButton(_ sender: UIBarButtonItem) {
        if let url = webView.url {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = sender
            present(activityVC, animated: true, completion: nil)
        }
    }
  
}

// MARK: - KVO
extension WebKitController {
    
    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {
        guard let theKeyPath = keyPath , object as? WKWebView == webView else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if (displaysWebViewTitle ?? true) && theKeyPath == titleKeyPath {
            title = webView.title
        }
        
        if theKeyPath == estimatedProgressKeyPath {
            updateProgress()
        }
    }
    
    // MARK: Private
    
    private final func updateProgress() {
        let completed = webView.estimatedProgress == 1.0
        progressBar.setProgress(completed ? 0.0 : Float(webView.estimatedProgress), animated: !completed)
        UIApplication.shared.isNetworkActivityIndicatorVisible = !completed
    }
}
