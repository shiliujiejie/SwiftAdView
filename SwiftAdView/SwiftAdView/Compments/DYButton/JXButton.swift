//
//  JXButton.swift
//  CaoLiuApp
//
//  Created by mac on 15/1/2020.
//  Copyright © 2020 AnakinChen Network Technology. All rights reserved.
//

import UIKit

class JXButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        self.titleLabel?.textAlignment = .center
        self.imageView?.contentMode = .scaleAspectFit
        self.titleLabel?.font = UIFont.systemFont(ofSize: 10)
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleX: CGFloat = 0
        let titleY: CGFloat = contentRect.size.height * 0.75
        let titleW: CGFloat = contentRect.size.width
        let titleH: CGFloat = contentRect.size.height - titleY
        return CGRect.init(x: titleX, y: titleY, width: titleW, height: titleH)
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageW = contentRect.size.width
        let imageH = contentRect.size.height * 0.5
        return CGRect.init(x: 0, y: 0, width: imageW, height: imageH)
    }
    
}
