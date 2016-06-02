# NHGraphCoderPro
### 本地图形验证码 先上效果（v1.0 持续更新）
##### 类似于[极验验证码](http://geetest.com)
如果对你有帮助，请亮个 star！

![image](https://raw.githubusercontent.com/iFindTA/screenshots/master/graphiccode.gif)

#### Dependency:
-  FBShimmering:facebook开源组件，[Git地址](https://github.com/facebook/Shimmer/)

#### Features:
```
1，支持本地图片作为验证码模板，无需后台支持
2，可统计验证成功、失败次数
3，不依赖于其他平台闭源SDK、framework
4，支持网络图片作为验证码模版（待实现）
```

#### Usage:
###### 使用比较简单
创建：
```ObjectiveC
	CGSize size = self.view.bounds.size;
    UIImage *img__ = [UIImage imageNamed:@"test_4.jpg"];
    NHGraphCoder *coder = [NHGraphCoder codeWithImage:img__];
    coder.center = CGPointMake(size.width*0.5, size.height*0.5);
    [coder handleGraphicCoderVerifyEvent:^(NHGraphCoder * _Nonnull cd, BOOL success) {
        NSLog(@"验证结果:%d",success);
    }];
    [self.view addSubview:coder];
```

刷新图形：
```ObjectiveC
	[coder resetStateForDetect];
```

#### Feedback:
nanhujiaju@gmail.com