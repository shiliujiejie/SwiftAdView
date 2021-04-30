

import UIKit
import SnapKit

public struct QHTabBar {
    var storyboardName: String = ""
    var title: String = ""
    var icon: String = ""
    var selectIcon: String = ""
    static func Null() -> QHTabBar {
        return QHTabBar()
    }
}

class CLTabBarController: UITabBarController, CLTabBarDataSource, CLTabBarDelegate {
    
    var tabBarView: CLTabBarView = CLTabBarView(frame: CGRect.zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        p_addTabBarView()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Private
    
    func p_addTabBarView() {
        let frame = self.tabBar.frame
        tabBarView.frame = frame
        tabBarView.dataSource = self
        tabBarView.delegate = self
        self.view.addSubview(tabBarView)
        
        self.tabBar.isHidden = true
        layoutPageSubviews()
        
    }
    
    //MARK: Public
    
    func addChildVCWithStoryboardName(tabBar: QHTabBar) {
        if tabBar.storyboardName == "Home" {
            let vc = LVMainPartController()
            addChild(vc)
        } else if tabBar.storyboardName == "Mine"  {
            let vc = AcountNewController()
            addChild(vc)
        } else if tabBar.storyboardName == "Msg" {
            let vc = ChatSessionController()
            addChild(vc)
        } else if tabBar.storyboardName == "Vip" {
            let vc = VIPPartMainController()
            addChild(vc)
        } else if tabBar.storyboardName == "Yue" {
            let vc = LFInfoMainController()
            addChild(vc)
        }
       
    }
    
    func selectIndexView(index: Int) {
        self.selectedIndex = index - 1
        self.tabBarView.selectTabBar(index: index)
    }
    
    //MARK: Util
    
    func createImageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1);
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext();
        context!.setFillColor(color.cgColor);
        context!.fill(rect);
        
        let theImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return theImage!;
    }
    
    //MARK: CLTabBarDataSource
    
    func tabBarViewForRows(_ tabBarView: CLTabBarView) -> [QHTabBar] {
        return [QHTabBar()]
    }
    
    func tabBarViewForMiddle(_ tabBarView: CLTabBarView, size: CGSize) -> UIView? {
        return nil
    }
    
    //MARK: CLTabBarDelegate
    
    func tabBarView(_ tabBarView: CLTabBarView, didSelectRowAt index: Int) {
        self.selectedIndex = index
    }

}


private extension CLTabBarController {
    func layoutPageSubviews() {
        layoutTabBar()
    }
    
    func layoutTabBar() {
        tabBarView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(tabBar.snp.top)
        }
    }
}
