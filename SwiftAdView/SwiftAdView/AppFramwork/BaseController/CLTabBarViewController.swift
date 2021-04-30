

import UIKit
import AssetsLibrary
import Photos

class CLTabBarViewController: CLTabBarController {
    
    var dataArray: [QHTabBar] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController?.setNavigationBarHidden(true, animated: false);
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        self.view.backgroundColor = UIColor.clear
        
        p_setup()
    }
    
   
    
    //MARK: Private
    
    func p_setup() {
        let tabBarHome = QHTabBar.init(storyboardName: "Home", title: "首页", icon: "tb_home_n", selectIcon: "tb_home_s")
        let tabBarVip = QHTabBar.init(storyboardName:"Vip", title: "会员", icon: "tb_vip_n", selectIcon: "tb_vip_s")
        let tabBarYue = QHTabBar.init(storyboardName: "Yue", title: "约啪", icon: "tb_yuepa_n", selectIcon: "tb_yuepa_s")
        let tabBarSearch = QHTabBar.init(storyboardName: "Msg", title: "消息", icon: "tb_msg_n", selectIcon: "tb_msg_s")
        let tabBarMine = QHTabBar.init(storyboardName: "Mine", title: "我的", icon: "tb_mine_n", selectIcon: "tb_mine_s")
        dataArray = [tabBarHome,tabBarYue,tabBarVip,tabBarSearch,tabBarMine]
        
        for value in dataArray {
            addChildVCWithStoryboardName(tabBar: value)
        }
        self.tabBarView.reloadData()
        self.selectIndexView(index: 1)
        p_setTabBarViewColor()
    }
    
    func p_setTabBarViewColor() {
        self.tabBarView.backgroundColor = UIColor.colorGradientChangeWithSize(size: CGSize(width: screenWidth, height: safeAreaBottomHeight + 49), direction: .vertical, startColor: ConstValue.kCoverBgColor, endColor: ConstValue.kVcViewColor)
//        if self.selectedIndex == 0 {
//            self.tabBarView.backgroundColor = ConstValue.kVcViewColor
//        }
//        else {
//            self.tabBarView.backgroundColor = UIColor.colorGradientChangeWithSize(size: CGSize(width: screenWidth, height: safeAreaBottomHeight + 49), direction: .vertical, startColor: rgba(15, 15, 29, 0.5), endColor: ConstValue.kVcViewColor) //ConstValue.kVcViewColor
//        }
//        if self.navigationController?.viewControllers.first is CLRootScrollViewController {
//            let vc = self.navigationController?.viewControllers.first as! CLRootScrollViewController
//            vc.mainScrollV.isScrollEnabled = false
//        }
        // addGradientLayer()
    }
    //初始化gradientLayer并设置相关属性
    func addGradientLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        //设置渐变的主颜色
        gradientLayer.colors = [UIColor.lightGray.cgColor,UIColor.clear.cgColor]
        gradientLayer.locations = [0.1,1.0]
        //将gradientLayer作为子layer添加到主layer上
        self.tabBarView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    //MARK: Action
    
    func navigationControllerShouldPush() -> Bool {
        if selectedIndex == 0 {
            return true
        }
        return false
    }
    
    func navigationControllerDidPushBegin() -> Bool {
        let b = false
        switch selectedIndex {
        case 0: do {
        }
            break
        case 1:
            break
        case 2:
            break
        case 3:
            break
        default:
            break
        }
        return b
    }
    
    //MARK: CLTabBarDataSource
    override func tabBarViewForRows(_ tabBarView: CLTabBarView) -> [QHTabBar] {
        return dataArray
    }
    
    ///加号按钮
    override func tabBarViewForMiddle(_ tabBarView: CLTabBarView, size: CGSize) -> UIView? {
//
//        let hd = CGFloat(9.0)
//        let w = 45 as CGFloat
//        let wd = CGFloat(size.width - 45)/2
//        let h = CGFloat(30)
//        let middleBtn = UIButton(frame: CGRect(x: wd, y: hd, width: w, height:h))
//        middleBtn.setImage(getImage("centerIcon"), for: .normal)
//        middleBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
//        middleBtn.backgroundColor = UIColor.clear
//        middleBtn.addTarget(self, action: #selector(self.goRecordViewAction(_:)), for: .touchUpInside)
//
//        return middleBtn
        return nil
    }
    
    //MARK: CLTabBarDelegate
    override func tabBarView(_ tabBarView: CLTabBarView, didSelectRowAt index: Int) {
        if self.selectedIndex == index {
            //let vc = self.children[selectedIndex]
            switch selectedIndex {
            case 0: do {
               // let v: HomeViewController = vc as! HomeViewController
                //v.mainCV.reloadData()
                //v.mainCV.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
            }
                break
            case 1:
                break
            case 2:
                break
            case 3:
                break
            default:
                break
            }
        }
        else {
            self.selectedIndex = index
            p_setTabBarViewColor()
        }
    }
    
    //MARK: Action
    ///加号按钮的点击事件
    @objc func goRecordViewAction(_ sender: Any) {
        DLog("center add")
       // choseVideoFromLibrary()
    }
    /// 从相册选择视频
    func choseVideoFromLibrary() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Thumbnail", bundle: nil)
        let vc: ThumbnailViewController = storyboard.instantiateViewController(withIdentifier: "Thumbnail") as! ThumbnailViewController
        let nav = CLNavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
}


