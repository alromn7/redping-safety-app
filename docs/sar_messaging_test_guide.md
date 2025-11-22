# SAR Messaging Test Guide

## Overview
This guide explains how to test the SAR (Search and Rescue) messaging functionality in the REDP!NG app.

## Testing SAR Messaging

### 1. Access SAR Page
1. Open the app
2. Navigate to the SAR section from the main navigation
3. You should see the SAR dashboard with various controls

### 2. Test SOS Alert Reception
1. On the SAR page, look for the "Test SOS Ping" button
2. Click the button to simulate an incoming SOS alert
3. A confirmation dialog should appear
4. Confirm to send the test SOS alert

### 3. View SOS Alert Details
1. After sending the test SOS alert, it should appear in the SAR updates list
2. The alert should show as a red/critical item
3. Click on the SOS alert to view detailed information

### 4. Test Message Composer
1. In the SOS alert detail view, you should see a "Send Message" button
2. Click the button to open the message composer dialog
3. The dialog should show:
   - Message input field
   - Priority selector (Low, Medium, High, Critical)
   - Message type selector (SAR Response, User Response, etc.)
   - Send button

### 5. Send a Message
1. Type a test message in the input field
2. Select a priority level
3. Select a message type
4. Click "Send Message"
5. You should see:
   - Loading state on the send button
   - Dialog closes automatically
   - Success message appears at the bottom

### 6. Test Quick Message Actions
1. In the SOS alert detail view, look for "Quick Message Actions"
2. You should see buttons for:
   - Status Update
   - Location Update
3. Click any of these buttons
4. The message should be sent automatically with predefined content
5. Success feedback should appear

### 7. Test Contact Options
1. In the SOS alert detail view, click the "Contact" button
2. A dialog should appear with contact options
3. Options should include:
   - Call user directly
   - Call emergency contacts
4. Note: Actual calling functionality is not implemented yet (shows TODO)

## Expected Behavior

### Message Sending
- Messages should be sent through the SAR messaging service
- Success/error feedback should be displayed
- Dialog should close automatically on success
- Error messages should be shown for failures

### Message Content
- Custom messages should preserve the exact text entered
- Quick actions should send predefined professional messages
- All messages should include proper metadata

### UI/UX
- Loading states should be shown during message sending
- Buttons should be disabled during sending
- Success/error feedback should be clearly visible
- Dialog navigation should work properly

## Troubleshooting

### If Messages Don't Send
1. Check if the app is running without compilation errors
2. Verify that the SAR messaging service is initialized
3. Check the console for any error messages
4. Ensure the service manager is properly initialized

### If UI Doesn't Work
1. Check if the SOS alert detail card is displayed correctly
2. Verify that all buttons are clickable
3. Check for any layout issues in the message composer
4. Ensure proper imports are in place

### If No SOS Alerts Appear
1. Make sure the test SOS ping button is working
2. Check if the SAR service is properly handling incoming alerts
3. Verify that the alert is being added to the updates list
4. Check the console for SAR service logs

## Technical Notes

### Service Integration
- SAR messaging uses `SARMessagingService`
- Messages are sent via `EmergencyMessagingService`
- Service manager coordinates all messaging operations

### Message Flow
1. User composes message in `SARMessageComposer`
2. Message is sent via `SARMessagingService.sendMessageToSOSUser`
3. Service handles message delivery and feedback
4. UI shows appropriate success/error messages

### Error Handling
- All message sending operations are wrapped in try-catch
- User-friendly error messages are displayed
- Service initialization is checked before sending
- Graceful fallbacks for service unavailability
