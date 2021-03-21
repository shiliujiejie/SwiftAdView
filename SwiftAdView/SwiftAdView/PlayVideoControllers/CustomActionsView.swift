
import UIKit

class CustomActionsView: UIView {
    
    var itemClick:((_ index : Int) -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.removeFromSuperview()
    }
    
    deinit {
        print("CustomActionsView --- release")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(white: 0, alpha: 0.7)
        loadUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    func loadUI() {
        let sideView = UIView()
        addSubview(sideView)
        sideView.backgroundColor = UIColor(white: 1, alpha: 1)
        sideView.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing)
            } else {
                make.trailing.equalToSuperview()
            }
            make.centerY.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(UIScreen.main.bounds.height)
        }
        
        for index in 0...3 {
            let button = UIButton(type: .custom)
            button.setTitle(["X1.0", "X1.2", "X1.5","开启操作"][index], for: .normal)
            button.setTitleColor(UIColor.darkGray, for: .normal)
            button.tag = index + 100
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            button.titleEdgeInsets.left = 20
            button.addTarget(self, action: #selector(muneButtonClick(_:)), for: .touchUpInside)
            sideView.addSubview(button)
            button.snp.makeConstraints { (make) in
                make.leading.equalTo(15)
                make.trailing.equalTo(-20)
                make.top.equalTo(20+55*index)
                make.height.equalTo(40)
            }
        }
    }
    
    @objc func muneButtonClick(_ sender: UIButton) {
        print("sender.title = \(String(describing: sender.titleLabel?.text))")
        itemClick?(sender.tag - 100)
    }
    
}
