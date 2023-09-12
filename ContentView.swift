//

import SwiftUI

struct ShakeData {
    var offset: CGFloat = 0
    var rotation: Angle = .zero
}

struct MyKeyframeAnimator<Root, Trigger: Equatable, Content: View>: View {
    var initialValue: Root
    var trigger: Trigger
    @ViewBuilder var content: (Root) -> Content
    var keyframes: [any MyKeyframeTracks<Root>]

    @State private var startDate: Date? = nil
    @State private var suspended = true

    var timeline: MyKeyframeTimeline<Root> {
        MyKeyframeTimeline(initialValue: initialValue, tracks: keyframes)
    }

    func value(for date: Date) -> Root {
        guard let s = startDate else { return initialValue }
        return timeline.value(time: date.timeIntervalSince(s))
    }

    func isPaused(_ date: Date) -> Bool {
        guard let s = startDate else { return true }
        let time = date.timeIntervalSince(s)
        if time > timeline.duration { return true }
        return false
    }

    var body: some View {
        TimelineView(.animation(paused: suspended)) { context in
            let _ = print(Date.now.timeIntervalSince1970)
            let value = value(for: context.date)
            content(value)
                .onChange(of: isPaused(context.date)) { _, newValue in
                    suspended = newValue
                }
        }
        .onChange(of: trigger) { _, _ in
            startDate = Date()
            suspended = false
        }
    }
}

let points: [(Double, duration: TimeInterval, startVelocity: Double?, endVelocity: Double?)] = [
    (-50, duration: 2, startVelocity: nil, endVelocity: -50),
    (30, duration: 5, startVelocity: nil, endVelocity: nil),
    (-100, duration: 2, startVelocity: -100, endVelocity: nil),
    (0, duration: 0.5, startVelocity: 5, endVelocity: nil),
    (-100, duration: 1, startVelocity: 10, endVelocity: nil),
    (-120, duration: 3, startVelocity: nil, endVelocity: nil),
]

import Charts

struct ContentView: View {
    @State private var shakes = 0

    var body: some View {
        let t0 = KeyframeTimeline(initialValue: 0) {
            for point in points {
                CubicKeyframe(point.0, duration: point.duration, startVelocity: point.startVelocity, endVelocity: point.endVelocity)
            }
        }
        let t1 = MyKeyframeTimeline(initialValue: 0, tracks:
            [
                MyKeyframeTrack(\.self, points.map { p in
                                 MyCubicKeyframe(p.0, duration: p.duration, startVelocity: p.startVelocity, endVelocity: p.endVelocity)
                             })
            ]
        )
        Chart {
            let times = stride(from: 0, through: t0.duration, by: 0.01)
            ForEach(Array(times), id: \.self) { time in
                LineMark(x: .value("x", time), y: .value("y", t0.value(time: time)), series: .value("1", "1"))
                LineMark(x: .value("x", time), y: .value("y", t1.value(time: time)), series: .value("2", "2"))
                    .foregroundStyle(.green)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }
}

#Preview {
    ContentView()
}
