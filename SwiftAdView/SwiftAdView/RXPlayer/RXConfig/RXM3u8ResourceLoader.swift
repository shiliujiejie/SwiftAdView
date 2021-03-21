

import UIKit
import AVKit

class RXM3u8ResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    
    /// 单例
    fileprivate static let instance = RXM3u8ResourceLoader()
    /// 获取单例
    public static var shared: RXM3u8ResourceLoader {
        get {
            return instance
        }
    }
    /// 假的链接(前缀不要http或者https，后缀一定要.m3u8，中间随便)
    fileprivate let m3u8_url_vir = "scheme://fake.m3u8"
    /// 真的链接
    fileprivate var m3u8_url: String = ""
    /// 真实的加密密钥
    private var URIKey: String?
    /// 是否播放时缓存
    private var cacheWhenPlaying: Bool = false
    var tsManager: TSManager?
    
    /// 播放中断
    public func interruptPlay() {
        NLog("播放中断")
        /// 这里先保存或者结束上一个视频的缓存进程 ，还没下完，被中断 记录中断位置
        if tsManager != nil && !tsManager!.downloadSucceeded(tsManager!.directoryName) {
            tsManager!.downlodInterrupt()
            NLog("缓存中断")
        }
    }
    
    /// 生成AVPlayerItem
    public func playerItem(with url: URL, uriKey: String? = nil, httpHeaderFieldsKey: [String: Any]? = nil, cacheWhenPlaying: Bool? = false) -> AVPlayerItem {
        URIKey = uriKey
        m3u8_url = url.absoluteString
       
        self.cacheWhenPlaying = cacheWhenPlaying ?? false
        /// 这里先保存或者结束上一个视频的缓存进程 ，还没下完，被中断 记录中断位置
        if tsManager != nil && !tsManager!.downloadSucceeded(tsManager!.directoryName) {
            tsManager!.downlodInterrupt()
        }
        if self.cacheWhenPlaying {
            
            tsManager = TSManager()
            tsManager!.m3u8URL = m3u8_url
            tsManager!.directoryName = m3u8_url.md5()
            if !tsManager!.downloadSucceeded(m3u8_url.md5()) { // 未完成
                if tsManager!.isInterruptTask(m3u8_url.md5()) { /// 是否中断下载
                    //这里无需处理uri,因为"key.key"文件在第一个ts下载之前就会存在
                    tsManager!.downloadFromLastInterruptedIndex()
                } else {
                    if URIKey != nil && !URIKey!.isEmpty {
                        tsManager!.download(URIKey)
                    } else {
                        tsManager!.download()
                    }
                }
            }
        }
        var urlAsset: AVURLAsset
        if URIKey != nil {
            /// 用虚假的m3u8(m3u8_url_vir)进行初始化 原因是：外界传进来的url有可能不是以.m3u8结尾的，即不是m3u8格式的链接，如果直接用url进行初始化，那么代理方法拦截时，系统不会以m3u8文件格式去处理拦截的url，就是系统只会发起一次网络请求，之后的操作完全无效，而用虚假的m3u8链接，是为了混淆系统，让系统直接认为我们请求的链接就是m3u8格式的链接，那么代理里面的拦截就会执行下去，真正的请求链接通过赋值给变量m3u8_url进行保存，只需要在代理方法里面发起真正的链接请求就行了
            urlAsset = AVURLAsset(url: URL(string: m3u8_url_vir)!, options: httpHeaderFieldsKey)
            urlAsset.resourceLoader.setDelegate(self, queue: .main)
        } else {
            urlAsset = AVURLAsset(url: url, options: httpHeaderFieldsKey)
        }
        let item = AVPlayerItem(asset: urlAsset)
        if #available(iOS 9.0, *) {
            item.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        }
        return item
    }
    
    /// 拦截代理方法
    ///true代表意思：系统，你要等等，不能播放，需要等我通知，你才能继续（相当于系统进程被阻断，直到收到了某些消息，才能继续运行）
    /// false代表意思：系统，你不要等，直接播放
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        NLog("CurrentRequest -- Url )")
        /// 获取到拦截的链接url
        guard let url = loadingRequest.request.url?.absoluteString else {
            return false
        }
        NLog("CurrentRequest -- Url == \(url)")
        
        /// 判断url请求是不是 ts (请求很频繁，因为一个视频分割成多个ts，直接放最前)
        if url.hasSuffix(".ts") {
            /// 处理的操作异步进行
            NLog("Fake_Ts -- url = \(url)")
            guard let realUrl = URL(string: m3u8_url) else { return false }
            DispatchQueue.main.async {
            /// 在这里可以对ts链接进行各种处理，（后台ts文件和m3u8文件在同一目录下）
                let newUrl = url.replacingOccurrences(of: self.m3u8_url_vir, with: realUrl.deletingLastPathComponent().absoluteString)
                
                if let url = URL(string: newUrl) {
                    NLog("real--Ts--Url === \(newUrl)")
                    /// redirect: 更改(不懂？，百度翻译)，url就是新的url链接
                    loadingRequest.redirect = URLRequest(url: url)
                    /// 302: 重定向(不懂？上百度)
                    loadingRequest.response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: nil, headerFields: nil)
                /// 通知系统请求结束
                    loadingRequest.finishLoading()
                } else {
                    /// 通知系统请求结束，请求有误
                    self.finishLoadingError(loadingRequest)
                }
            }
            
            /// 通知系统等待
            return true
        }
        
        /// 判断url请求是不是 m3u8 (第一次发起的是m3u8请求，但是只请求一次，就放中间)
        if url == m3u8_url_vir {
            NLog("Fake_M3u8 --Url == \(url)")
            /// 处理的操作异步进行
            DispatchQueue.global().async {
                if let data = self.m3u8FileRequest(self.m3u8_url) {
                    DispatchQueue.main.async {
                        /// 获取到原始m3u8字符串
                        if let m3u8String = String(data: data, encoding: .utf8) {
                            NLog("M3u8_Text String ==\n\n \(m3u8String)")
                            /// 可以对字符串进行任意的修改，比如：
                            // 用正则表达式取出秘钥
                            let keySttr = self.regexGetSub(pattern: "URI=\"(.+?)\"", str: m3u8String)
                            /// 还原m3u8字符串
                            let newM3u8String = m3u8String.replacingOccurrences(of: keySttr, with: self.URIKey ?? "")
                            //print("Replace_M3u8String ==\n\n \(newM3u8String)")
                            /// 将字符串转化为数据
                            let data = newM3u8String.data(using: .utf8)!
                            
                            /// 将数据塞给系统
                            loadingRequest.dataRequest?.respond(with: data)
                            /// 通知系统请求结束
                            loadingRequest.finishLoading()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        /// 通知系统请求结束，请求有误
                        self.finishLoadingError(loadingRequest)
                    }
                }
            }
            /// 通知系统等待
            return true
        }
        
        /// 判断url请求是不是 key (key只请求一次，就放最后面)
        if !url.hasSuffix(".ts") && url != m3u8_url_vir {
            NLog("Fake_Key--Url == \(url)")
            /// 处理的操作异步进行  http://vm.4ywc.cn/enc.key
            DispatchQueue.main.async {
                ///获取key的数据，其实也是一串字符串，如果需要验证证书之类的，用Alamofire请求吧，同上面的m3u8一样，也要同步
                /// 在这里对字符串进行任意修改，解密之类的，同上
              //  let newUrl = url.replacingOccurrences(of: self.m3u8_url_vir, with: self.enyParams[PlayerView.kKeyURL] ?? "")
               //  print("Really_Key -- url == \(newUrl)")
                if let keystr = self.URIKey ,let data = keystr.data(using: .utf8) {
                    NLog("Key_Data == \(data)")
                    /// 将数据塞给系统
                    loadingRequest.dataRequest?.respond(with: data)
                    /// 通知系统请求结束
                    loadingRequest.finishLoading()
                } else {
                    /// 通知系统请求结束，请求有误
                    self.finishLoadingError(loadingRequest)
                }
            }
            /// 通知系统等待
            return true
        }
        /// 通知系统不用等待
        return false
    }
    
    /// 为了演示，模拟同步网络请求，网络请求获取的是数据Data
    func m3u8FileRequest(_ url: String) -> Data? {
        if let data = try? Data(contentsOf: URL(string: url)!)  {
             return data
        }
        return nil
    }
    
    /// 请求失败的，全部返回Error
    func finishLoadingError(_ loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequest.finishLoading(with: NSError(domain: NSURLErrorDomain, code: 400, userInfo: nil) as Error)
    }
    
    func regexGetSub(pattern: String, str: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options:[])
        let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex...,in: str))
        if matches.count > 0 {
            print("matches == \(matches)")
            let ss = str[Range(matches[0].range(at: 1), in: str)!]
            return String(ss)
        }
        return ""
    }
}

