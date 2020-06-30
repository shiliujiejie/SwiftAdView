
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
    let shadow: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        return view
    }()
    let bgImage: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "placeholderH")
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        imageView.layer.masksToBounds = true
        return imageView
    }()
    lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "pause"), for: .normal)
        button.addTarget(self, action: #selector(playAction(_:)), for: .touchUpInside)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1.0
        return button
    }()
    var playActionHandle:(()->())?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Private
    func setUpUI() {
        contentView.addSubview(shadow)
        shadow.addSubview(bgImage)
        bgImage.addSubview(playButton)
        layoutPageSubviews()
       // shadow.addShadow(radius: 2, opacity: 0.5, UIColor.darkGray)
        shadow.addShadow(opacity: 1, position: 13, pathWidth: 7, .lightGray)
       
    }
    @objc func playAction(_ sender: UIButton) {
        playActionHandle?()
    }
}

// MARK: - layout
private extension TablePlayCell {
    
    func layoutPageSubviews() {
        layoutShadowBackground()
        layoutImageBackground()
        layoutPlayButton()
        
    }
    
    func layoutShadowBackground() {
        shadow.bounds = CGRect(x: 0, y: 0, width: screenWidth - 20, height: (screenWidth - 20) * 9/16)
           shadow.snp.makeConstraints { (make) in
               make.leading.equalTo(10)
               make.top.equalTo(20)
               make.trailing.equalTo(-10)
            make.bottom.equalTo((-20))
        }
    }
    func layoutImageBackground() {
        bgImage.snp.makeConstraints { (make) in
            make.top.leading.equalTo(0.5)
            make.bottom.trailing.equalTo(-0.7)
        }
    }
    func layoutPlayButton() {
        playButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(38)
            make.width.equalTo(55)
        }
    }
    
    
  
}

extension UIView {
    
    /// 添加阴影
    func addShadow(radius: CGFloat,
                   opacity: Float,
                   _ color: UIColor? = .darkGray)
    {
        self.layer.shadowColor = color?.cgColor
        self.layer.shadowOffset = CGSize()
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.masksToBounds = false
        self.clipsToBounds = false
    }
    /// 请正确设置bounds后调用， position ： （1，2，3，4）<-> (上,左,下,右) ， 0 -> 4边都加
    func addShadow(opacity: Float,
                   position: Int,
                   pathWidth: CGFloat,
                   _ color:  UIColor? = .darkGray)
    {
        self.layer.shadowColor = color?.cgColor
        self.layer.shadowOffset = CGSize()
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = pathWidth
        self.layer.masksToBounds = false
        self.clipsToBounds = false
        var shadowRect = CGRect.zero
        let orX: CGFloat = 0
        let orY: CGFloat = 0
        let size_w = self.bounds.width
        let size_h = self.bounds.height
        if position == 0 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: orY-pathWidth/2, width: size_w+pathWidth, height: size_h+pathWidth)
        } else if position == 1 {
            shadowRect = CGRect(x: orX, y: orY-pathWidth/2, width: size_w, height: pathWidth)
        } else if position == 2 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: orY, width: pathWidth, height: size_h)
        } else if position == 3 {
            shadowRect = CGRect(x: orY, y: size_h-pathWidth/2, width: size_w, height: pathWidth)
        } else if position == 4 {
            shadowRect = CGRect(x: size_w-pathWidth/2, y: orY, width: pathWidth, height: size_h)
        } else if position == 12 || position == 21 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: orY-pathWidth/2, width: size_w-2*pathWidth, height: size_h-2*pathWidth)
        } else if position == 13 || position == 31 {
            shadowRect = CGRect(x: orX+2*pathWidth, y: orY-pathWidth/2, width: size_w-4*pathWidth, height: size_h+pathWidth)
        } else if position == 14 || position == 41 {
            shadowRect = CGRect(x: 2*pathWidth, y: orY-pathWidth/2, width: size_w-1.5*pathWidth, height: size_h-2*pathWidth)
        } else if position == 23 || position == 32 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: orY+2*pathWidth, width: size_w-2*pathWidth, height: size_h-1.5*pathWidth)
        } else if position == 24 || position == 42 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: 2*pathWidth, width: size_w+pathWidth, height: size_h-4*pathWidth)
        } else if position == 34 || position == 43 {
            shadowRect = CGRect(x: 2*pathWidth, y: 2*pathWidth, width: size_w-1.5*pathWidth, height: size_h-1.5*pathWidth)
        } else if position == 123 || position == 213 || position == 321 || position == 312 || position == 132 || position == 231 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: orY-pathWidth/2, width: size_w-2*pathWidth, height: size_h+pathWidth)
        } else if position == 234 || position == 243 || position == 324 || position == 342 || position == 432 || position == 423 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: orY+2*pathWidth, width: size_w+pathWidth, height: size_h-2*pathWidth)
        } else if position == 134 || position == 143 || position == 314 || position == 341 || position == 431 || position == 413 {
            shadowRect = CGRect(x: orX+2*pathWidth, y: orY-pathWidth/2, width: size_w-2*pathWidth, height: size_h+pathWidth)
        } else if position == 124 || position == 142 || position == 214 || position == 241 || position == 421 || position == 412 {
            shadowRect = CGRect(x: orX-pathWidth/2, y: orY-pathWidth/2, width: size_w+pathWidth, height: size_h-2*pathWidth)
        }
        let bazier = UIBezierPath.init(rect: shadowRect)
        self.layer.shadowPath = bazier.cgPath
    }
    
}
