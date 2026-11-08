import UIKit
import WebKit

/// Loads the published game at launch, with bundled offline fallback.
/// GitHub Pages only serves game content; native binaries still require a new IPA.
final class GameViewController: UIViewController, WKNavigationDelegate {
    private var gameView: WKWebView!
    private let trustedHost = "denisbarabash9-del.github.io"
    private let onlineURL = URL(string: "https://denisbarabash9-del.github.io/Retro-Ranked-2025/")!
    private var offlineURL: URL? {
        Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Game")
    }
    private var isOffline = false

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.isOpaque = false
        view.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.16, alpha: 1)
        view.scrollView.isScrollEnabled = false
        view.scrollView.bounces = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.delaysContentTouches = false
        gameView = view
        self.view = view
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Requires enabling GitHub Pages: Settings > Pages > Deploy from branch main /root.
        var probe = URLRequest(url: onlineURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        probe.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: probe) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error == nil, let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    var request = URLRequest(url: self.onlineURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
                    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                    self.gameView.load(request)
                } else {
                    self.loadOffline()
                }
            }
        }.resume()
    }
    private func loadOffline() {
        guard !isOffline, let url = offlineURL else { return }
        isOffline = true
        gameView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadOffline()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadOffline()
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel); return
        }
        if scheme == "file" || scheme == "about" { decisionHandler(.allow); return }
        if scheme == "https" && url.host?.lowercased() == trustedHost &&
            url.path.hasPrefix("/Retro-Ranked-2025/") { decisionHandler(.allow); return }
        decisionHandler(.cancel)
    }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }
}
