//
//  BarChartViewController.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

#if canImport(UIKit)
    import UIKit
#endif
import DGCharts
#if canImport(UIKit)
    import UIKit
#endif

class BarChartViewController: DemoBaseViewController {
    
    @IBOutlet var chartView: BarChartView!
    @IBOutlet var sliderX: UISlider!
    @IBOutlet var sliderY: UISlider!
    @IBOutlet var sliderTextX: UITextField!
    @IBOutlet var sliderTextY: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Bar Chart"
        
        self.options = [.toggleValues,
                        .toggleHighlight,
                        .animateX,
                        .animateY,
                        .animateXY,
                        .saveToGallery,
                        .togglePinchZoom,
                        .toggleData,
                        .toggleBarBorders]
        
        self.setup(barLineChartView: chartView)
        
        chartView.delegate = self
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = false
        
        chartView.maxVisibleCount = 60
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 7
        xAxis.valueFormatter = DayAxisValueFormatter(chart: chartView)
        
        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.minimumFractionDigits = 0
        leftAxisFormatter.maximumFractionDigits = 1
        leftAxisFormatter.negativeSuffix = " $"
        leftAxisFormatter.positiveSuffix = " $"
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 8
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
        leftAxis.labelPosition = .outsideChart
        leftAxis.spaceTop = 0.15
        leftAxis.axisMinimum = 0 // FIXME: HUH?? this replaces startAtZero = YES
        
        let rightAxis = chartView.rightAxis
        rightAxis.enabled = true
        rightAxis.labelFont = .systemFont(ofSize: 10)
        rightAxis.labelCount = 8
        rightAxis.valueFormatter = leftAxis.valueFormatter
        rightAxis.spaceTop = 0.15
        rightAxis.axisMinimum = 0
        
        let l = chartView.legend
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.form = .circle
        l.formSize = 9
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.xEntrySpace = 4
//        chartView.legend = l

        let marker = XYMarkerView(color: UIColor(white: 180/250, alpha: 1),
                                  font: .systemFont(ofSize: 12),
                                  textColor: .white,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: chartView.xAxis.valueFormatter!)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        
        sliderX.value = 12
        sliderY.value = 50
        slidersValueChanged(nil)
        addGesture()
    }
    
    func addGesture() {
        
        let gestureList = chartView.gestureRecognizers
        /// 对charts自带的拖拽手势，再加一个拖拽曲线的响应事件
        if let pan = gestureList?.first(where: { $0.isKind(of: UIPanGestureRecognizer.self) }) as? UIPanGestureRecognizer  {
            pan.addTarget(self, action: #selector(self.handlePan))
        }
    }
    
    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        
        // 保证缩放在>1使用组件其自身的拖拽手势，在小于等于1时使用辅助手势相应
        let scaleX = chartView.scaleX
        guard scaleX <= 1 else { return }
        
        
        switch pan.state {
        case .began:
//            chartView.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer })?.isEnabled = false
            ()
        case .changed:
            
            let translation = pan.translation(in: self.view)
            pan.setTranslation(.zero, in: self.view)
            
            let pt = translation.x / self.view.bounds.width * CGFloat(Int(sliderX.value) + 1)
            
            let min = chartView.xAxis.axisMinimum - pt
            let max = chartView.xAxis.axisMaximum - pt
            
            
            guard let set = chartView.data?.first as? BarChartDataSet else { return }
            
//            guard min >= 0 else { return }
//            guard max <= CGFloat(entrieCount + maxXVisibleCount) else { return }
            
            chartView.xAxis.axisMinimum = min
            chartView.xAxis.axisMaximum = max
            chartView.notifyDataSetChanged()
            
            let entrieCount = set.entries.count
            if pt < 0 { // 左滑，拉之后
                let crt = (min + max) / 2
                let maxXVisibleCount = Int(sliderX.value / 4)
                let load = entrieCount-maxXVisibleCount
                print("crt: \(crt), load: \(load)")
                if (load-5..<load-4).contains(Int(crt)) {
//                if (load-2..<load-1).contains(Int(crt)) {
                    appendChartData()
                }
            } else if pt > 0 {  // 右滑，拉之前
                let crt = (min + max) / 2
                let maxXVisibleCount = Int(sliderX.value / 4)
                let load = maxXVisibleCount
                print("crt: \(crt), load: \(load)")
                
                if ((load+3)..<(load+4)).contains(Int(crt)) {
//                if ((load+1)..<(load+2)).contains(Int(crt)) {
                    insertChartData()
                }
            }
            
        default:
            ()
        }
    }
    
    func appendChartData() {
        if self.shouldHideData {
            chartView.data = nil
            return
        }
        
        guard let set = chartView.data?.first as? BarChartDataSet else { return }
        
        let start = set.entries.count
        let count = Int(sliderX.value) + 1
        let range = UInt32(sliderY.value)
        (start..<start+count+1).forEach({ i in
            let mult = range + 1
            let val = Double(arc4random_uniform(mult)) + 10
            let entry: BarChartDataEntry
            entry = BarChartDataEntry(x: Double(i), y: val)
            set.append(entry)
        })
        
        print("appendChartData")
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }
    
    func insertChartData() {
        if self.shouldHideData {
            chartView.data = nil
            return
        }
        
        guard var set = chartView.data?.first as? BarChartDataSet else { return }
        
        let start = 1
        let count = Int(sliderX.value) + 1
        let range = UInt32(sliderY.value)
        let yVals = (start..<start+count+1).map({ (i) -> ColorBarChartDataEntry in
            let mult = range + 1
            let val = Double(arc4random_uniform(mult)) + 10
            let entry = BarChartDataEntry(x: Double(i), y: val)
            let material = ChartColorTemplates.material()
            let color = material[i % material.count]
            return ColorBarChartDataEntry(color: color, entry: entry)
        })
        set.insert(contentsOf: yVals.map({ $0.entry }), at: 0)
        
        set.entries.enumerated().forEach { (index, entry) in
            entry.x = Double(index)
        }
        
        let newColors = yVals.map({ $0.color }) + set.colors
        set.setColors(newColors, alpha: 1)
        
        let offset = chartView.xAxis.axisMinimum + Double(count)
        let size = chartView.xAxis.axisMaximum - chartView.xAxis.axisMinimum
        chartView.xAxis.axisMinimum = offset
        chartView.xAxis.axisMaximum = offset + size
        
        print("insertChartData")
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }
    
    override func updateChartData() {
        if self.shouldHideData {
            chartView.data = nil
            return
        }
        
        self.setDataCount(Int(sliderX.value) + 1, range: UInt32(sliderY.value))
    }
    
    func setDataCount(_ count: Int, range: UInt32) {
        let start = 1
        
        let yVals = (start..<start+count+1).map { (i) -> ColorBarChartDataEntry in
            let mult = range + 1
            let val = Double(arc4random_uniform(mult)) + 10
            let entry: BarChartDataEntry
            if i == 3 {
                entry = BarChartDataEntry(x: Double(i), y: val, icon: UIImage(named: "icon"))
            } else {
                entry = BarChartDataEntry(x: Double(i), y: val)
            }
            let material = ChartColorTemplates.material()
            let color = material[i % material.count]
            return ColorBarChartDataEntry(color: color, entry: entry)
        }
        
        var set1: BarChartDataSet! = nil
        if let set = chartView.data?.first as? BarChartDataSet {
            set1 = set
            set1.replaceEntries(yVals.map({ $0.entry }))
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
        } else {
            set1 = BarChartDataSet(entries: yVals.map({ $0.entry }), label: "The year 2017")
//            set1.colors = ChartColorTemplates.material()
            set1.colors = yVals.map({ $0.color })
            set1.drawValuesEnabled = false
            
            let data = BarChartData(dataSet: set1)
            data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
            data.barWidth = 0.9
            chartView.data = data
        }
        
//        chartView.setNeedsDisplay()
    }
    
    override func optionTapped(_ option: Option) {
        super.handleOption(option, forChartView: chartView)
    }
    
    // MARK: - Actions
    @IBAction func slidersValueChanged(_ sender: Any?) {
        sliderTextX.text = "\(Int(sliderX.value + 2))"
        sliderTextY.text = "\(Int(sliderY.value))"
        
        self.updateChartData()
    }
    
    override func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
