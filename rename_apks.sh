#!/bin/bash

# Directory where Flutter outputs the APKs
APK_DIR="build/app/outputs/flutter-apk"

# Check if directory exists
if [ ! -d "$APK_DIR" ]; then
    echo "❌ Error: APK directory not found at $APK_DIR"
    echo "Did you run 'flutter build apk' first?"
    exit 1
fi

echo "📂 Processing APKs in $APK_DIR..."

cd "$APK_DIR"

# Renaming Logic
count=0

# Helper function to rename
rename_file() {
    local old_name=$1
    local new_name=$2
    if [ -f "$old_name" ]; then
        mv "$old_name" "$new_name"
        echo "✅ Renamed: $old_name -> $new_name"
        ((count++))
    fi
}

# Rename Split APKs
rename_file "app-arm64-v8a-release.apk" "UnFilter_arm64-v8a.apk"
rename_file "app-armeabi-v7a-release.apk" "UnFilter_armeabi-v7a.apk"
rename_file "app-x86_64-release.apk" "UnFilter_x86_64.apk"

# Rename Universal APK (if it exists)
rename_file "app-release.apk" "UnFilter_universal.apk"

if [ $count -eq 0 ]; then
    echo "⚠️  No matching APK files found to rename."
else
    echo "🎉 Successfully renamed $count APK(s)!"
fi
