#!/usr/bin/env pwsh
# Comprehensive Firebase Configuration Migration Verification
# Run this script to verify all systems are migrated from functions.config() to .env

Write-Host "`n" -NoNewline
Write-Host "=" -ForegroundColor Cyan -NoNewline
Write-Host ("=" * 78) -ForegroundColor Cyan
Write-Host "  FIREBASE CONFIGURATION MIGRATION VERIFICATION" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

$allPassed = $true
$testCount = 0
$passCount = 0

function Test-Item {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$SuccessMessage,
        [string]$FailureMessage
    )
    
    $script:testCount++
    Write-Host "`n[$script:testCount] Testing: " -NoNewline -ForegroundColor Yellow
    Write-Host $Name
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "    ✅ PASS: " -NoNewline -ForegroundColor Green
            Write-Host $SuccessMessage
            $script:passCount++
            return $true
        } else {
            Write-Host "    ❌ FAIL: " -NoNewline -ForegroundColor Red
            Write-Host $FailureMessage
            $script:allPassed = $false
            return $false
        }
    } catch {
        Write-Host "    ❌ ERROR: " -NoNewline -ForegroundColor Red
        Write-Host $_.Exception.Message
        $script:allPassed = $false
        return $false
    }
}

Write-Host "`n📋 SECTION 1: Environment File Configuration" -ForegroundColor Cyan
Write-Host ("─" * 80) -ForegroundColor Cyan

Test-Item -Name ".env file exists in redping_14v/functions" -Test {
    Test-Path "c:\flutterapps\redping_14v\functions\.env"
} -SuccessMessage ".env file found" -FailureMessage ".env file missing - migration incomplete"

Test-Item -Name ".env.example file exists" -Test {
    Test-Path "c:\flutterapps\redping_14v\functions\.env.example"
} -SuccessMessage "Template file exists for team members" -FailureMessage "Template missing"

Test-Item -Name ".env is in .gitignore" -Test {
    $gitignore = Get-Content "c:\flutterapps\redping_14v\functions\.gitignore" -Raw
    $gitignore -match "\.env"
} -SuccessMessage "Secrets are protected from version control" -FailureMessage "Security risk: .env not in .gitignore"

Test-Item -Name "STRIPE_SECRET_KEY configured in .env" -Test {
    $env = Get-Content "c:\flutterapps\redping_14v\functions\.env" -Raw
    $env -match "STRIPE_SECRET_KEY=sk_"
} -SuccessMessage "Stripe secret key configured" -FailureMessage "Stripe key missing"

Test-Item -Name "STRIPE_WEBHOOK_SECRET configured in .env" -Test {
    $env = Get-Content "c:\flutterapps\redping_14v\functions\.env" -Raw
    $env -match "STRIPE_WEBHOOK_SECRET=whsec_"
} -SuccessMessage "Webhook secret configured" -FailureMessage "Webhook secret missing"

Test-Item -Name "AGORA_APP_ID configured in .env" -Test {
    $env = Get-Content "c:\flutterapps\redping_14v\functions\.env" -Raw
    $env -match "AGORA_APP_ID="
} -SuccessMessage "Agora credentials configured" -FailureMessage "Agora config missing"

Test-Item -Name "Security config variables in .env" -Test {
    $env = Get-Content "c:\flutterapps\redping_14v\functions\.env" -Raw
    ($env -match "SECURITY_ALLOWED_ORIGINS=") -and 
    ($env -match "SECURITY_SIGNING_REQUIRED=") -and
    ($env -match "SECURITY_SIGNATURE_SKEW_SECONDS=")
} -SuccessMessage "All security variables configured" -FailureMessage "Security variables incomplete"

Write-Host "`n📋 SECTION 2: Code Migration Verification" -ForegroundColor Cyan
Write-Host ("─" * 80) -ForegroundColor Cyan

Test-Item -Name "No functions.config() in subscriptionPayments.js" -Test {
    $content = Get-Content "c:\flutterapps\redping_14v\functions\src\subscriptionPayments.js" -Raw
    $content -notmatch "functions\.config\(\)"
} -SuccessMessage "Migration complete - using process.env" -FailureMessage "Still using deprecated functions.config()"

Test-Item -Name "No functions.config() in index.js" -Test {
    $content = Get-Content "c:\flutterapps\redping_14v\functions\index.js" -Raw
    $content -notmatch "functions\.config\(\)"
} -SuccessMessage "Migration complete - using process.env" -FailureMessage "Still using deprecated functions.config()"

Test-Item -Name "process.env.STRIPE_SECRET_KEY in code" -Test {
    $content = Get-Content "c:\flutterapps\redping_14v\functions\src\subscriptionPayments.js" -Raw
    $content -match "process\.env\.STRIPE_SECRET_KEY"
} -SuccessMessage "Modern environment variable usage" -FailureMessage "Not using process.env"

Test-Item -Name "process.env in index.js security config" -Test {
    $content = Get-Content "c:\flutterapps\redping_14v\functions\index.js" -Raw
    ($content -match "process\.env\.SECURITY_ALLOWED_ORIGINS") -and
    ($content -match "process\.env\.AGORA_APP_ID")
} -SuccessMessage "All configs migrated to process.env" -FailureMessage "Mixed config approaches detected"

Write-Host "`n📋 SECTION 3: Flutter App Configuration" -ForegroundColor Cyan
Write-Host ("─" * 80) -ForegroundColor Cyan

Test-Item -Name "Stripe config exists in Flutter app" -Test {
    Test-Path "c:\flutterapps\redping_14v\lib\core\config\stripe_config.dart"
} -SuccessMessage "Stripe configuration file exists" -FailureMessage "Stripe config missing"

