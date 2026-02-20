//
//  MessagesViewController.swift
//  Minimal reproduction of iPad didSelect issue
//
//  ISSUE: On iPad, tapping message bubbles does not reliably call didSelect
//  after the extension has been used once. Works perfectly on iPhone.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    var label: UILabel!
    var logTextView: UITextView!
    var counter: Int = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        log("viewDidLoad")
    }
    
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Status label
        label = UILabel()
        label.text = "Tap a message or send one"
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // Send button
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Message", for: .normal)
        sendButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        // Log view to show lifecycle events
        logTextView = UITextView()
        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.layer.cornerRadius = 8
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logTextView)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            sendButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            logTextView.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 20),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let logLine = "[\(timestamp)] [\(device)] \(message)\n"
        print(logLine)
        DispatchQueue.main.async {
            self.logTextView?.text.append(logLine)
            if let textView = self.logTextView {
                let bottom = NSRange(location: textView.text.count - 1, length: 1)
                textView.scrollRangeToVisible(bottom)
            }
        }
    }
    
    // MARK: - Send Message
    
    @objc func sendTapped() {
        guard let conversation = activeConversation else {
            log("ERROR: No active conversation")
            return
        }
        
        counter += 1
        
        let message = MSMessage(session: conversation.selectedMessage?.session ?? MSSession())
        let layout = MSMessageTemplateLayout()
        layout.caption = "Message #\(counter)"
        layout.subcaption = "Tap to test didSelect"
        message.layout = layout
        
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "count", value: "\(counter)")]
        message.url = components.url
        
        conversation.insert(message) { [weak self] error in
            if let error = error {
                self?.log("Send ERROR: \(error.localizedDescription)")
            } else {
                self?.log("Message #\(self?.counter ?? 0) sent")
                self?.requestPresentationStyle(.compact)
            }
        }
    }
    
    // MARK: - iMessage Lifecycle Methods
    // 
    // BUG: On iPad, after sending a message and collapsing, tapping on
    // subsequent message bubbles does NOT call didSelect. The extension
    // does not open. User must refresh conversation for taps to work again.
    //
    // On iPhone, every tap correctly triggers didSelect.
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        let hasSelected = conversation.selectedMessage != nil
        log("willBecomeActive - selectedMessage: \(hasSelected)")
    }
    
    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        let hasSelected = conversation.selectedMessage != nil
        log("didBecomeActive - selectedMessage: \(hasSelected)")
        
        if let url = conversation.selectedMessage?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let countStr = components.queryItems?.first(where: { $0.name == "count" })?.value {
            label.text = "Loaded message #\(countStr)"
            log("Loaded message #\(countStr) from selectedMessage")
        }
    }
    
    override func willSelect(_ message: MSMessage, conversation: MSConversation) {
        super.willSelect(message, conversation: conversation)
        log("willSelect called ✓")
    }
    
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        // THIS METHOD IS NOT CALLED ON IPAD after first use
        log("didSelect called ✓✓✓ - THIS SHOULD APPEAR ON TAP")
        
        if let url = message.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let countStr = components.queryItems?.first(where: { $0.name == "count" })?.value {
            label.text = "Selected message #\(countStr)"
        }
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        log("didReceive called")
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        log("didTransition to: \(presentationStyle == .expanded ? "expanded" : "compact")")
    }
    
    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
        log("didResignActive")
    }
}
