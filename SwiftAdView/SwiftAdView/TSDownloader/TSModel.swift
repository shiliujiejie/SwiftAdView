
import UIKit

class TSModel: NSObject {
    /// ts时长
    var duration: Float = 0.0
    /// ts路径
    var tsUrl: String = ""
    /// 索引
    var index: Int = 0
}

/// ts视频片段列表model
class TSListModel: NSObject {
    var tsModelArray = [TSModel]()
    var length = 0
    var duration: Float = 0.0
    var identifier: String = ""
    
    func initTsList(with tsList: [TSModel]) {
        tsModelArray = tsList
        length = tsList.count
    }
}
