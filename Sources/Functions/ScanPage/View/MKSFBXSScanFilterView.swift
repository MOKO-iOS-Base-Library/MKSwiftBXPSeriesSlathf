//
//  MKSFBXSScanFilterView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/27.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSScanFilterView: UIView {
    
    // MARK: - Constants
    private let offsetX: CGFloat = 10.0
    private let backViewHeight: CGFloat = 370.0
    private let signalIconWidth: CGFloat = 17.0
    private let signalIconHeight: CGFloat = 15.0
    private let noteMsg1 = "* RSSI filtering is the highest priority filtering condition. BLE Name filtering must first meet the RSSI filtering condition."
    
    // MARK: - Properties
    private var searchBlock: ((String, String, Int) -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = UIColor(white: 0, alpha: 0.1)
        setupUI()
        addTapAction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("MKSFBXSScanFilterView销毁")
    }
    
    // MARK: - Public Methods
    class func showSearchName(_ name: String, tagID: String, rssi: Int, searchBlock: @escaping (String, String, Int) -> Void) {
        let view = MKSFBXSScanFilterView()
        view.showSearchName(name, tagID: tagID, rssi: rssi, searchBlock: searchBlock)
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        addSubview(backView)
        backView.addSubview(nameLabel)
        backView.addSubview(nameTextField)
        backView.addSubview(tagLabel)
        backView.addSubview(tagTextField)
        backView.addSubview(minRssiLabel)
        backView.addSubview(rssiValueLabel)
        backView.addSubview(signalIcon)
        backView.addSubview(graySignalIcon)
        backView.addSubview(slider)
        backView.addSubview(minLabel)
        backView.addSubview(maxLabel)
        backView.addSubview(noteLabel1)
        backView.addSubview(doneButton)
        
        let backViewWidth = Screen.width - 2 * offsetX
        let textFieldPositionX = offsetX + 100 + 5
        let textFieldWidth = backViewWidth - textFieldPositionX - offsetX
        let nameLabelPositionY: CGFloat = 10
        let tagLabelPositionY = nameLabelPositionY + 30 + 10
        let textSpaceY: CGFloat = 30 + 10
        let signalIconPositionY = tagLabelPositionY + textSpaceY + 25 + 30
        
        backView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.top.equalToSuperview().offset(-backViewHeight)
            make.width.equalTo(backViewWidth)
            make.height.equalTo(backViewHeight)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.top.equalToSuperview().offset(nameLabelPositionY)
            make.width.equalTo(100)
            make.height.equalTo(30)
        }
        
        nameTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(textFieldPositionX)
            make.top.equalToSuperview().offset(nameLabelPositionY)
            make.width.equalTo(textFieldWidth)
            make.height.equalTo(30)
        }
        
        tagLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.top.equalToSuperview().offset(tagLabelPositionY)
            make.width.equalTo(100)
            make.height.equalTo(30)
        }
        
        tagTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(textFieldPositionX)
            make.top.equalToSuperview().offset(tagLabelPositionY)
            make.width.equalTo(textFieldWidth)
            make.height.equalTo(30)
        }
        
        minRssiLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.top.equalToSuperview().offset(tagLabelPositionY + textSpaceY)
            make.width.equalTo(100)
            make.height.equalTo(25)
        }
        
        rssiValueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(textFieldPositionX)
            make.top.equalToSuperview().offset(tagLabelPositionY + textSpaceY)
            make.width.equalTo(textFieldWidth)
            make.height.equalTo(25)
        }
        
        signalIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.top.equalToSuperview().offset(signalIconPositionY)
            make.width.equalTo(signalIconWidth)
            make.height.equalTo(signalIconHeight)
        }
        
        slider.snp.makeConstraints { make in
            make.leading.equalTo(signalIcon.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(signalIconPositionY)
            make.trailing.equalTo(graySignalIcon.snp.leading).offset(-10)
            make.height.equalTo(signalIconHeight)
        }
        
        graySignalIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-offsetX)
            make.top.equalToSuperview().offset(signalIconPositionY)
            make.width.equalTo(signalIconWidth)
            make.height.equalTo(signalIconHeight)
        }
        
        maxLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.top.equalTo(signalIcon.snp.bottom).offset(2)
            make.width.equalTo(50)
            make.height.equalTo(UIFont.systemFont(ofSize: 11).lineHeight)
        }
        
        minLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-offsetX)
            make.top.equalTo(signalIcon.snp.bottom).offset(2)
            make.width.equalTo(50)
            make.height.equalTo(UIFont.systemFont(ofSize: 11).lineHeight)
        }
        
        let noteSize = noteMsg1.size(withFont: .systemFont(ofSize: 11), maxSize: CGSize(width: backViewWidth - 2 * offsetX, height: .greatestFiniteMagnitude))
        noteLabel1.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.top.equalTo(signalIcon.snp.bottom).offset(offsetX + 20)
            make.width.equalTo(backViewWidth - 2 * offsetX)
            make.height.equalTo(noteSize.height)
        }
        
        doneButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(offsetX)
            make.bottom.equalToSuperview().offset(-40)
            make.width.equalTo(backViewWidth - 2 * offsetX)
            make.height.equalTo(45)
        }
    }
    
    private func addTapAction() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        addGestureRecognizer(tap)
    }
    
    @objc private func rssiValueChanged() {
        rssiValueLabel.text = String(format: "%.fdBm", -100 - slider.value)
    }
    
    @objc private func dismiss() {
        nameTextField.resignFirstResponder()
        tagTextField.resignFirstResponder()
        
        UIView.animate(withDuration: 0.25) {
            self.backView.transform = CGAffineTransform(translationX: 0, y: -self.backViewHeight)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func doneButtonPressed() {
        nameTextField.resignFirstResponder()
        tagTextField.resignFirstResponder()
        
        UIView.animate(withDuration: 0.25) {
            self.backView.transform = CGAffineTransform(translationX: 0, y: -self.backViewHeight)
        } completion: { _ in
            let rssiValue = -100 - Int(self.slider.value)
            self.searchBlock?(self.nameTextField.text ?? "", self.tagTextField.text ?? "", rssiValue)
            self.removeFromSuperview()
        }
    }
    
    private func showSearchName(_ name: String, tagID: String, rssi: Int, searchBlock: @escaping (String, String, Int) -> Void) {
        App.window!.addSubview(self)
        
        self.searchBlock = searchBlock
        nameTextField.text = name
        tagTextField.text = tagID
        slider.value = Float(-100 - rssi)
        rssiValueLabel.text = "\(rssi)dBm"
        
        UIView.animate(withDuration: 0.25) {
            self.backView.transform = CGAffineTransform(translationX: 0, y: self.backViewHeight + 88) // Assuming kTopBarHeight is 88
        } completion: { _ in
            self.nameTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - UI Components
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(14.0),text: "BLE Name")
    }()
    
    private lazy var nameTextField: MKSwiftTextField = {
        let textField = MKSwiftTextField.init(textFieldType: .normal)
        textField.maxLength = 20
        textField.textColor = Color.defaultText
        textField.borderStyle = .none
        textField.font = Font.MKFont(13.0)
        textField.placeholder = "1-20 characters"
        textField.clearButtonMode = .whileEditing
        textField.layer.masksToBounds = true
        textField.layer.borderColor = Color.navBar.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 4
        return textField
    }()
    
    private lazy var tagLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(14.0),text: "Tag ID")
    }()
    
    private lazy var tagTextField: MKSwiftTextField = {
        let textField = MKSwiftTextField.init(textFieldType: .hexCharOnly)
        textField.maxLength = 12
        textField.textColor = Color.defaultText
        textField.borderStyle = .none
        textField.font = Font.MKFont(13.0)
        textField.placeholder = "1-6 Bytes"
        textField.clearButtonMode = .whileEditing
        textField.layer.masksToBounds = true
        textField.layer.borderColor = Color.navBar.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 4
        return textField
    }()
    
    private lazy var minRssiLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(14.0),text: "Min. RSSI")
    }()
    
    private lazy var rssiValueLabel: UILabel = {
        let label = MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(14.0),text: "-100dBm")
        
        let lineView = UIView()
        lineView.backgroundColor = Color.defaultText
        label.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        return label
    }()
    
    private lazy var signalIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_wifiSignalIcon", in: .module)
        return imageView
    }()
    
    private lazy var graySignalIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_wifiGraySignalIcon", in: .module)
        return imageView
    }()
    
    private lazy var slider: MKSwiftSlider = {
        let slider = MKSwiftSlider()
        slider.maximumValue = 0
        slider.minimumValue = -100
        slider.value = -100
        slider.addTarget(self, action: #selector(rssiValueChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var minLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.textAlignment = .left
        label.font = Font.MKFont(11.0)
        label.text = "-100dBm"
        return label
    }()
    
    private lazy var maxLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.rgb(15, 131, 255)
        label.textAlignment = .left
        label.font = Font.MKFont(11.0)
        label.text = "0dBm"
        return label
    }()
    
    private lazy var noteLabel1: UILabel = {
        let label = UILabel()
        label.textColor = .orange
        label.font = Font.MKFont(11.0)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.text = noteMsg1
        return label
    }()
    
    private lazy var doneButton: UIButton = {
        let button = MKSwiftUIAdaptor.createRoundedButton(title: "Apply",
                                                          target: self,
                                                          action: #selector(doneButtonPressed))
    
        return button
    }()
}

extension MKSFBXSScanFilterView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
}