Test-Item -Name "All 8 Price IDs in stripe_config.dart" -Test {
    $content = Get-Content "c:\flutterapps\redping_14v\lib\core\config\stripe_config.dart" -Raw
    $priceIds = @(
        "price_1SVjOcPlurWsomXvo3cJ8YO9",  # Essential+ Monthly
        "price_1SXB6BPlurWsomXv5j56KjdG",  # Essential+ Yearly
        "price_1SVjOIPlurWsomXvOvgWfPFK",  # Pro Monthly
        "price_1SXB4aPlurWsomXvUR3fggRE",  # Pro Yearly
        "price_1SVjNIPlurWsomXvMAxQouxd",  # Ultra Monthly
        "price_1SXB31PlurWsomXvfmQaoq7R",  # Ultra Yearly
        "price_1SVjO7PlurWsomXv9CCcDrGF",  # Family Monthly
        "price_1SX9tyPlurWsomXv5PWCoHJF"   # Family Yearly
    )
    $allFound = $true
    foreach ($id in $priceIds) {
        if ($content -notmatch [regex]::Escape($id)) {
            $allFound = $false
            break
        }
    }
    $allFound
} -SuccessMessage "All 8 subscription price IDs configured" -FailureMessage "Some price IDs missing"

Test-Item -Name "Stripe SDK initialized in main.dart" -Test {
    $content = Get-Content "c:\flutterapps\redping_14v\lib\main.dart" -Raw
    ($content -match "StripeConfig\.initialize") -and
    ($content -match "Stripe\.publishableKey")
} -SuccessMessage "Stripe SDK properly initialized" -FailureMessage "Stripe initialization missing"

Write-Host "`n📋 SECTION 4: Website Configuration" -ForegroundColor Cyan
Write-Host ("─" * 80) -ForegroundColor Cyan

Test-Item -Name "Website .env.local exists" -Test {
    Test-Path "c:\flutterapps\redping_website2\.env.local"
} -SuccessMessage "Local environment configured" -FailureMessage "Website .env.local missing"

Test-Item -Name "Website uses environment variables" -Test {
    $content = Get-Content "c:\flutterapps\redping_website2\src\lib\stripe\config.ts" -Raw
    ($content -match "process\.env\.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY") -and
    ($content -match "process\.env\.STRIPE_SECRET_KEY")
} -SuccessMessage "Website properly uses Next.js env vars" -FailureMessage "Website not using env vars"

Test-Item -Name "Website has all Stripe Price IDs" -Test {
    $content = Get-Content "c:\flutterapps\redping_website2\src\lib\stripe\config.ts" -Raw
    ($content -match "price_1SVjOcPlurWsomXvo3cJ8YO9") -and
    ($content -match "price_1SXB6BPlurWsomXv5j56KjdG") -and
    ($content -match "price_1SVjOIPlurWsomXvOvgWfPFK") -and
    ($content -match "price_1SXB4aPlurWsomXvUR3fggRE")
} -SuccessMessage "All price IDs configured in website" -FailureMessage "Website price IDs incomplete"

Write-Host "`n📋 SECTION 5: Documentation Updates" -ForegroundColor Cyan
Write-Host ("─" * 80) -ForegroundColor Cyan

Test-Item -Name "Migration documentation exists" -Test {
    Test-Path "c:\flutterapps\redping_14v\FIREBASE_CONFIG_MIGRATION_COMPLETE.md"
} -SuccessMessage "Migration guide documented" -FailureMessage "Documentation missing"

Test-Item -Name "Header comments updated in subscriptionPayments.js" -Test {
    $content = Get-Content "c:\flutterapps\redping_14v\functions\src\subscriptionPayments.js" -Raw
    ($content -match "functions/\.env") -and
    ($content -notmatch "firebase functions:config:set")
} -SuccessMessage "Code comments reflect new approach" -FailureMessage "Comments still reference old config method"

Write-Host "`n" -NoNewline
Write-Host "=" -ForegroundColor Cyan -NoNewline
Write-Host ("=" * 78) -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$percentPassed = [math]::Round(($passCount / $testCount) * 100, 1)

Write-Host "`nTotal Tests: " -NoNewline
Write-Host $testCount -ForegroundColor Yellow
Write-Host "Passed:      " -NoNewline
Write-Host $passCount -ForegroundColor Green
Write-Host "Failed:      " -NoNewline
Write-Host ($testCount - $passCount) -ForegroundColor Red
Write-Host "Success Rate: " -NoNewline
Write-Host "$percentPassed%" -ForegroundColor $(if ($percentPassed -eq 100) { "Green" } else { "Yellow" })

Write-Host ""

if ($allPassed) {
    Write-Host "✅ ALL TESTS PASSED - MIGRATION COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 Your Firebase configuration is future-proof!" -ForegroundColor Cyan
    Write-Host "   ✓ Works today with .env files" -ForegroundColor White
    Write-Host "   ✓ Will continue working after March 2026" -ForegroundColor White
    Write-Host "   ✓ No breaking changes required" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Deploy functions: firebase deploy --only functions" -ForegroundColor White
    Write-Host "  2. Test Stripe checkout flow" -ForegroundColor White
    Write-Host "  3. Monitor function logs for any issues" -ForegroundColor White
} else {
    Write-Host "⚠️  SOME TESTS FAILED - REVIEW FAILURES ABOVE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Action Required:" -ForegroundColor Yellow
    Write-Host "  1. Fix any failed checks above" -ForegroundColor White
    Write-Host "  2. Ensure .env file has all required variables" -ForegroundColor White
    Write-Host "  3. Verify no functions.config() calls remain in code" -ForegroundColor White
    Write-Host "  4. Re-run this script to verify fixes" -ForegroundColor White
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

exit $(if ($allPassed) { 0 } else { 1 })
