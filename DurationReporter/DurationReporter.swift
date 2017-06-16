//  MIT License
//
//  Copyright (c) 2017 ktustanowski
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.//
//  DispatchQueue+Once.swift
//  SwiftyOnce
//
//  Created by Kamil Tustanowski on 20.01.2017.
//  Copyright © 2017 ktustanowski. All rights reserved.
//

import Foundation

public struct DurationReporter {
    
    fileprivate static var reports: [String : [DurationReport]] = [:]
    
    /// Called right after report .begin()
    public static var onReportBegin: ((String, DurationReport) -> ())?
    /// Called right after report .end()
    public static var onReportEnd: ((String, DurationReport) -> ())?
    
    public static var timeUnit: DurationUnit = Millisecond()
    
    /// Begin time tracking. Supports multiple actions grouping. When added action that was already
    /// tracked 2, 3, 4... will be added to action name to indicate this fact. Another action can be
    /// added only after the previous one is finished. Tracking `Buffering`, `Loading` at the same
    /// time is fine but to track another `Buffering` the first one must complete first.
    ///
    /// - Parameters:
    ///   - event: action group name i.e Video_Identifier::Play
    ///   - action: concrete action name i.e. Buffering, ContentLoading etc.
    public static func begin(event: String, action: String, payload: Any? = nil) {
        var eventReports = reports[event] ?? []
        let actionReports = eventReports.filter({ $0.title.contains(action) })
        let actionAlreadyTracked = actionReports.filter({ $0.duration == nil }).count > 0
        
        guard !actionAlreadyTracked else {
            print("Can't add action - another \(action) is already tracked.")
            return }
        
        let actionCount = actionReports.count
        
        var actionUniqueName = action
        if actionCount > 0 {
            actionUniqueName += "\(actionCount + 1)"
        }
        
        let report = DurationReport(title: actionUniqueName)
        report.beginPayload = payload
        report.begin()
        onReportBegin?(event, report)
        eventReports.append(report)
        
        reports[event] = eventReports
    }
    
    /// Finish time tracking.
    ///
    /// - Parameters:
    ///   - event: action group name i.e Video_Identifier::Play
    ///   - action: concrete action name i.e. Buffering, ContentLoading etc.
    public static func end(event: String, action: String, payload: Any? = nil) {
        let eventReports = reports[event]
        let report = eventReports?.filter({ $0.title.contains(action) && !$0.isComplete }).last
        report?.endPayload = payload
        report?.end()
        
        guard let properReport = report else {
            print("Can't end action - \(action) didn't find.")
            return
        }
        
        onReportEnd?(event, properReport)
    }
    
    /// Report generating closure
    /// - Returns: report string
    public static var reportGenerator: ([String : [DurationReport]]) -> (String) = {reports in
        var output = ""
        
        reports.forEach { eventName, eventReports in
            let eventDurationInNs = eventReports.flatMap { $0.duration }.reduce(0, +)
            let eventDuration = eventDurationInNs / DurationReporter.timeUnit.divider
            output += ("\n🚀 \(eventName) - \(eventDuration)\(DurationReporter.timeUnit.symbol)\n")
            
            eventReports.enumerated().forEach { index, report in
                if let durationInNs = report.duration {
                    let duration = durationInNs / DurationReporter.timeUnit.divider
                    let percentage = String(format: "%.2f", (Double(durationInNs) / Double(eventDurationInNs)) * 100.0)
                    output += "\(index + 1). \(report.title) \(duration)\(DurationReporter.timeUnit.symbol) \(percentage)%\n"
                } else {
                    output += "\(index + 1). 🔴 \(report.title) - ?\n"
                }
                
            }
        }

        return output
    }
    
    /// Generate report from collected data
    ///
    /// - Returns: report string
    public static func generateReport() -> String {
        return reportGenerator(reports)
    }
    
    /// Provide collected data for further processing
    ///
    /// - Returns: collected data
    public static func reportData() -> [String : [DurationReport]] {
        return reports
    }
    
    /// Clear all gathered data
    public static func clear() {
        reports.removeAll()
    }
}
