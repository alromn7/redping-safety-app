# RedPing Subscription Testing Guide

## Test Scenarios & Scripts

### Scenario 1: New User Free Trial to Paid Conversion

**User Story:** New user signs up, uses free tier, then upgrades to Essential+

**Steps:**
1. Create new account
2. Verify free tier features accessible
3. Attempt blocked feature (Medical Profile)
4. Tap "Upgrade" in dialog
5. Select Essential+ plan
6. Enter payment details
7. Complete payment
8. Verify medical profile now accessible

**Expected Results:**
- Free features work immediately
- Medical profile blocked with upgrade prompt
- Payment processed successfully
- Subscription activated
- Medical profile unlocked

**Test Data:**
```
Card: 4242 4242 4242 4242
Expiry: 12/25
CVC: 123
Name: Test User
```

**Validation:**
- [ ] Firestore subscription document created
- [ ] Transaction logged in transactions collection
- [ ] Stripe subscription created in Dashboard
- [ ] Webhook received and processed
- [ ] Feature access updated immediately

---

### Scenario 2: Failed Payment Handling

**User Story:** User's card payment fails, system handles gracefully

**Test Cards:**
```
Declined: 4000 0000 0000 0002
Insufficient: 4000 0000 0000 9995
Success: 4242 4242 4242 4242
```

**Expected Results:**
- Clear error message displayed
- Option to retry
- Failed transaction logged
- No subscription created
- Retry succeeds with valid card

---

### Scenario 3: 3D Secure Authentication

**User Story:** User with 3D Secure card completes authentication

**Test Card:**
```
Card: 4000 0027 6000 3184
Expiry: 12/25
CVC: 123
```

**Expected Results:**
- 3D Secure modal appears
- User completes authentication
- Payment processed after auth
- Subscription created

---

## Test Cards Summary

```
✅ Success: 4242 4242 4242 4242
✅ 3D Secure: 4000 0027 6000 3184
❌ Declined: 4000 0000 0000 0002
❌ Insufficient: 4000 0000 0000 9995
✅ Mastercard: 5555 5555 5555 4444
✅ Amex: 3782 822463 10005
```

---

**Testing Complete:** Ready for production deployment.
