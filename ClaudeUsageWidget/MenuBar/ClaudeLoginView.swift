import SwiftUI
import WebKit
import PhosphorSwift

// Coordinator'ı SwiftUI dışında tutmak için wrapper
final class WebViewHolder: ObservableObject {
    var webView: WKWebView?
}

struct ClaudeLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onLogin: (String) -> Void

    @State private var isLoading = true
    @State private var statusMessage = ""
    @StateObject private var holder = WebViewHolder()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ClaudeWebView(holder: holder, onLoading: { isLoading = $0 })
            Divider()
            footer
        }
        .frame(width: 540, height: 660)
        .onAppear {
            // Zaten Safari'den login olduysa cookie hemen orada olabilir
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                tryGrabCookie()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView().frame(width: 14, height: 14)
            } else {
                Ph.globe.regular.resizable().scaledToFit().frame(width: 14, height: 14).foregroundColor(Color.secondary)
            }
            Text("Claude.ai")
                .font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Button("Kapat") { dismiss() }.buttonStyle(.plain).foregroundColor(.secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Giriş yaptıktan sonra butona bas.")
                    .font(.caption).foregroundColor(.secondary)
                if !statusMessage.isEmpty {
                    Text(statusMessage).font(.caption)
                        .foregroundColor(statusMessage.contains("✓") ? .green : .orange)
                }
            }
            Spacer()
            Button {
                tryGrabCookie()
            } label: {
                Label(title: { Text("action.get_cookie") },
                      icon: { Ph.key.fill.resizable().scaledToFit().frame(width: 14, height: 14) })
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func tryGrabCookie() {
        guard let webView = holder.webView else {
            statusMessage = String(localized: "login.webview_wait")
            // Biraz bekle ve tekrar dene
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { tryGrabCookie() }
            return
        }
        statusMessage = String(localized: "login.searching")
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            DispatchQueue.main.async {
                print("[Login] Cookie'ler:", cookies.map { "\($0.domain)|\($0.name)" }.joined(separator: ", "))

                let session = cookies.first { $0.domain.contains("claude.ai") && $0.name == "sessionKey" }

                if let c = session {
                    statusMessage = String(localized: "login.found")
                    onLogin("\(c.name)=\(c.value)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
                } else {
                    let claudeCookies = cookies.filter { $0.domain.contains("claude.ai") }
                    if claudeCookies.isEmpty {
                        statusMessage = String(localized: "login.not_found")
                    } else {
                        let joined = claudeCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                        statusMessage = String(localized: "login.found")
                        onLogin(joined)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
                    }
                }
            }
        }
    }
}

struct ClaudeWebView: NSViewRepresentable {
    @ObservedObject var holder: WebViewHolder
    let onLoading: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onLoading: onLoading) }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        DispatchQueue.main.async { holder.webView = webView }

        webView.load(URLRequest(url: URL(string: "https://claude.ai/login")!))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onLoading: (Bool) -> Void
        weak var webView: WKWebView?
        init(onLoading: @escaping (Bool) -> Void) { self.onLoading = onLoading }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            DispatchQueue.main.async { self.onLoading(true) }
        }
        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            DispatchQueue.main.async { self.onLoading(false) }
        }
        func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError _: Error) {
            DispatchQueue.main.async { self.onLoading(false) }
        }
    }
}
