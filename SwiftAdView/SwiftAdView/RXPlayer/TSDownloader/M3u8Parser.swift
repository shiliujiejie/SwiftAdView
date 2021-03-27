
import UIKit
import Alamofire

class M3u8Parser: NSObject {
    
    /// m3u8文件解析出来的文本字符串
    var m3u8Data: String = ""
    /// ts列表
    var tsModels = [TSModel]()
    /// ts列表Model
    var tsListModel = TSListModel()
    /// 标识符
    var identifier: String = ""
    /// Url Header 用于两层m3u8解析时， 拼接第二次解析的Url
    var urlHeader: String = ""
    
    /// 用于保存第一次解析前对 url Layer 的切片
    var urlM3u8Headers = [String]()
    /// 第二次解析，需要尝试解析的Urls
    var secondParseUrls = [String]()
    /// 用于保存第二次解析成功，筛选出来的有效的URL 切片
    var urlTsHeaders = [String]()
    
    /// 第一次解析出来的.m3u8后缀
    var lastM3u8File: String = ""
    
   
    
    /// 用于解析和下载的网络请求头
    var parseHtttpHeader: [String : String]?
    /// 请求方式
    var httpMethod: HTTPMethod = .get
    /// 自定义的密钥
    var URIKey: String?
    /// 第二层url地址的 当前解析 index
    var depthM3u8UrlIndex: Int = 0
    /// 当前TS index
    var currentTSIndex: Int = 0
    
    let manager = Alamofire.SessionManager.default
    
    var parseSuccessHandler:((_ tsList : TSListModel) -> Void)?
    var parseFailHandler:((_ failMsg: String) -> Void)?
    
