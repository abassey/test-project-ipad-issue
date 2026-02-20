# didSelect Not Called on iPad

## Summary
`didSelect(_:conversation:)` is not reliably called on iPad when tapping message bubbles after the extension has been used once. The same code works correctly on iPhone.

## Environment
- Xcode 16
- iOS 18 / iPadOS 18
- Affects iPad; iPhone works correctly

## Steps to Reproduce

### On iPhone (works correctly):
1. Build and run on iPhone
2. Open the extension from the app drawer
3. Tap "Send Message" - extension collapses after sending
4. Tap the message bubble
5. ✅ Extension opens, log shows "didSelect ✓✓✓"
6. Repeat steps 3-5 - didSelect is called every time

### On iPad (broken):
1. Build and run on iPad
2. Open the extension from the app drawer
3. Tap "Send Message" - extension collapses after sending
4. Tap the message bubble
5. ❌ Extension does NOT open, no didSelect in log
6. User must scroll away and back, or refresh conversation

## Expected Behavior
`didSelect` should be called when tapping message bubbles on both iPhone and iPad.

## Actual Behavior
- iPhone: `didSelect` called reliably ✓
- iPad: `didSelect` not called after first use ✗

## Question
Is there a recommended workaround for iPad, or is this a known framework limitation?


