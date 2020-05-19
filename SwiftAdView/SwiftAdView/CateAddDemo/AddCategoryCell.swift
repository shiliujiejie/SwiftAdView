//
//  AddCategoryCell.swift
//  News
//
//  Created by 杨蒙 on 2018/2/3.
//  Copyright © 2018年 hrscy. All rights reserved.
//

import UIKit

protocol AddCategoryCellDelagate: class {
    func deleteCategoryButtonClicked(of cell: AddCategoryCell)
}

class AddCategoryCell: UICollectionViewCell {
    static let cellId = "AddCategoryCell"

    weak var delegate: AddCategoryCellDelagate?
    
    var isEdit = false {
        didSet {
            deleteCategoryButton.isHidden = !isEdit
            if titleButton.titleLabel!.text! == "推荐" || titleButton.titleLabel!.text! == "热点" {
                deleteCategoryButton.isHidden = true
            }
        }
    }
    
    @IBOutlet weak var titleButton: UIButton!
    
    @IBOutlet weak var deleteCategoryButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        titleButton.backgroundColor = UIColor(white: 245/255, alpha: 1)
    }

    @IBAction func deleteCategoryButtonClicked(_ sender: UIButton) {
        delegate?.deleteCategoryButtonClicked(of: self)
    }
}
