//
//  MKSFBXSHistoryDataMaskView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/7.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSHistoryDataMaskView: UIView {
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        let screenBounds = UIScreen.main.bounds
        super.init(frame: screenBounds)
        backgroundColor = Color.rgb(0, 0, 0, 0.5)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // MARK: - Public Methods
    
    func show(with view: UIView) {
        if superview != nil {
            removeFromSuperview()
        }
        view.addSubview(self)
    }
    
    func dismiss() {
        if superview != nil {
            removeFromSuperview()
        }
    }
    
    func updateTotalNumber(_ totalNumber: String) {
        totalLabel.text = "Total records: \(totalNumber)"
    }
    
    func updateCurrentNumber(_ number: String) {
        numberLabel.text = "Reading data ... , update \(number) records"
        setNeedsLayout()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        addSubview(backView)
        backView.addSubview(totalLabel)
        backView.addSubview(numberLabel)
    }
    
    private func setupConstraints() {
        backView.snp.remakeConstraints({ make in
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.centerY.equalToSuperview()
            make.height.equalTo(80)
        })
        
        totalLabel.snp.remakeConstraints ({ make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(Font.MKFont(15.0).lineHeight)
        })
        // Calculate dynamic height for numberLabel
        let width = frame.size.width - 2 * 30 - 2 * 10
        let numberSize = numberLabel.text?.size(withFont: numberLabel.font, maxSize: CGSize(width: (width - 2 * 15), height: .greatestFiniteMagnitude))
        
        numberLabel.snp.remakeConstraints ({ make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalTo(totalLabel.snp.bottom).offset(10)
            make.height.equalTo(numberSize!.height)
        })
    }
    
    // MARK: - UI Components
    
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.rgb(44, 44, 44)
        view.layer.masksToBounds = true
        view.layer.borderColor = Line.color.cgColor
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = Font.MKFont(15.0)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = Font.MKFont(15.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Reading data ... , update 0 records"
        return label
    }()
}
