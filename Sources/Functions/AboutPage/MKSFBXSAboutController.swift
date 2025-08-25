//
//  MKSFBXSAboutController.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/4.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSAboutController: MKSwiftBaseViewController {
    
    // MARK: - Life Cycle
    deinit {
        print("MKSFBXSAboutController销毁")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Event Methods
    @objc private func openWebBrowser() {
        if let url = URL(string: "https://www.mokoblue.com") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        defaultTitle = "ABOUT"
        rightButton.isHidden = true
        
        view.addSubview(aboutIcon)
        view.addSubview(appNameLabel)
        view.addSubview(versionLabel)
        view.addSubview(bottomIcon)
        view.addSubview(companyNameLabel)
        view.addSubview(companyNetLabel)
        
        aboutIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(110)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40)
            make.height.equalTo(110)
        }
        
        appNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(aboutIcon.snp.bottom).offset(17)
            make.height.equalTo(UIFont.systemFont(ofSize: 20).lineHeight)
        }
        
        versionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(appNameLabel.snp.bottom).offset(17)
            make.height.equalTo(UIFont.systemFont(ofSize: 16).lineHeight)
        }
        
        companyNetLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(-60)
            make.height.equalTo(UIFont.systemFont(ofSize: 16).lineHeight)
        }
        
        companyNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(companyNetLabel.snp.top).offset(-17)
            make.height.equalTo(UIFont.systemFont(ofSize: 17).lineHeight)
        }
        
        if let image = bottomIcon.image {
            bottomIcon.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(image.size.width)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                make.height.equalTo(image.size.height)
            }
        }
    }
    
    // MARK: - UI Components
    private lazy var aboutIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_about_logo", in: .module)
        return imageView
    }()
    
    private lazy var appNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(20.0)
        label.text = "MK Sensor"
        return label
    }()
    
    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.rgb(189, 189, 189)
        label.textAlignment = .center
        label.font = Font.MKFont(16.0)
        label.text = "Version: V\(App.version)"
        return label
    }()
    
    private lazy var companyNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(16.0)
        label.text = "MOKO TECHNOLOGY LTD."
        return label
    }()
    
    private lazy var companyNetLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = Color.navBar
        label.font = Font.MKFont(16.0)
        label.text = "www.mokoblue.com"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openWebBrowser)))
        
        let lineView = UIView()
        lineView.backgroundColor = Color.rgb(3, 191, 234)
        label.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(155)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        return label
    }()
    
    private lazy var bottomIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.image = moduleIcon(name: "bxs_swf_aboutBottomIcon", in: .module)
        return imageView
    }()
}
