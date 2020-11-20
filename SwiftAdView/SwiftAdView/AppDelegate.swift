
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }
    
    //  整个项目支持竖屏，播放页面需要横屏，导入播放器头文件，添加下面方法：
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?)
        -> UIInterfaceOrientationMask {
            guard let num = R_PlayerOrietation(rawValue: orientationSupport.rawValue) else {
                return [.portrait]
            }
            return num.getOrientSupports()           // 这里的支持方向，做了组件化的朋友，实际项目中可以考虑用路由去播放器内拿，
    }
}

let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height
let statusBarHeight: CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone" ? 44 : 20)
let screenFrame: CGRect = UIScreen.main.bounds
let safeAreaTopHeight:CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone" ? 88 : 64)
let safeAreaBottomHeight:CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone"  ? 34 : 0)
































































/*   open == 1 cOpen ==1
 
< c == 5 >
 
 scAp7yQSoRqI2wOTSeSD2GATDwGSpEttTSCXYrWmoVcC65w0Lf8yD9AbrijqWtT2pdUZOvGisyEWtih4VIFyqGchMrxkEy6xDsgoflhCsAV/jvszRV+ND3N1a20EdlcaxSFrDvdAkG3FLgNCHQAYo03a6rT5iKffsjMsjwgPI9DTzZfqeqGuwflS/clCxKnRPF3LpOCyv5I5IUflkQS3W3xlP+6GfZ3G6wE+cpkdOITGBKYQflCsBUmS7HEAwbDF03ozeQgI392kaVNnQaCDxHavxjNM5mJRIfAsDpb8JXw5dK+zmKOi2f7w9Wv9hLXOsJAJM/PGGUTd5cWQADb5afSkgmadpCjXZH8bLBpWM1FDocsDVqycZC6L2//e84wcUgmGGVckHnTbwxxMHSpMbvfsoVE6a49YZbbtqCy03f/Lr03ODKp/x4lTpAdrzv9gaNbsUW9KKuV5sLiQGIfnJucFkFl71ebRdr3wAqi5RN8=
 < c == 10 >
 HPPXQHB0qBbin0xdJ8K8EjPM0Y6xeD+3F0HYNsQE40eYrz4URE+6Udl/xK6u24CVoPGAVnbNMU86S222TGKamaVODiBd9ajrUcBIuAgr+Sr8UUEZISW6XNSzryxun/OLf477M0VfjQ9zdWttBHZXGnqx6m3tzgnditVbqMLf0lzZO3z6R+VMsGxUd+8KS4geLM0MLNZztaK87I9yoq5jPpJtJjAPw2WDJFRIFdMx/zAM/aN8Fw1IyCOATPFXVfVj0GWgKUznhtsvShjGZ6VLD0c+B8T97BvspLON9aoXuPa/zl7ri3jng1a2RJGFxINwwtpKO2bDVzIpmbDGu6qxV7yElNMG4Dtrqe4gTWvI4ozw16ssd6DpJGOQwWez+69KGDFw8sXEKmGBv4KuBT7IzFo9XY3jx6Yiu76VlRCnrXtKnyXKigNARDATt5s8xFUYiQsvQyIafFtZChY31J8h1n0XMNsZpMKo4mAQRXg76wz37KFROmuPWGW27agstN3/y69Nzgyqf8eJU6QHa87/YKlysBR5kt/5AqZSWXeBgNlQBGl5sVfQdlyi3IXZF/4Zfd1Rg37PEnQXYH7kBIfryw==
 < c == 20 >
 HPPXQHB0qBbin0xdJ8K8EjPM0Y6xeD+3F0HYNsQE40eYrz4URE+6Udl/xK6u24CVoPGAVnbNMU86S222TGKamaVODiBd9ajrUcBIuAgr+Srr5UQiQMCEV9b4OE4rxx6zf477M0VfjQ9zdWttBHZXGnqx6m3tzgnditVbqMLf0lzZO3z6R+VMsGxUd+8KS4geLM0MLNZztaK87I9yoq5jPpJtJjAPw2WDJFRIFdMx/zAM/aN8Fw1IyCOATPFXVfVj0GWgKUznhtsvShjGZ6VLD0c+B8T97BvspLON9aoXuPa/zl7ri3jng1a2RJGFxINwwtpKO2bDVzIpmbDGu6qxV7yElNMG4Dtrqe4gTWvI4ozw16ssd6DpJGOQwWez+69KGDFw8sXEKmGBv4KuBT7IzFo9XY3jx6Yiu76VlRCnrXtKnyXKigNARDATt5s8xFUYiQsvQyIafFtZChY31J8h1n0XMNsZpMKo4mAQRXg76wz37KFROmuPWGW27agstN3/y69Nzgyqf8eJU6QHa87/YKlysBR5kt/5AqZSWXeBgNlQBGl5sVfQdlyi3IXZF/4Zfd1Rg37PEnQXYH7kBIfryw==
 */

