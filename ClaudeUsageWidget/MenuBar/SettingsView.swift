import SwiftUI
import PhosphorSwift

struct SettingsView: View {
    @ObservedObject var store: UsageDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var cookieInput: String = ""
    @State private var showCookieHelp = false
    @State private var showLoginSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    loginSection
                    Divider()
                    cookieSection
                    if showCookieHelp { helpSection }
                    Divider()
                    preferencesSection
                }
                .padding(20)
            }
            Divider()
            actionBar
        }
        .frame(width: 480, height: 460)
        .onAppear { cookieInput = store.sessionCookie }
        .sheet(isPresented: $showLoginSheet) {
            ClaudeLoginSheet { cookie in
                cookieInput = cookie
                store.saveCookie(cookie)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("settings.title").font(.title3.bold())
            Spacer()
            Button("action.close") { dismiss() }.buttonStyle(.plain).foregroundColor(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title: { Text("settings.auto_login.title").font(.headline) },
                  icon: { Ph.userCircle.fill.resizable().scaledToFit().frame(width: 16, height: 16) })
            Text("settings.auto_login.desc").font(.caption).foregroundColor(.secondary)
            Button { showLoginSheet = true } label: {
                Label(title: { Text("action.sign_in") },
                      icon: { Ph.signIn.regular.resizable().scaledToFit().frame(width: 16, height: 16) })
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)

            if !store.sessionCookie.isEmpty {
                HStack(spacing: 4) {
                    Ph.checkCircle.fill.resizable().scaledToFit().frame(width: 13, height: 13).foregroundColor(Color.green)
                    Text("settings.active").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    private var cookieSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title: { Text("settings.manual.title").font(.subheadline.bold()).foregroundColor(.secondary) },
                      icon: { Ph.key.fill.resizable().scaledToFit().frame(width: 14, height: 14).foregroundColor(Color.secondary) })
                Spacer()
                Button(showCookieHelp
                       ? String(localized: "settings.how_to.hide")
                       : String(localized: "settings.how_to")) {
                    withAnimation { showCookieHelp.toggle() }
                }
                .font(.caption).buttonStyle(.plain).foregroundColor(.accentColor)
            }
            TextEditor(text: $cookieInput)
                .font(.system(.caption, design: .monospaced))
                .frame(height: 60)
                .border(Color.secondary.opacity(0.3), width: 1)
                .cornerRadius(4)
            Text("settings.manual.hint").font(.caption2).foregroundColor(.secondary)
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title: { Text("settings.preferences.title").font(.headline) },
                  icon: { Ph.slidersHorizontal.regular.resizable().scaledToFit().frame(width: 16, height: 16) })

            // Refresh interval
            VStack(alignment: .leading, spacing: 6) {
                Text("settings.refresh.title")
                    .font(.subheadline).foregroundColor(.secondary)
                Picker("", selection: $store.refreshIntervalMinutes) {
                    Text("settings.refresh.5min").tag(5)
                    Text("settings.refresh.10min").tag(10)
                    Text("settings.refresh.15min").tag(15)
                    Text("settings.refresh.off").tag(0)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                if store.refreshIntervalMinutes == 0 {
                    Text("settings.refresh.off.hint")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            // Widget visibility (gezinen widget şimdilik kapalı)
            if AppConfig.floatingWidgetEnabled {
                Toggle(isOn: $store.isWidgetVisible) {
                    Label(title: { Text("settings.widget.title").font(.subheadline) },
                          icon: { Ph.appWindow.regular.resizable().scaledToFit().frame(width: 14, height: 14) })
                }
                .toggleStyle(.switch)
            }
        }
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                helpStep(n: 1, key: "settings.help1")
                helpStep(n: 2, key: "settings.help2")
                helpStep(n: 3, key: "settings.help3")
                helpStep(n: 4, key: "settings.help4")
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(8)
        }
    }

    private func helpStep(n: Int, key: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(n).").font(.caption.bold()).foregroundColor(.accentColor)
                .frame(width: 16, alignment: .trailing)
            Text(key).font(.caption)
        }
    }

    private var actionBar: some View {
        HStack {
            if !store.sessionCookie.isEmpty {
                Button(role: .destructive) {
                    store.clearCookie(); cookieInput = ""
                } label: {
                    Label(title: { Text("action.sign_out") },
                          icon: { Ph.trash.regular.resizable().scaledToFit().frame(width: 14, height: 14) })
                }
                .buttonStyle(.plain).foregroundColor(.red)
            }
            Spacer()
            Button("action.cancel") { dismiss() }.keyboardShortcut(.cancelAction)
            Button("action.save") {
                store.saveCookie(cookieInput); dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(cookieInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }
}
