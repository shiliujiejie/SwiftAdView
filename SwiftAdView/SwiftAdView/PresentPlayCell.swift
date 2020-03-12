//
//  PresentPlayCell.swift
//  CaoLiuApp
//
//  Created by mac on 2019/3/4.
//  Copyright © 2019年 AnakinChen Network Technology. All rights reserved.
//

import UIKit

class PresentPlayCell: UICollectionViewCell {
    
    static let cellId = "PresentPlayCell"
    
    let bgImage: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    //MARK: Private
    func setUpUI() {
        contentView.addSubview(bgImage)
        layoutPageSubviews()
    }
    
   
    
}



// MARK: - layout
private extension PresentPlayCell {
    
    func layoutPageSubviews() {
        layoutImageBackground()
        
    }
    
    func layoutImageBackground() {
        bgImage.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
  
}
