
import UIKit

class ChannelRecommendCell: UICollectionViewCell {
    static let cellId = "ChannelRecommendCell"
    
    @IBOutlet weak var titleButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleButton.backgroundColor = UIColor(white: 245/255, alpha: 1)
       
        //titleButton.layer.cornerRadius = 22
        
    }
}
