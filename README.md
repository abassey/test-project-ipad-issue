# iPad iMessage Extension Bug - didSelect Not Called

## Summary
On iPad, `didSelect(_:conversation:)` is not called when tapping message bubbles after the extension has been used once. This works correctly on iPhone.

## Environment
- Xcode 16
- iOS 18 / iPadOS 18
- Tested on iPad Pro (M4), iPad Air
- iPhone works correctly on all tested devices

## Steps to Reproduce

1. Build and run on TWO devices (or simulators) - at least one must be iPad
2. Open Messages on both devices in the same conversation
3. On the iPad:
   - Open the extension from the app drawer
   - Tap "Send Message" to send a test message
   - Extension collapses after sending
4. On the other device:
   - Tap the received message bubble to open extension
   - Tap "Send Message" to reply
5. Back on iPad:
   - **Tap the new message bubble**
   - **BUG: Extension does not open. didSelect is not called.**

## Expected Behavior
Tapping any message bubble should call `didSelect` and open the extension.

## Actual Behavior
On iPad, after sending a message:
- Tapping message bubbles does nothing
- `didSelect` is never called (check console logs)
- User must scroll away and back, or refresh conversation

## Console Output
The app logs all lifecycle events. On iPad you will see:
- `didSelect called ✓✓✓` appears on FIRST tap only
- Subsequent taps show NO lifecycle callbacks at all

On iPhone, `didSelect called ✓✓✓` appears on EVERY tap.

## Workarounds Attempted
- Observing `NSExtensionHostDidBecomeActive` notifications
- Checking `selectedMessage` in `didBecomeActive`
- Forcing UI refresh in `didTransition`
- None of these work because no callbacks fire on tap

## Related Forum Threads
- Thread 53167: "MSMessagesAppViewController.didSelect not called on message reselect"
- Thread 60323: "willSelectMessage and didSelectMessage don't fire"

## Question
Is there a recommended way to detect message taps on iPad, or a way to programmatically deselect messages so subsequent taps register as new selections?
