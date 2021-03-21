//
//  ActivityLabelController.swift
//  SwiftAdView
//
//  Created by mac on 2020-11-07.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit

class ActivityLabelController: UIViewController {
    
    @IBOutlet weak var labelXib: ActiveLabel!
    let label = ActiveLabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customType = ActiveType.custom(pattern: "\\sbaidu\\b") //Looks for "baidu"
        let customType2 = ActiveType.custom(pattern: "\\sit\\b") //Looks for "it"
        let customType3 = ActiveType.custom(pattern: "\\ssupports\\b") //Looks for "supports"
        
        label.enabledTypes.append(customType)
        label.enabledTypes.append(customType2)
        label.enabledTypes.append(customType3)
        
        label.urlMaximumLength = 400
        let testText = "This is a post with $multiple #hashtags @and a @userhandle. Links #are also supported like" +
            " this one: http://optonaut.co. Now it also supports custom $patterns https://github.com/shiliujiejie/adResource/raw/master/timg.jpeg -> please &link to baidu Website\n\n" +
        "Let's trim a long link: \nhttps://twitter.com/twicket_app/status/649678392372121601 "
        let attch = NSTextAttachment()
        attch.image = UIImage(named: "channelAdd")
        attch.bounds = CGRect(x: 0, y: 0, width: 18, height: 18)
        let attstr = NSAttributedString(attachment: attch)
        
        let coinatt = NSMutableAttributedString.init(string: testText)
        coinatt.append(attstr)

    
        print(" coinatt == \(coinatt)")
        label.attributedText = NSAttributedString.init(attributedString: coinatt)//NSAttributedString(string: testText)
        //label.text = testText
        label.customize { label in
            
            label.numberOfLines = 0
            label.lineSpacing = 4
            
            label.textColor = UIColor(red: 102.0/255, green: 117.0/255, blue: 127.0/255, alpha: 1)
            label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
            label.mentionColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
            label.URLColor = UIColor(red: 85.0/255, green: 151.0/255, blue: 238.0/255, alpha: 1)
            label.URLSelectedColor = UIColor(red: 82.0/255, green: 190.0/255, blue: 41.0/255, alpha: 1)
            
            label.handleMentionTap { self.alert("Mention", message: $0) }
            label.handleHashtagTap { self.alert("Hashtag", message: $0) }
            label.handleURLTap { self.alert("URL", message: $0.absoluteString) }
            
            //Custom types
            
            label.customColor[customType] = UIColor.purple
            label.customSelectedColor[customType] = UIColor.green
            label.customColor[customType2] = UIColor.magenta
            label.customSelectedColor[customType2] = UIColor.green
            
            label.configureLinkAttribute = { (type, attributes, isSelected) in
                var atts = attributes
                switch type {
                case customType3:
                    atts[NSAttributedString.Key.font] = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.boldSystemFont(ofSize: 14)
                default: ()
                }
                
                return atts
            }
            
            label.handleCustomTap(for: customType) { self.alert("Custom type", message: $0) }
            label.handleCustomTap(for: customType2) { self.alert("Custom type", message: $0) }
            label.handleCustomTap(for: customType3) { self.alert("Custom type", message: $0) }
        }
        
        label.frame = CGRect(x: 20, y: 40, width: view.frame.width - 40, height: 300)
        view.addSubview(label)
        
        
        
        /// xib
        labelXib.text = "This is a post with $multiple #hashtags @and a @userhandle. Links are also supported like this one: http://optonaut.co. Now it also supports custom patterns -> please link to baidu Website" +
        "Let's trim a long link: https://twitter.com/twicket_app/status/649678392372121601"
        labelXib.urlMaximumLength = 31
        labelXib.enabledTypes.append(customType)
        labelXib.enabledTypes.append(customType2)
        labelXib.enabledTypes.append(customType3)
        
        labelXib.customize { (label) in
            //Custom types
            label.customColor[customType] = UIColor.purple
            label.customSelectedColor[customType] = UIColor.green
            label.customColor[customType2] = UIColor.magenta
            label.customSelectedColor[customType2] = UIColor.green
        }
        
        labelXib.handleMentionTap { self.alert("Mention", message: $0) }
        labelXib.handleHashtagTap { self.alert("Hashtag", message: $0) }
        labelXib.handleURLTap { self.alert("URL", message: $0.absoluteString) }
        
        labelXib.handleCustomTap(for: customType) { self.alert("Custom type", message: $0) }
        labelXib.handleCustomTap(for: customType2) { self.alert("Custom type", message: $0) }
        labelXib.handleCustomTap(for: customType3) { self.alert("Custom type", message: $0) }
        
    }
    
    
    func alert(_ title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        vc.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(vc, animated: true, completion: nil)
    }
    
}
