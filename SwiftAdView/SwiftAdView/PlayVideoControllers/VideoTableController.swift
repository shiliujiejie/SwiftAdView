//
//  VideoTableController.swift
//  SwiftAdView
//
//  Created by mac on 2020-03-14.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit

class VideoTableController: UIViewController {

    /// 这里用UITableView 来做， 也可以使用UICollectionView 一样的效果（纯属 个人习惯）
    lazy var tableView: UITableView = {
        let table = UITableView.init(frame: view.bounds, style: .plain)
        table.backgroundColor = UIColor.white
        table.delegate = self
        table.dataSource = self
        table.bounces = false
        table.showsVerticalScrollIndicator = false
        table.scrollsToTop = false
        table.isPagingEnabled = true
        table.register(TablePlayCell.classForCoder(), forCellReuseIdentifier: TablePlayCell.cellId)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    


}

extension VideoTableController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TablePlayCell.cellId, for: indexPath) as! TablePlayCell
        return cell
    }
    
    
}