/*  open == 1 cOpen ==0 HPPXQHB0qBbin0xdJ8K8EjPM0Y6xeD+3F0HYNsQE40eYrz4URE+6Udl/xK6u24CV1NtZDoazSBl+n/LRQVGWLKVODiBd9ajrUcBIuAgr+SpVYbe72OzRIjBkgSvwImocTZeJuQ5/vX1AMzJl66TYpBe62E5j6zHmpUt2Zdw+Q+fSrQHuECnUjGGhUxcMDDYN2rV80MHf2S5/+6EsqbqhPxvDhBH7hym/9NEi5rKoSXhKyow1Gm81QKLRFetHc7nRrkrIwJWrX9wUCVMiIM5zkVFmLOf/+OFSKirC+H3ImQDHduBbJ2qJRfwdr1IsIiSheuOj0Myeqq5NQI6YeLn0txkIrXk+S6lFf1n8lTGkWBLWI3jJUtU7AGWpLl8KeDqJtXKi0ZMAK5O2Vj7uIvNCf6bcW/G2aHmAtVkhNmo+tqW7/AXQARM5s5d9XdkH8CfDgZcb3Q6YvO+ixnymkRVxSlzUYtkSdFXgOkkVHDNvslCspOuljUh+02Svj795bi/jVDEWgUwVBdYWIcPhIEvd7ozt0yyQ4VRARDtlTEIRl9EvMoQjvMsJXA6Q6fBhIxnLLFFIn9H0C8wwz9ufan9bDQ==
 */

/*  open == 0 cOpen ==0 Zn9+TM7jhYZgkDFPvkBwx2ATDwGSpEttTSCXYrWmoVcC65w0Lf8yD9AbrijqWtT2sez1D2IQKodb2vZ/BOXqqmchMrxkEy6xDsgoflhCsAV/jvszRV+ND3N1a20EdlcaxSFrDvdAkG3FLgNCHQAYo03a6rT5iKffsjMsjwgPI9DTzZfqeqGuwflS/clCxKnRPF3LpOCyv5I5IUflkQS3W3xlP+6GfZ3G6wE+cpkdOITGBKYQflCsBUmS7HEAwbDF03ozeQgI392kaVNnQaCDxHavxjNM5mJRIfAsDpb8JXw5dK+zmKOi2f7w9Wv9hLXOsJAJM/PGGUTd5cWQADb5afSkgmadpCjXZH8bLBpWM1FDocsDVqycZC6L2//e84wcUgmGGVckHnTbwxxMHSpMbvfsoVE6a49YZbbtqCy03f/Lr03ODKp/x4lTpAdrzv9gaNbsUW9KKuV5sLiQGIfnJucFkFl71ebRdr3wAqi5RN8=
 */










 // enptyKey: A7D9083Bo6d1F6
 
/* {
 "isOpen":1,
 "probability":2,
 "isChannelOpen":1,
 "channelProbability":5,
 "ksCodes":[
     {
         "code":"TZ3VF",
         "id":"wp001"
     },
     {
         "code":"ZW3VF",
         "id":"wp001"
     }
 ],
 "dyProCodes":[
     {
         "code":"Z6D5F",
         "id":"dy001"
     },
     {
         "code":"CBD5F",
         "id":"dy002"
     }
 ]
} */
