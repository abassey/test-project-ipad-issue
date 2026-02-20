//
//  MessagesViewController.swift
//  Minimal reproduction: didSelect works on iPhone but not iPad
//
//  ISSUE: On iPad, after using the extension once, tapping message bubbles
//  does not reliably trigger didSelect. Works correctly on iPhone.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    var label: UILabel!
    var logTextView: UITextView!
    var messageCount: Int = 0
    var selectCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        log("viewDidLoad")
    }
    
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        label = UILabel()
        label.text = "Send messages, then tap the bubbles"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Message", for: .normal)
        sendButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        logTextView = UITextView()
        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.layer.cornerRadius = 8
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logTextView)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            sendButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            logTextView.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 16),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    func log(_ message: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let line = "[\(time)] [\(device)] \(message)\n"
        print(line)
        DispatchQueue.main.async {
            self.logTextView?.text.append(line)
            if let tv = self.logTextView {
                tv.scrollRangeToVisible(NSRange(location: tv.text.count - 1, length: 1))
            }
        }
    }
    
    @objc func sendTapped() {
        guard let conversation = activeConversation else {
            log("ERROR: No conversation")
            return
        }
        
        messageCount += 1
        let message = MSMessage(session: conversation.selectedMessage?.session ?? MSSession())
        let layout = MSMessageTemplateLayout()
        layout.caption = "Message #\(messageCount)"
        layout.subcaption = "Tap this bubble to test"
        message.layout = layout
        
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "n", value: "\(messageCount)")]
        message.url = components.url
        
        conversation.insert(message) { [weak self] error in
            if let error = error {
                self?.log("Send error: \(error.localizedDescription)")
            } else {
                self?.log("Sent message #\(self?.messageCount ?? 0)")
                self?.requestPresentationStyle(.compact)
            }
        }
    }
    
    // MARK: - iMessage Lifecycle
    //
    // BUG: On iPad, didSelect stops being called after the extension is used.
    // On iPhone, didSelect is called reliably every time a message is tapped.
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        log("willBecomeActive")
    }
    
    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        log("didBecomeActive")
    }
    
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        selectCount += 1
        log("didSelect ✓✓✓ (#\(selectCount)) - SHOULD APPEAR ON EVERY TAP")
        label.text = "didSelect called! (#\(selectCount))"
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        log("didTransition -> \(presentationStyle == .expanded ? "expanded" : "compact")")
    }
}


