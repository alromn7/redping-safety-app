# OpenWeatherMap API Setup

## Get Your Free API Key (Required for Temperature Display)

### Step 1: Sign Up
1. Go to: https://openweathermap.org/api
2. Click "Sign Up" (top right)
3. Create free account with email

### Step 2: Get API Key
1. After login, go to: https://home.openweathermap.org/api_keys
2. Your default API key is already created
3. Copy the API key (looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

### Step 3: Add to RedPing
1. Open: `lib/services/weather_service.dart`
2. Find line 10: `static const String _apiKey = 'YOUR_API_KEY_HERE';`
3. Replace `YOUR_API_KEY_HERE` with your actual API key
4. Save file and hot reload app

### Example:
```dart
static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

## API Limits (Free Tier)
- ✅ 1,000 calls per day
- ✅ 60 calls per minute
- ✅ RedPing updates every 10 minutes = ~144 calls/day (well within limit)

## What You Get
- **Current outdoor temperature** based on your GPS location
- Updates every 10 minutes automatically
- Displayed in the sensor card below RedPing button

## Troubleshooting
- **N/A showing**: API key not added or invalid
- **Takes 10-15 minutes**: New API keys need activation time
- Check console for error messages: "Weather API: Invalid API key"

## Privacy Note
- Only your GPS coordinates are sent to OpenWeatherMap
- No personal information shared
- Industry-standard weather service used by millions of apps
