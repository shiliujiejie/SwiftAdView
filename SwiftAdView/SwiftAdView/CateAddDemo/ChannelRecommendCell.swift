//
//  ChannelRecommendCell.swift
//  News
//
//  Created by 杨蒙 on 2018/2/3.
//  Copyright © 2018年 hrscy. All rights reserved.
//

import UIKit



class ChannelRecommendCell: UICollectionViewCell {
    static let cellId = "ChannelRecommendCell"
    
    @IBOutlet weak var titleButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleButton.backgroundColor = UIColor.groupTableViewBackground
       
        layer.cornerRadius = 3
        
    }
}