    func parseM3u8(url: String,
                   key: String? = nil,
                   succeedHandler: @escaping (TSListModel) -> (),
                   failHandler: @escaping (_ failMessage: String) -> ())
    {
        URIKey = key
        parseSuccessHandler = succeedHandler
        parseFailHandler = failHandler
        parseFirstLayerM3u8(url)
    }
    /// 解析第一层m3u8
    ///
    /// - Parameter url: 第一层url ,唯一一个，不需要尝试拼接
    func parseFirstLayerM3u8(_ url: String) {
        //guard let m3u8ParserDelegate = delegate else { return }
        if !(url.hasPrefix("http://") || url.hasPrefix("https://")) {
            parseFailHandler?("Invalid http URL.(无效的URL链接)")
            return
        }
        // 将layerUrl 切片，为后面拼接用
        getM3u8UrlHeader(url)
        manager.session.configuration.timeoutIntervalForRequest = 10
        manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: parseHtttpHeader).responseData { (response) in
            if let alamoError = response.result.error {
                NLog("error -- \(alamoError)")
                DispatchQueue.main.async {
                     self.parseFailHandler?("<Layer> m3u8 file content first read error.")
                }
                return
            } else {
                let statusCode = (response.response?.statusCode)! //example : 200
                if statusCode == 200 {
                    if let data = response.data, let layerM3u8Content = String(data: data, encoding: .utf8) {
                        print("layerM3u8Content = \(layerM3u8Content)")
                        if layerM3u8Content.isEmpty {
                            DispatchQueue.main.async {
                                self.parseFailHandler?("m3u8链接无法转换为 字符串")
                            }
                            return
                        } else {
                            /// 第一层就解析到了ts流
                            if layerM3u8Content.range(of: "#EXTINF:") != nil {
                                print("<Layer> m3u8 can be parse, start parsing.(m3u8解析 - 修成正果)")
                                self.getTsDownloadUrlHeader(url)
                                self.sepalateRealM3u8List(layerM3u8Content, url)
                            }
                            /// 第一层解析出来没有ts流，说明有2层，解析第二层
                            if layerM3u8Content.range(of: "#EXT-X-STREAM-INF:") != nil {
                                print("<Layer> m3u8 can not be parse, parse again.")
                                var m3u8String = ""
                                let lastM3u8pes = layerM3u8Content.components(separatedBy: "\n")
                                /// 获取带.m3u8后缀的切片
                                for stringPs in lastM3u8pes {
                                    if stringPs.contains(".m3u8") {
                                        m3u8String = stringPs
                                        self.lastM3u8File = stringPs
                                    }
                                }
                                /// 拼接批量二次解析需要的第二层m3u8Url
                                if !m3u8String.isEmpty {
                                    for header in self.urlM3u8Headers {
                                        var realM3u8Url = ""
                                        if m3u8String.hasPrefix("/") {
                                            realM3u8Url = String(format: "%@%@", header, m3u8String)
                                        } else {
                                            realM3u8Url = String(format: "%@/%@", header, m3u8String)
                                        }
                                        print("secondParseUrl m3u8：\(realM3u8Url)")
                                        self.secondParseUrls.append(realM3u8Url)
                                    }
                                    /// 第二次解析
                                    self.parseDepthM3u8()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 第二次解析, 尝试去解析每一个可能的Url,只要解析到，并且包含ts流,取出ts
    func parseDepthM3u8() {
        if secondParseUrls.count <= depthM3u8UrlIndex { return }
        let depthUrl = secondParseUrls[depthM3u8UrlIndex]
        manager.request(depthUrl, method: httpMethod, parameters: nil, encoding: URLEncoding.default, headers: parseHtttpHeader).responseData { (response) in
            if let _ = response.result.error {
                NLog("<Depth> m3u8 parse failed!,Invalid m3u8 URL :\(depthUrl) ")
                if self.depthM3u8UrlIndex == self.secondParseUrls.count - 1 {
                    DispatchQueue.main.async {
                        self.parseFailHandler?("<Depth> m3u8 parse failed!")
                    }
                    self.depthM3u8UrlIndex = 0
                } else {
                    /// index + 1 继续解析
                    self.depthM3u8UrlIndex += 1
                    self.parseDepthM3u8()
                }
                return
            } else {
                let statusCode = (response.response?.statusCode)! //example : 200
                if statusCode == 200 {
                    if let data = response.data, let depthM3u8Content = String(data: data, encoding: .utf8) {
                        // 解析到
                        if !depthM3u8Content.isEmpty {
                            NLog("depthM3u8Content == \(depthM3u8Content)")
                            /// 解析到了ts流
                            if depthM3u8Content.range(of: "#EXTINF:") != nil {
                                NLog("<Depth> m3u8 url: \n \(depthUrl) \n can be parse, start parsing.(m3u8解析 - 修成正果)")
                                self.getTsDownloadUrlHeader(depthUrl)
                                self.sepalateRealM3u8List(depthM3u8Content, depthUrl)
                            } else {
                                NLog("<Depth> m3u8 parse failed!,Invalid m3u8 URL :\(depthUrl) ")
                                if self.depthM3u8UrlIndex == self.secondParseUrls.count - 1 {
                                    DispatchQueue.main.async {
                                        self.parseFailHandler?("<Depth> m3u8 parse failed!")
                                    }
                                    self.depthM3u8UrlIndex = 0
                                } else {
                                    /// index + 1 继续解析
                                    self.depthM3u8UrlIndex += 1
                                    self.parseDepthM3u8()
                                }
                            }
                        }
                    } else {
                        NLog("<Depth> m3u8 parse failed!,Invalid m3u8 URL :\(depthUrl) ")
                        if self.depthM3u8UrlIndex == self.secondParseUrls.count - 1 {
                            DispatchQueue.main.async {
                                self.parseFailHandler?("<Depth> m3u8 parse failed!")
                            }
                            self.depthM3u8UrlIndex = 0
                        } else {
                            /// index + 1 继续解析
                            self.depthM3u8UrlIndex += 1
                            self.parseDepthM3u8()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Private funcs
private extension M3u8Parser {
    
    /// 第一次切片Url
    ///
    /// - Parameter url: Layer .m3u8 url
    func getM3u8UrlHeader(_ url: String) {
        let headerPaths = url.components(separatedBy: "/")
        if headerPaths.count <= 3 {
            return
        }
        var headerUtlPath = ""
        if let lastStr = headerPaths.last {
            if var depthM3u8Header = url.components(separatedBy: lastStr).first {
                if depthM3u8Header.hasSuffix("/") {
                    depthM3u8Header.remove(at: depthM3u8Header.index(before: depthM3u8Header.endIndex))
                }
                urlM3u8Headers.append(depthM3u8Header)
                headerUtlPath = depthM3u8Header
            }
        }
        print("urlM3u8Headers == \(urlM3u8Headers)")
        getM3u8UrlHeader(headerUtlPath)
    }
    
    /// 第二次切片Url: 为ts的下载地址做准备（如果ts列表是全路径，则不需要）
    ///
    /// - Parameter url: Depth .m3u8 url
    func getTsDownloadUrlHeader(_ url: String) {
        let headerPaths = url.components(separatedBy: "/")
        if headerPaths.count <= 3 {
            //urlTsHeaders.append(tsUrlHeader)
            return
        }
        var headerUtlPath = ""
        if let lastStr = headerPaths.last {
            if var tsUrlHeader = url.components(separatedBy: lastStr).first {
                if tsUrlHeader.hasSuffix("/") {
                    tsUrlHeader.remove(at: tsUrlHeader.index(before: tsUrlHeader.endIndex))
                }
                urlTsHeaders.append(tsUrlHeader)
                headerUtlPath = tsUrlHeader
            }
        }
        getTsDownloadUrlHeader(headerUtlPath)
    }
    
}

// MARK: - Privite Funcs
private extension M3u8Parser {
    
    /// 下载秘钥/自定义密钥保存
    ///
    /// - Parameter m3u8Content: 带ts列表的有效 m3u8Content
    func downLoadKeyWith(_ m3u8Content: String) {
        if !m3u8Content.contains("#EXT-X-KEY:") { return }
        if URIKey != nil && !URIKey!.isEmpty { // 自定义密钥不为空
            writeCustomURIKeyToFile()
            return
        }
        var keySttr = ""
        // 用正则表达式取出秘钥所在 url
        keySttr = DownLoadHelper.regexGetSub(pattern: "URI=\"(.+?)\"", str: m3u8Content)
        print("KEY Data Path == \(keySttr)")
        if keySttr.isEmpty {
            print("URI - Key Url isEmpty")
            return
        }
        if keySttr.hasPrefix("http") || keySttr.hasPrefix("https") {
            // 全路径，直接下载
            downloadURIkey(keySttr)
        } else {
            for header in self.urlM3u8Headers {
                var realKeyUrl = ""
                if keySttr.hasPrefix("/") {
                    realKeyUrl = String(format: "%@%@", header, keySttr)
                } else {
                    realKeyUrl = String(format: "%@/%@", header, keySttr)
                }
                print("URI Key Url：\(realKeyUrl)")
                downloadURIkey(realKeyUrl)
            }
        }
        print("DownLoad KEY file by URI = \(keySttr) ")
    }
    /// 下载密钥文件，存入沙盒
    func downloadURIkey(_ keyUrlStr: String) {
        manager.request(keyUrlStr, method: httpMethod, parameters: nil, encoding: URLEncoding.default, headers: parseHtttpHeader).responseData { (response) in
            if let _ = response.result.error {
                print("KEY Data download < failed > - url =\(keyUrlStr)")
                return
            } else {
                let statusCode = (response.response?.statusCode)! //example : 200
                if statusCode == 200 {
                    if let dataKey = response.data, !dataKey.isEmpty {
                        DownLoadHelper.checkOrCreatedM3u8Directory(self.identifier)
                        let filePath = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(self.identifier).appendingPathComponent("key")
                        NLog("KEY Data download < Succeed >")
                        if !FileManager.default.fileExists(atPath: filePath.path) {
                            NLog("KEY Data is not exist, download and save to: \(filePath) ")
                            let success = FileManager.default.createFile(atPath: filePath.path, contents: dataKey, attributes: nil)
                            if success {
                                NLog("KEY Data write to file Succeed")
                            } else {
                                NLog("KEY Data write to file Failed! =\(dataKey.count)")
                            }
                        }
                    } else {
                        NLog("KEY Data download < failed > - < KEY Data isEmpty >")
                    }
                } else {
                    NLog("KEY Data download < failed > - url =\(keyUrlStr)")
                }
            }
        }
    }
    /// 写入自定义URI
    func writeCustomURIKeyToFile() {
        /// 这里会根据 实际情况改动，1: URIKey为一个字符串， 2: URIKey是一个http地址
        if let dataKey = URIKey!.data(using: .utf8) {
            DownLoadHelper.checkOrCreatedM3u8Directory(self.identifier)
            let filePath = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(self.identifier).appendingPathComponent("key")
            if !FileManager.default.fileExists(atPath: filePath.path) {
                print("URI Data is not exist, write custom URI Data to: \(filePath) ")
                let success = FileManager.default.createFile(atPath: filePath.path, contents: dataKey, attributes: nil)
                if success {
                    print("URI Data write to file Succeed")
                } else {
                    print("URI Data write to file Failed! =\(dataKey.count)")
                }
            }
        } else {
            print("URI Data isEmpty")
        }
    }
    
    /// 尝试去拼接路径下载第一个ts,如果下载成功，则表示路径拼对了，将正确路径的前缀返给每个Ts model
    func tryToGetRightTsPath(_ tsLastUrl: String) -> String? {
        for tsUrlHeader in urlTsHeaders {
            var maybeRightUrl = ""
            if tsLastUrl.hasPrefix("/") {
                maybeRightUrl = String(format: "%@%@", tsUrlHeader,tsLastUrl)
            } else {
                maybeRightUrl = String(format: "%@/%@", tsUrlHeader,tsLastUrl)
            }
            if let _ = try? Data(contentsOf: URL(string: maybeRightUrl)!) {
                print("correct Ts downloadUrl = \(maybeRightUrl)")
                return tsUrlHeader
            } else {
                print("current TS download url is not correct.:\(maybeRightUrl)")
            }
        }
        return nil
    }
    
    /// 拆分m3u8文件，取出ts 和秘钥等
    func sepalateRealM3u8List(_ m3u8Content: String, _ url: String) {
        self.m3u8Data = m3u8Content
        currentTSIndex = 0
        if tsModels.count > 0 { tsModels.removeAll() }
        downLoadKeyWith(m3u8Content)
        
        let segmentRange = m3u8Content.range(of: "#EXTINF:")!
        let segmentsString = String(m3u8Content.suffix(from: segmentRange.lowerBound)).components(separatedBy: "#EXT-X-ENDLIST")
        var segmentArray = segmentsString[0].components(separatedBy: "\n")
        segmentArray = segmentArray.filter { !$0.contains("#EXT-X-DISCONTINUITY") }
        var rightTsUrl = ""
        if segmentArray.count > 2 {
            let segmentURL = segmentArray[1]
            /// ts 路径非全路径
            if !(segmentURL.hasPrefix("http://") || segmentURL.hasPrefix("https://")) {
                // 拼接url 全路劲
                rightTsUrl = tryToGetRightTsPath(segmentURL) ?? ""
                if rightTsUrl.isEmpty {
                    print("The correct ts download url was not found, maybe download failed.")
                    //return
                }
            }
        }
        print("right -TS - URLHeader = \(rightTsUrl)")
        /// 分割 m3u8文件，拼接TS model
        while (segmentArray.count > 2) {
            let tsModel = TSModel()
            let segmentDurationPart = segmentArray[0].components(separatedBy: ":")[1]
            var segmentDuration: Float = 0.0
            
            if segmentDurationPart.contains(",") {
                segmentDuration = Float(segmentDurationPart.components(separatedBy: ",")[0])!
            } else {
                segmentDuration = Float(segmentDurationPart)!
            }
            tsModel.duration = segmentDuration
            var segmentURL = segmentArray[1]
            /// ts 路径非全路径
            if !(segmentURL.hasPrefix("http://") && !segmentURL.hasPrefix("https://")) {
                // 拼接url 全路劲
                if segmentURL.hasPrefix("/") {
                    segmentURL = String(format: "%@%@", rightTsUrl,segmentURL)
                } else {
                    segmentURL = String(format: "%@/%@", rightTsUrl,segmentURL)
                }
            }
            tsModel.tsUrl = segmentURL
            //print("tsModel.tsUrl ==== \(segmentURL)")
            tsModel.index = currentTSIndex
            tsModels.append(tsModel)
            segmentArray.remove(at: 0)
            segmentArray.remove(at: 0)
            currentTSIndex += 1
        }
        tsListModel.initTsList(with: tsModels)
        tsListModel.identifier = identifier
        var allTSDurations: Float = 0.0
        for tsModel in tsModels {
            allTSDurations += tsModel.duration
        }
        NLog("当前视频TS个数为 = \(tsListModel.tsModelArray.count)，总时长：\(allTSDurations)秒")
        tsListModel.duration = allTSDurations
        DispatchQueue.main.async {
            self.parseSuccessHandler?(self.tsListModel)
        }
    }
}

