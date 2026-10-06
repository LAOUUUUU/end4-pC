import Appearance
import SwiftUI
import WidgetsCore

/// Clock, world clocks, CPU and memory, countdown, notes and to-do: the shell's widgets, in one column.
struct WidgetsView: View {
    @ObservedObject var hub: WidgetHub
    @ObservedObject var theme: ThemeModel
    @AppStorage("io.github.endlyrics.notes") private var notes = ""
    @State private var newTask = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            clock
            stats
            countdown
            notesCard
            todo
        }
    }

    private var clock: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 6) {
                Text(ClockFormat.time(context.date, in: .current, use24Hour: true))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text(context.date.formatted(date: .complete, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                ForEach(Array(hub.worldClocks.dropFirst().enumerated()), id: \.offset) { _, entry in
                    HStack {
                        Text(entry.label).font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text(ClockFormat.time(context.date, in: entry.zone, use24Hour: true))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                }
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 14) {
            meter("CPU", hub.stats.cpuPercent)
            meter("Memory", hub.stats.memoryPercent)
        }
        .onAppear { hub.stats.start() }
    }

    private func meter(_ label: String, _ percent: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 11, weight: .semibold))
                Spacer()
                Text("\(Int(percent.rounded()))%").font(.system(size: 11, design: .monospaced))
            }
            Capsule()
                .fill(.white.opacity(0.15))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    GeometryReader { geometry in
                        Capsule().fill(theme.accent)
                            .frame(width: geometry.size.width * CGFloat(percent / 100))
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }

    private var countdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TIMER").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            if hub.countdown.running {
                HStack {
                    Text(Self.clockText(hub.countdown.remaining))
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                    Spacer()
                    Button("Cancel") { hub.countdown.cancel() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                }
            } else {
                HStack(spacing: 6) {
                    ForEach([5, 15, 30, 60], id: \.self) { minutes in
                        Button("\(minutes) min") { hub.countdown.start(minutes: minutes) }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.white.opacity(0.12)))
                    }
                }
            }
            Toggle("Pause music when it ends", isOn: Binding(
                get: { hub.countdown.pausesMusic },
                set: { hub.countdown.pausesMusic = $0 }
            ))
                .font(.system(size: 11))
                .toggleStyle(.switch)
                .tint(theme.accent)
        }
        .card()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            TextEditor(text: $notes)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .frame(height: 80)
        }
        .card()
    }

    private var todo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TO-DO").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(hub.todo.list.completedCount)/\(hub.todo.list.items.count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            TextField("Add a task", text: $newTask)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .onSubmit {
                    hub.todo.list.add(newTask)
                    newTask = ""
                }
            ForEach(hub.todo.list.items) { item in
                HStack(spacing: 8) {
                    Button {
                        hub.todo.list.toggle(item.id)
                    } label: {
                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.done ? theme.accent : .white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    Text(item.text)
                        .font(.system(size: 12))
                        .strikethrough(item.done)
                        .foregroundStyle(.white.opacity(item.done ? 0.5 : 0.95))
                    Spacer()
                    Button {
                        hub.todo.list.remove(item.id)
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card()
    }

    /// m:ss for the countdown.
    static func clockText(_ seconds: Double) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private extension View {
    /// A translucent rounded card, the glass style used across the full-screen menu.
    func card() -> some View {
        self
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1)))
    }
}