//        print("dX:\(dX), dY:\(dY)")
        let dataMax = chartView.xAxis.axisMaximum
        
        if (dataMax-5..<dataMax-4).contains(dX) {
//            page += 1
//            print("page: \(page)")
            
//            updateChartData()
        }
    }
    
    override func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let chart = chartView as? BarChartView else { return }
        let visibleCount = chart.visibleXRange
        let totalDataCount = Double(chart.data?.entryCount ?? 0)
        
        if highlight.x == totalDataCount - visibleCount {
            // 向右滑动（加载更老数据）
            loadMoreData(isNewData: false)
        } else if highlight.x == visibleCount - 1 {
            // 向左滑动（加载新数据）
            loadMoreData(isNewData: true)
        }
    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        
        let min = chartView.xAxis.axisMinimum
        let max = chartView.xAxis.axisMaximum
        
        print("DidEndPanning min:\(min), max:\(max)")
        
    }
    
    func loadMoreData(isNewData: Bool) {
        
        
//        let start = 1
//        let count = Int(sliderX.value) + 1
//        let range = UInt32(sliderY.value)
//
//        let yVals = (start..<start+count+1).map { (i) -> BarChartDataEntry in
//            let mult = range + 1
//            let val = Double(arc4random_uniform(mult))
//            if arc4random_uniform(100) < 25 {
//                return BarChartDataEntry(x: Double(i), y: val, icon: UIImage(named: "icon"))
//            } else {
//                return BarChartDataEntry(x: Double(i), y: val)
//            }
//        }
//
//        // 示例：
//        let moreData = yVals // 加载附加数据
//        if isNewData {
//            set1.append(contentsOf: moreData)
//        } else {
//            set1.insert(contentsOf: moreData, at: 0)
//        }
//
//        // 更新图表数据
//        chartView.data?.notifyDataChanged()
//        chartView.notifyDataSetChanged()
    }
    
}


class ColorBarChartDataEntry {
    let color: NSUIColor
    let entry: BarChartDataEntry
    init(color: UIColor, entry: BarChartDataEntry) {
        self.color = color
        self.entry = entry
    }
}
