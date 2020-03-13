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
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "playCellBg")
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


class TablePlayCell: UITableViewCell {
    
    static let cellId = "TablePlayCell"
    
    let bgImage: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "playCellBg")
        return imageView
    }()
//    lazy var playButton: UIButton = {
//        let button = UIButton(type: .custom)
//        button.setImage(UIImage(named: "navbackWhite"), for: .normal)
//        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
//        return button
//    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
private extension TablePlayCell {
    
    func layoutPageSubviews() {
        layoutImageBackground()
        
    }
    
    func layoutImageBackground() {
        bgImage.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
  
}
