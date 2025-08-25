import UIKit
import SnapKit
import MKBaseSwiftModule

@MainActor class MKSFBXSTHCurveViewModel {
    var lineColor: UIColor = .blue
    var lineWidth: CGFloat = 1.0
    var curveViewBackgroundColor: UIColor = Color.rgb(224, 245, 254)
    var curveTitle: String = ""
    var titleColor: UIColor = Color.defaultText
    var titleFont: UIFont = Font.MKFont(12.0)
    var yPostionColor: UIColor = Color.defaultText
    var yPostionWidth: CGFloat = Line.height
    var labelColor: UIColor = Color.defaultText
    var labelFont: UIFont = Font.MKFont(10.0)
}

// MARK: - MKSFBXSCurveView
private class MKSFBXSCurveView: UIView {
    var pointList: [CGFloat] = []
    var lineColor: UIColor = .blue
    var lineWidth: CGFloat = 1.0
    
    func updatePointValues(_ pointList: [String], maxValue: CGFloat, minValue: CGFloat) {
        guard !pointList.isEmpty else { return }
            
        self.pointList.removeAll()
        let totalValue = maxValue - minValue
        
        // 处理 totalValue 为 0 的情况
        guard totalValue != 0 else {
            let defaultValue = bounds.height - 13.0
            self.pointList = Array(repeating: defaultValue, count: pointList.count)
            setNeedsDisplay()
            return
        }
        
        for i in 0..<pointList.count {
            // 安全转换字符串为数值，转换失败使用 minValue
            let value = CGFloat(Double(pointList[i])!)
            let tempValue = (bounds.height - 13.0) * (maxValue - value) / totalValue
            self.pointList.append(tempValue)
        }
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawCurve()
    }
    
    private func drawCurve() {
        guard !pointList.isEmpty else { return }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineWidth(lineWidth > 0 ? lineWidth : 1.0)
        context.setStrokeColor(lineColor.cgColor)
        
        context.move(to: CGPoint(x: 0, y: pointList[0]))
        
        let width = bounds.width / CGFloat(pointList.count)
        for i in 1..<pointList.count {
            context.addLine(to: CGPoint(x: CGFloat(i) * width, y: pointList[i]))
        }
        
        context.strokePath()
    }
}

class MKSFBXSTHCurveView: UIView {
    
    // MARK: - Constants
    private let valueLabelWidth: CGFloat = 35
    private let maxPointCount = 1000
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(horizontalLine)
        addSubview(maxLabel)
        addSubview(maxLine)
        addSubview(valueMaxLabel)
        addSubview(valueMaxLine)
        addSubview(valueMinLabel)
        addSubview(valueMinLine)
        addSubview(minLabel)
        addSubview(minLine)
        addSubview(aveLabel)
        addSubview(aveLine)
        addSubview(scrollView)
        scrollView.addSubview(curveView)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(-40)
            make.width.equalTo(120)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        
        maxLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.width.equalTo(valueLabelWidth)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
        
        valueMaxLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(maxLabel)
            make.top.equalTo(maxLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel)
        }
        
        aveLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(maxLabel)
            make.top.equalTo(valueMaxLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel)
        }
        
        valueMinLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(maxLabel)
            make.top.equalTo(aveLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel)
        }
        
        minLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(maxLabel)
            make.bottom.equalToSuperview().offset(-5)
            make.height.equalTo(maxLabel)
        }
        
        horizontalLine.snp.remakeConstraints { make in
            make.leading.equalTo(maxLabel.snp.trailing).offset(3)
            make.width.equalTo(0.5) // CUTTING_LINE_HEIGHT
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
        }
        
        maxLine.snp.remakeConstraints { make in
            make.leading.equalTo(horizontalLine.snp.trailing)
            make.width.equalTo(3)
            make.centerY.equalTo(maxLabel)
            make.height.equalTo(0.5)
        }
        
        minLine.snp.remakeConstraints { make in
            make.leading.equalTo(horizontalLine.snp.trailing)
            make.width.equalTo(3)
            make.centerY.equalTo(minLabel)
            make.height.equalTo(0.5)
        }
        
        aveLine.snp.remakeConstraints { make in
            make.leading.equalTo(horizontalLine.snp.trailing)
            make.width.equalTo(3)
            make.centerY.equalTo(aveLabel)
            make.height.equalTo(0.5)
        }
        
        valueMaxLine.snp.remakeConstraints { make in
            make.leading.equalTo(horizontalLine.snp.trailing)
            make.width.equalTo(3)
            make.centerY.equalTo(valueMaxLabel)
            make.height.equalTo(0.5)
        }
        
        valueMinLine.snp.remakeConstraints { make in
            make.leading.equalTo(horizontalLine.snp.trailing)
            make.width.equalTo(3)
            make.centerY.equalTo(valueMinLabel)
            make.height.equalTo(0.5)
        }
        
        scrollView.snp.remakeConstraints { make in
            make.leading.equalTo(horizontalLine.snp.trailing)
            make.trailing.equalToSuperview().offset(-5)
            make.top.equalTo(valueMaxLabel.snp.centerY)
            make.bottom.equalTo(valueMinLabel.snp.centerY)
        }
        
        curveView.frame = CGRect(x: 0, y: 0, width: curveViewWidth, height: curveViewHeight)
    }
    
    // MARK: - Helper Properties
    private var labelSpace: CGFloat {
        return (bounds.height - 10 - 5 * Font.MKFont(10.0).lineHeight) / 4
    }
    
    private var curveViewWidth: CGFloat {
        return bounds.width - 60
    }
    
    private var curveViewHeight: CGFloat {
        return bounds.height - 10 - 2 * Font.MKFont(10.0).lineHeight - 2 * labelSpace
    }
    
    // MARK: - Public Methods
    func drawCurve(with paramModel: MKSFBXSTHCurveViewModel,
                  pointList: [String],
                  maxValue: CGFloat,
                  minValue: CGFloat) {
        guard !pointList.isEmpty else { return }
        
        configParams(with: paramModel)
        
        horizontalLine.snp.remakeConstraints { make in
            make.left.equalTo(maxLabel.snp.right).offset(3)
            make.width.equalTo(paramModel.yPostionWidth > 0 ? paramModel.yPostionWidth : 0.5)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }
        
        let tempValue = (maxValue - minValue) / 2
        valueMaxLabel.text = String(format: "%.1f", maxValue)
        valueMinLabel.text = String(format: "%.1f", minValue)
        maxLabel.text = String(format: "%.1f", maxValue + tempValue)
        minLabel.text = String(format: "%.1f", minValue - tempValue)
        aveLabel.text = String(format: "%.1f", minValue + tempValue)
        
        var tempViewWidth = curveViewWidth
        if pointList.count > maxPointCount {
            let space = curveViewWidth / CGFloat(maxPointCount)
            tempViewWidth = CGFloat(pointList.count / maxPointCount) * curveViewWidth + CGFloat(pointList.count % maxPointCount) * space
        }
        
        curveView.frame = CGRect(x: 0, y: 0, width: tempViewWidth, height: curveViewHeight)
        curveView.updatePointValues(pointList, maxValue: maxValue, minValue: minValue)
        
        scrollView.contentSize = pointList.count <= maxPointCount ? .zero : CGSize(width: tempViewWidth, height: 0)
    }
    
    func drawCurve(with pointList: [String], maxValue: CGFloat, minValue: CGFloat) {
        let dataModel = MKSFBXSTHCurveViewModel()
        drawCurve(with: dataModel, pointList: pointList, maxValue: maxValue, minValue: minValue)
    }
    
    // MARK: - Private Methods
    private func configParams(with paramModel: MKSFBXSTHCurveViewModel) {
        backgroundColor = paramModel.curveViewBackgroundColor
        curveView.lineColor = paramModel.lineColor
        curveView.lineWidth = paramModel.lineWidth > 0 ? paramModel.lineWidth : 1.0
        curveView.backgroundColor = paramModel.curveViewBackgroundColor
        titleLabel.textColor = paramModel.titleColor
        titleLabel.font = paramModel.titleFont
        titleLabel.text = paramModel.curveTitle
        horizontalLine.backgroundColor = paramModel.yPostionColor
        
        [maxLabel, valueMaxLabel, aveLabel, valueMinLabel, minLabel].forEach {
            $0.textColor = paramModel.labelColor
            $0.font = paramModel.labelFont
        }
    }
    
    // MARK: - UI Components (Lazy loading)
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.font = Font.MKFont(12.0)
        label.textAlignment = .center
        label.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        return label
    }()
    
    private lazy var horizontalLine: UIView = {
        let view = UIView()
        view.backgroundColor = Color.defaultText
        return view
    }()
    
    private lazy var maxLabel = createLabel()
    private lazy var valueMaxLabel = createLabel()
    private lazy var aveLabel = createLabel()
    private lazy var valueMinLabel = createLabel()
    private lazy var minLabel = createLabel()
    
    private lazy var maxLine = createLine()
    private lazy var valueMaxLine = createLine()
    private lazy var aveLine = createLine()
    private lazy var valueMinLine = createLine()
    private lazy var minLine = createLine()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var curveView: MKSFBXSCurveView = {
        let view = MKSFBXSCurveView()
        return view
    }()
    
    private func createLabel() -> UILabel {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }
    
    private func createLine() -> UIView {
        let view = UIView()
        view.backgroundColor = Color.rgb(136, 136, 136)
        return view
    }
}

// MARK: - UIScrollViewDelegate
extension MKSFBXSTHCurveView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("当前滚动范围: \(scrollView.contentOffset.x)")
        if scrollView.contentOffset.x <= 0 {
            var offset = scrollView.contentOffset
            offset.x = 0
            scrollView.contentOffset = offset
        }
    }
}
