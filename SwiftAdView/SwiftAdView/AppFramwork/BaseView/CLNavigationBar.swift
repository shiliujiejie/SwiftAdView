
import UIKit

public protocol CLNavigationBarDelegate: NSObjectProtocol {
    func backAction()
}

class CLNavigationBar: UIView {
    
    weak open var delegate: CLNavigationBarDelegate?
    
    lazy var bgImageView: UIImageView = {
        let image = UIImageView()
        image.isUserInteractionEnabled = true
        image.backgroundColor = UIColor.clear
        return image
    }()
    lazy var navBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    lazy var titleLabel: UILabel = {
        let lable = UILabel()
        lable.textAlignment = .center
        lable.textColor = UIColor.white
        lable.font = UIFont.boldSystemFont(ofSize: 18)
        return lable
    }()
    lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "navBackBlack"), for: .normal)
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return button
    }()
    let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = ConstValue.kCoverBgColor
        return view
    }()
    var navBackBlack: Bool = true {
        didSet {
            if navBackBlack {
                 backButton.setImage(UIImage(named: "navBackBlack"), for: .normal)
            } else {
                backButton.setImage(UIImage(named: "navBackWhite"), for: .normal)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        p_setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func p_setup() {
        addSubview(bgImageView)
        addSubview(navBarView)
        addSubview(backButton)
        navBarView.addSubview(titleLabel)
        navBarView.addSubview(lineView)
        layoutPageSubviews()
    }

    @objc func backAction() {
        delegate?.backAction()
    }
}

// MARK: - Layout
private extension CLNavigationBar {
    
    func layoutPageSubviews() {
        layoutBgImageView()
        layoutNavBarView()
        layoutBackButton()
        layoutTitleLable()
        layoutLineView()
    }
    
    func layoutBackButton() {
        backButton.snp.makeConstraints { (make) in
            make.leading.equalTo(10)
            make.top.equalTo(ConstValue.kStatusBarHeight + 5)
            make.bottom.equalToSuperview().offset(-5)
            make.width.equalTo(34)
        }
    }
    
    func layoutTitleLable() {
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(screenWidth - 145)
        }
    }
    
    func layoutBgImageView() {
        bgImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func layoutNavBarView() {
        navBarView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(ConstValue.kStatusBarHeight)
        }
    }
    
    func layoutLineView() {
        lineView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}


