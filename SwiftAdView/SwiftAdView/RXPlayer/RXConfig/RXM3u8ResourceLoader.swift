

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
    /// 假的链接(乱写的，前缀反正不要http或者https，后缀一定要.m3u8，中间随便)
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
        print("播放中断")
        /// 这里先保存或者结束上一个视频的缓存进程 ，还没下完，被中断 记录中断位置
        if tsManager != nil && !tsManager!.downloadSucceeded(tsManager!.directoryName) {
            tsManager!.downlodInterrupt()
            print("缓存中断")
        }
    }
    
    /// 生成AVPlayerItem
    public func playerItem(with url: URL, uriKey: String? = nil, cacheWhenPlaying: Bool? = false) -> AVPlayerItem {
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
            urlAsset = AVURLAsset(url: URL(string: m3u8_url_vir)!, options: nil)
            urlAsset.resourceLoader.setDelegate(self, queue: .main)
        } else {
            urlAsset = AVURLAsset(url: url, options: nil)
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
         print("CurrentRequest -- Url )")
        /// 获取到拦截的链接url
        guard let url = loadingRequest.request.url?.absoluteString else {
            return false
        }
        print("CurrentRequest -- Url == \(url)")
        
        /// 判断url请求是不是 ts (请求很频繁，因为一个视频分割成多个ts，直接放最前)
        if url.hasSuffix(".ts") {
            /// 处理的操作异步进行
            print("Fake_Ts -- url = \(url)")
            guard let realUrl = URL(string: m3u8_url) else { return false }
            DispatchQueue.main.async {
            /// 在这里可以对ts链接进行各种处理，（后台ts文件和m3u8文件在同一目录下）
                let newUrl = url.replacingOccurrences(of: self.m3u8_url_vir, with: realUrl.deletingLastPathComponent().absoluteString)
                
                if let url = URL(string: newUrl) {
                    //print("really--Ts--Url === \(newUrl)")
                    /// redirect: 更改(不懂？，百度翻译)，url就是新的url链接
                    loadingRequest.redirect = URLRequest(url: url)
                    /// 302: 重定向(不懂？上百度)
                    loadingRequest.response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: nil, headerFields: nil)
                    //Data.init(contentsOf: <#T##URL#>)
                    //loadingRequest.dataRequest?.respond(with: <#T##Data#>)
                //总之上面两步就是替换原先旧的网络请求，发起新的网络请求，如果不需要对ts链接进行任何操作的，屏蔽上两步
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
        
        if url == m3u8_url {
            print("true_M3u8 --Url == \(url)")
        }
        /// 判断url请求是不是 m3u8 (第一次发起的是m3u8请求，但是只请求一次，就放中间)
        if url == m3u8_url_vir {
            print("Fake_M3u8 --Url == \(url)")
            /// 处理的操作异步进行
            DispatchQueue.global().async {
            ///在这里通过请求m3u8_url链接获取m3u8的数据，其实就是一段字符串(和上面的apple_m3u8字符串相似)，将字符串直接转为Data格式，可以直接从网上下载，直接转为Data，有一点必须注意，网络请求必须是同步的，不能为异步的
                if let data = self.m3u8FileRequest(self.m3u8_url) {
                    DispatchQueue.main.async {
                        /// 获取到原始m3u8字符串
                        if let m3u8String = String(data: data, encoding: .utf8) {
                            print("M3u8_Text String ==\n\n \(m3u8String)")
                            /// 可以对字符串进行任意的修改，比如：
                            /// 1、后端对URI里面的链接进行过加密，可以在这里解密后修改替换回去
                            ///2、URI链接没进行前缀替换，前缀还是http或者https的，系统请求之后是不会在代理方法里面拦截之后的操作，这需要我们手动替换前缀，上面的字符串前缀是替换过的(还不明白的自己看上面URI里面的链接)
                            /// 3、后端对ts链接进行过加密，同1，
                            ///当然不止这3种操作，还有很多，只要你能想到，但是这些修改操作后，都必须要保证修改后的字符串，进行格式化后，还是m3u8格式的字符串
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
            print("Fake_Key--Url == \(url)")
            /// 处理的操作异步进行  http://vm.4ywc.cn/enc.key
            DispatchQueue.main.async {
                ///获取key的数据，其实也是一串字符串，如果需要验证证书之类的，用Alamofire请求吧，同上面的m3u8一样，也要同步
                /// 在这里对字符串进行任意修改，解密之类的，同上
              //  let newUrl = url.replacingOccurrences(of: self.m3u8_url_vir, with: self.enyParams[PlayerView.kKeyURL] ?? "")
               //  print("Really_Key -- url == \(newUrl)")
                if let keystr = self.URIKey ,let data = keystr.data(using: .utf8) {
                    //print("Key_Data == \(data) ---")
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


extension String {
    func urlScheme(scheme:String) -> URL? {
        if let url = URL.init(string: self) {
            var components = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = scheme
            return components?.url
        }
        return nil
    }
}