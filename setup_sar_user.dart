#!/usr/bin/env dart


void main() async {
  print('🚁 Setting up SAR Team Member...');

  // This would typically interact with the app's services
  // For now, we'll provide instructions

  print('''
📋 SAR User Setup Instructions:

1. Run the app on emulator-5556:
   flutter run -d emulator-5556

2. Login with SAR credentials:
   Email: sar@example.com
   Password: sar123456

3. Navigate to SAR Registration page:
   - Go to Profile → SAR Registration
   - Fill out the form with these details:
     * Member Type: Professional Rescuer
     * Name: SAR Team Member
     * Phone: +1-555-0123
     * Emergency Contact: +1-555-0124

4. Submit registration and verify:
   - The registration will be pending
   - You can manually verify it in the code

5. Test messaging:
   - Send SOS from emulator-5554 (regular user)
   - Check messages on emulator-5556 (SAR member)
   - Use Test Send button on SAR page

📱 Quick Commands:
   # Regular user (emulator-5554)
   flutter run -d emulator-5554
   
   # SAR member (emulator-5556) 
   flutter run -d emulator-5556
   
   # Clear app data if needed
   adb -s emulator-5556 shell pm clear com.example.redping_14v
''');

  print('✅ Setup instructions ready!');
}













