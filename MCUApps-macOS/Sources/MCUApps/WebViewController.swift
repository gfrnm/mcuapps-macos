import Cocoa
import WebKit
import AuthenticationServices

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let appUrlString = "https://mcu-apps.co.id/login"
    private let customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"

    private var webView: WKWebView!
    private var splashView: NSView!
    private var progressIndicator: NSProgressIndicator!
    private var errorView: NSView!
    private var googleNavView: NSView!
    private var currentZoomFactor: Double = 1.0

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1280, height: 820))
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0).cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupGoogleNavBar()
        setupSplashView()
        setupErrorView()
        loadApp()
    }

    // MARK: - WKWebView Setup
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs

        // Injected script to handle escape key & basic protections
        let scriptSource = """
            window.addEventListener('keydown', function(e) {
                if (e.key === 'Escape' || e.keyCode === 27) {
                    window.webkit.messageHandlers.mcuHandler.postMessage('ESCAPE_PRESSED');
                }
            }, true);
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        
        let contentController = config.userContentController
        contentController.add(ScriptMessageHandler(parent: self), name: "mcuHandler")

        webView = WKWebView(frame: self.view.bounds, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = customUserAgent
        webView.allowsBackForwardNavigationGestures = true

        self.view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            webView.topAnchor.constraint(equalTo: self.view.topAnchor)
        ])
    }

    // MARK: - Google Navigation Bar
    private func setupGoogleNavBar() {
        googleNavView = NSView()
        googleNavView.translatesAutoresizingMaskIntoConstraints = false
        googleNavView.wantsLayer = true
        googleNavView.layer?.backgroundColor = NSColor.white.cgColor
        googleNavView.isHidden = true

        let backButton = NSButton(title: " ⬅ Kembali ke Halaman Login MCUApps", target: self, action: #selector(navigateToLogin))
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.bezelStyle = .rounded
        backButton.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        backButton.contentTintColor = NSColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0)

        let hintLabel = NSTextField(labelWithString: "💡 Tekan Esc atau klik tombol di samping untuk kembali ke Login")
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = NSFont.systemFont(ofSize: 12)
        hintLabel.textColor = NSColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1.0)

        googleNavView.addSubview(backButton)
        googleNavView.addSubview(hintLabel)

        self.view.addSubview(googleNavView)
        NSLayoutConstraint.activate([
            googleNavView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            googleNavView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            googleNavView.topAnchor.constraint(equalTo: self.view.topAnchor),
            googleNavView.heightAnchor.constraint(equalToConstant: 48),

            backButton.leadingAnchor.constraint(equalTo: googleNavView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: googleNavView.centerYAnchor),

            hintLabel.trailingAnchor.constraint(equalTo: googleNavView.trailingAnchor, constant: -16),
            hintLabel.centerYAnchor.constraint(equalTo: googleNavView.centerYAnchor)
        ])
    }

    // MARK: - Splash / Loading View
    private func setupSplashView() {
        splashView = NSView(frame: self.view.bounds)
        splashView.translatesAutoresizingMaskIntoConstraints = false
        splashView.wantsLayer = true
        splashView.layer?.backgroundColor = NSColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0).cgColor

        let titleLabel = NSTextField(labelWithString: "MCUApps")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 34)
        titleLabel.textColor = NSColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0)
        titleLabel.alignment = .center

        let subLabel = NSTextField(labelWithString: "Memuat Platform Pembelajaran Kuliah Kesehatan...")
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.font = NSFont.systemFont(ofSize: 13)
        subLabel.textColor = NSColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1.0)
        subLabel.alignment = .center

        progressIndicator = NSProgressIndicator()
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .regular
        progressIndicator.startAnimation(nil)

        splashView.addSubview(titleLabel)
        splashView.addSubview(subLabel)
        splashView.addSubview(progressIndicator)

        self.view.addSubview(splashView)
        NSLayoutConstraint.activate([
            splashView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            splashView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            splashView.topAnchor.constraint(equalTo: self.view.topAnchor),
            splashView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: splashView.centerYAnchor, constant: -40),

            subLabel.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            progressIndicator.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
            progressIndicator.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 20)
        ])
    }

    // MARK: - Error / Offline View
    private func setupErrorView() {
        errorView = NSView(frame: self.view.bounds)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.wantsLayer = true
        errorView.layer?.backgroundColor = NSColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0).cgColor
        errorView.isHidden = true

        let card = NSView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.white.cgColor
        card.layer?.cornerRadius = 12
        card.layer?.shadowColor = NSColor.black.withAlphaComponent(0.08).cgColor
        card.layer?.shadowOpacity = 1.0
        card.layer?.shadowRadius = 16
        card.layer?.shadowOffset = CGSize(width: 0, height: 4)

        let title = NSTextField(labelWithString: "Tidak Ada Koneksi Internet")
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = NSFont.boldSystemFont(ofSize: 18)
        title.textColor = NSColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)
        title.alignment = .center

        let desc = NSTextField(wrappingLabelWithString: "Pastikan perangkat Mac Anda terhubung ke jaringan internet (WiFi / Seluler) untuk mengakses MCUApps.")
        desc.translatesAutoresizingMaskIntoConstraints = false
        desc.font = NSFont.systemFont(ofSize: 13)
        desc.textColor = NSColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1.0)
        desc.alignment = .center

        let retryBtn = NSButton(title: "Coba Lagi", target: self, action: #selector(retryLoading))
        retryBtn.translatesAutoresizingMaskIntoConstraints = false
        retryBtn.bezelStyle = .rounded
        retryBtn.font = NSFont.boldSystemFont(ofSize: 13)
        retryBtn.contentTintColor = NSColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0)

        card.addSubview(title)
        card.addSubview(desc)
        card.addSubview(retryBtn)
        errorView.addSubview(card)

        self.view.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: self.view.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            card.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 440),
            card.heightAnchor.constraint(equalToConstant: 220),

            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            desc.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            retryBtn.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 20),
            retryBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            retryBtn.widthAnchor.constraint(equalToConstant: 140),
            retryBtn.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - Navigation Actions
    func loadApp() {
        if let url = URL(string: appUrlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    @objc func navigateToLogin() {
        googleNavView.isHidden = true
        loadApp()
    }

    @objc func retryLoading() {
        errorView.isHidden = true
        splashView.isHidden = false
        progressIndicator.startAnimation(nil)
        loadApp()
    }

    func reloadPage() {
        webView.reload()
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    func zoomIn() {
        currentZoomFactor = min(2.5, currentZoomFactor + 0.1)
        applyZoom()
    }

    func zoomOut() {
        currentZoomFactor = max(0.5, currentZoomFactor - 0.1)
        applyZoom()
    }

    func zoomReset() {
        currentZoomFactor = 1.0
        applyZoom()
    }

    private func applyZoom() {
        webView.pageZoom = CGFloat(currentZoomFactor)
    }

    func handleEscapeKey() {
        if !googleNavView.isHidden {
            navigateToLogin()
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString.lowercased()

        // 1. Intercept Sign in with Apple (Web redirect or OAuth authorization URL)
        // This triggers macOS native Touch ID / Apple ID sheet directly without browser login!
        if urlString.contains("/auth/apple/redirect") || urlString.contains("appleid.apple.com/auth/authorize") {
            decisionHandler(.cancel)
            performNativeAppleSignIn()
            return
        }

        // 2. Check if external domains (WhatsApp, Shopee, Linktree) -> open in system browser
        if urlString.contains("wa.me") || urlString.contains("whatsapp.com") || urlString.contains("shopee.co.id") || urlString.contains("linktr.ee") {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // 3. Google OAuth / Sign In Detection
        if urlString.contains("accounts.google.com") || urlString.contains("google.com/o/oauth") || urlString.contains("google.com/signin") {
            googleNavView.isHidden = false
            self.view.bringSubviewToFront(googleNavView)
        } else {
            googleNavView.isHidden = true
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        splashView.isHidden = true
        errorView.isHidden = true
        progressIndicator.stopAnimation(nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError()
    }

    private func showError() {
        splashView.isHidden = true
        progressIndicator.stopAnimation(nil)
        errorView.isHidden = false
        self.view.bringSubviewToFront(errorView)
    }

    // MARK: - WKUIDelegate (Popups and new windows)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let targetUrl = navigationAction.request.url {
            let targetString = targetUrl.absoluteString.lowercased()
            if targetString.contains("/auth/apple/redirect") || targetString.contains("appleid.apple.com") {
                performNativeAppleSignIn()
                return nil
            }
            if targetString.contains("mcu-apps.co.id") || targetString.contains("accounts.google.com") || targetString.contains("google.com") {
                webView.load(navigationAction.request)
            } else {
                NSWorkspace.shared.open(targetUrl)
            }
        }
        return nil
    }

    // MARK: - Native Sign in with Apple (Touch ID / iCloud Sheet)
    @objc func performNativeAppleSignIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window ?? NSApplication.shared.windows.first ?? NSWindow()
    }

    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        let appleId = appleIDCredential.user
        let email = appleIDCredential.email ?? ""
        let identityToken = appleIDCredential.identityToken.flatMap { String(data: $0, encoding: .utf8) } ?? ""

        var fullNameString = ""
        if let fullName = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            fullNameString = formatter.string(from: fullName)
        }

        submitAppleAuthToWebView(appleId: appleId, email: email, name: fullNameString, identityToken: identityToken)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("[MCUApps] Sign in with Apple canceled or failed: \(error.localizedDescription)")
    }

    private func submitAppleAuthToWebView(appleId: String, email: String, name: String, identityToken: String) {
        let payload: [String: String] = [
            "apple_id": appleId,
            "email": email,
            "name": name,
            "identity_token": identityToken,
            "platform": "macOS"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let jsCode = """
        (function() {
            const data = \(jsonString);
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/auth/apple/native';

            for (const key in data) {
                if (data.hasOwnProperty(key)) {
                    const input = document.createElement('input');
                    input.type = 'hidden';
                    input.name = key;
                    input.value = data[key];
                    form.appendChild(input);
                }
            }

            if (document.body) {
                document.body.appendChild(form);
            } else {
                document.documentElement.appendChild(form);
            }
            form.submit();
        })();
        """

        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(jsCode) { _, error in
                if let error = error {
                    print("[MCUApps] Error submitting Apple Auth to WebView: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Message Handler for Escape Key
private class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var parent: WebViewController?

    init(parent: WebViewController) {
        self.parent = parent
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? String, body == "ESCAPE_PRESSED" {
            DispatchQueue.main.async {
                self.parent?.handleEscapeKey()
            }
        }
    }
}