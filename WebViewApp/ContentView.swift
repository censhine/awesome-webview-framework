import SwiftUI
import WebKit

struct ContentView: View {
    @AppStorage("webURL") private var webURL: String = "http://47.115.132.109:8081/"
    @State private var showSettings = false
    @State private var refreshID = UUID()
    @State private var loadError: String? = nil
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            WebView(
                urlString: webURL,
                refreshID: refreshID,
                isLoading: $isLoading,
                loadError: $loadError
            )
            // 不再忽略安全区域：让网页内容避开状态栏/灵动岛，确保顶部按钮可点击
            
            // Loading indicator
            if isLoading && loadError == nil {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("加载中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(30)
                .background(.ultraThinMaterial)
                .cornerRadius(15)
            }
            
            // Error overlay with retry
            if let error = loadError {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("加载失败")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("重试") {
                        loadError = nil
                        isLoading = true
                        refreshID = UUID()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(30)
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding()
            }
            
        }
        .overlay(alignment: .topTrailing) {
            // Settings button — 使用 overlay 避免全屏容器拦截 WebView 触摸事件
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings, onURLChanged: { _ in
                loadError = nil
                isLoading = true
                refreshID = UUID()
            })
        }
    }
}

// MARK: - iOS WebView
#if os(iOS)
struct WebView: UIViewRepresentable {
    let urlString: String
    let refreshID: UUID
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // 确保 JavaScript 启用
        config.preferences.javaScriptEnabled = true
        // iOS 14+ 默认网页偏好设置
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        // 使用默认数据存储（避免某些情况下 cookie/storage 丢失导致白屏）
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        // 修复真机白屏：使用白色不透明背景，确保渲染正确
        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        // 确保 autoresizing 正确
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // 修复真机白屏：使用 .automatic 让系统正确处理安全区域，避免内容被遮挡
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        // 修复真机白屏：设置自定义 User-Agent，包含 Safari/Chrome 标识
        // 某些网站（如 Next.js）会根据 UA 返回不同内容，真机默认 UA 可能导致内容不渲染
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        // 修复真机白屏：在文档加载开始时注入脚本，确保在 hydration 前设置样式
        let whiteScreenFixScript = WKUserScript(source: """
            (function() {
                // 确保在 hydration 前就设置可见性
                var style = document.createElement('style');
                style.textContent = 'html, body { visibility: visible !important; opacity: 1 !important; display: block !important; }';
                (document.head || document.documentElement).appendChild(style);
            })();
        """, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(whiteScreenFixScript)
        
        context.coordinator.lastRefreshID = refreshID
        context.coordinator.onLoadingChange = { loading in
            DispatchQueue.main.async { self.isLoading = loading }
        }
        context.coordinator.onError = { error in
            DispatchQueue.main.async { self.loadError = error }
        }
        // 保存当前 URL 用于进程崩溃后重新加载
        context.coordinator.currentURLString = urlString
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            // 添加 User-Agent header（双重保险）
            request.setValue(webView.customUserAgent, forHTTPHeaderField: "User-Agent")
            webView.load(request)
        }
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onLoadingChange = { loading in
            DispatchQueue.main.async { self.isLoading = loading }
        }
        context.coordinator.onError = { error in
            DispatchQueue.main.async { self.loadError = error }
        }
        
        guard context.coordinator.lastRefreshID != refreshID else { return }
        context.coordinator.lastRefreshID = refreshID
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            webView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var lastRefreshID = UUID()
        var onLoadingChange: ((Bool) -> Void)?
        var onError: ((String?) -> Void)?
        var currentURLString: String?
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingChange?(true)
            onError?(nil)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingChange?(false)
            // 调试：打印加载完成的 URL
            if let url = webView.url {
                print("[WebView] 加载完成: \(url.absoluteString)")
            }
            // 修复真机白屏：注入 JavaScript 确保页面可见
            // 某些 Next.js 应用在 WKWebView 中可能因 hydration 问题导致内容隐藏
            webView.evaluateJavaScript("""
                (function() {
                    // 确保 body 可见
                    document.body.style.visibility = 'visible';
                    document.body.style.opacity = '1';
                    document.body.style.display = '';
                    // 确保 html 可见
                    document.documentElement.style.visibility = 'visible';
                    document.documentElement.style.opacity = '1';
                    // 移除可能的隐藏样式
                    var hidden = document.querySelectorAll('[hidden]');
                    hidden.forEach(function(el) { el.removeAttribute('hidden'); });
                })();
            """) { _, error in
                if let error = error {
                    print("[WebView] 注入脚本失败: \(error.localizedDescription)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadingChange?(false)
            print("[WebView] 加载失败: \(error.localizedDescription)")
            onError?(error.localizedDescription)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onLoadingChange?(false)
            print("[WebView] 预加载失败: \(error.localizedDescription)")
            // 过滤掉取消加载的错误（通常是因为快速切换页面导致）
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                return
            }
            onError?(error.localizedDescription)
        }
        
        // 处理 HTTP 重定向
        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            if let url = webView.url {
                print("[WebView] 重定向到: \(url.absoluteString)")
            }
        }
        
        // 修复真机白屏：处理导航策略，允许所有导航
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 允许所有导航（包括 JS 触发的导航）
            decisionHandler(.allow)
        }
        
        // 修复真机白屏：处理 WKWebView 进程崩溃
        // 真机上 WKWebView 的 Web Content Process 可能因内存压力而崩溃，导致白屏
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("[WebView] WebContent 进程崩溃，正在重新加载...")
            onLoadingChange?(true)
            if let urlString = currentURLString, let url = URL(string: urlString) {
                var request = URLRequest(url: url)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                webView.load(request)
            }
        }
    }
}

// MARK: - macOS WebView
#elseif os(macOS)
struct WebView: NSViewRepresentable {
    let urlString: String
    let refreshID: UUID
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        context.coordinator.lastRefreshID = refreshID
        context.coordinator.onLoadingChange = { loading in
            DispatchQueue.main.async { self.isLoading = loading }
        }
        context.coordinator.onError = { error in
            DispatchQueue.main.async { self.loadError = error }
        }
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onLoadingChange = { loading in
            DispatchQueue.main.async { self.isLoading = loading }
        }
        context.coordinator.onError = { error in
            DispatchQueue.main.async { self.loadError = error }
        }
        
        guard context.coordinator.lastRefreshID != refreshID else { return }
        context.coordinator.lastRefreshID = refreshID
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var lastRefreshID = UUID()
        var onLoadingChange: ((Bool) -> Void)?
        var onError: ((String?) -> Void)?
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingChange?(true)
            onError?(nil)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingChange?(false)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadingChange?(false)
            onError?(error.localizedDescription)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onLoadingChange?(false)
            onError?(error.localizedDescription)
        }
    }
}
#endif
