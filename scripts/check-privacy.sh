#!/usr/bin/env bash
# Privacy guard (docs/01 §8, docs/04 §1): the app must not make its own network requests,
# include analytics/advertising SDKs, track users, or write camera images to disk.
set -euo pipefail

cd "$(dirname "$0")/.."
status=0

check() {
    local description="$1" pattern="$2"
    if matches=$(grep -rnE "$pattern" Strengthspan --include='*.swift'); then
        echo "::error::$description"
        echo "$matches"
        status=1
    fi
}

check "Network requests are not allowed in app code" 'URLSession|URLRequest|NWConnection|WebSocket'
check "Analytics, advertising or tracking SDKs are not allowed" 'import (Firebase|FirebaseAnalytics|Mixpanel|Amplitude|Segment|AppsFlyer|Adjust|FBSDK|GoogleMobileAds)|ATTrackingManager|ASIdentifierManager|advertisingIdentifier'
check "Camera frames must never be written to disk" 'AVCapturePhotoOutput|AVCaptureMovieFileOutput|AVAssetWriter|UIImageWriteToSavedPhotosAlbum|PHPhotoLibrary'
check "Apple Health data must not be read" 'HKSampleQuery|HKStatisticsQuery|HKAnchoredObjectQuery|read: \[[^]]'

if grep -q '<true/>' <(sed -n '/NSPrivacyTracking</{n;p;}' Strengthspan/Resources/PrivacyInfo.xcprivacy); then
    echo "::error::PrivacyInfo.xcprivacy must declare NSPrivacyTracking = false"
    status=1
fi

[ "$status" -eq 0 ] && echo "Privacy checks passed"
exit "$status"
