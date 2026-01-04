package com.rakhul.unfilter

import java.util.regex.Pattern

object LibSignatures {

    enum class MatchType {
        NATIVE_LIB, // specific .so file name regex
        DEX_PATH,   // java package path regex in DEX strings (e.g. Lcom/squareup/retrofit2)
        ASSET_FILE  // file path in assets/ regex
    }

    data class Rule(
        val name: String,
        val type: MatchType,
        val pattern: String,
        val category: String,
        val versionRegex: String? = null // Optional regex to extract version if match found
    )

    // A comprehensive list of popular libraries and frameworks
    val RULES = listOf(
        // --- Frameworks ---
        Rule("Flutter", MatchType.NATIVE_LIB, "libflutter\\.so", "Framework", "Flutter (\\d+\\.\\d+\\.\\d+)"),
        Rule("Flutter", MatchType.DEX_PATH, "Lio/flutter/", "Framework"),
        Rule("React Native", MatchType.NATIVE_LIB, "libreactnativejni\\.so|libhermes\\.so", "Framework"),
        Rule("React Native", MatchType.ASSET_FILE, "assets/index\\.android\\.bundle", "Framework"),
        Rule("Xamarin", MatchType.NATIVE_LIB, "libmonodroid\\.so|libxamarin.*\\.so", "Framework"),
        Rule("Unity", MatchType.NATIVE_LIB, "libunity\\.so", "Game Engine", "(\\d+\\.\\d+\\.\\d+[a-z]\\d+)"),
        Rule("Godot", MatchType.NATIVE_LIB, "libgodot_android\\.so", "Game Engine"),
        Rule("Unreal Engine", MatchType.NATIVE_LIB, "libUE4\\.so", "Game Engine"),
        Rule("Cordova", MatchType.ASSET_FILE, ".*cordova\\.js", "Framework"),
        Rule("Cordova", MatchType.DEX_PATH, "Lorg/apache/cordova/", "Framework"),
        Rule("Ionic", MatchType.ASSET_FILE, "assets/www/index\\.html", "Framework"),
        Rule("NativeScript", MatchType.NATIVE_LIB, "libns-internal\\.so", "Framework"),
        Rule("Corona SDK", MatchType.NATIVE_LIB, "liblua\\.so|libcorona\\.so", "Game Engine"),

        // --- Networking ---
        Rule("Retrofit", MatchType.DEX_PATH, "Lretrofit2/", "Networking"),
        Rule("OkHttp", MatchType.DEX_PATH, "Lokhttp3/", "Networking"),
        Rule("Volley", MatchType.DEX_PATH, "Lcom/android/volley/", "Networking"),
        Rule("Ktor", MatchType.DEX_PATH, "Lio/ktor/", "Networking"),
        Rule("Android Async Http", MatchType.DEX_PATH, "Lcom/loopj/android/http/", "Networking"),
        
        // --- Image Loading ---
        Rule("Glide", MatchType.DEX_PATH, "Lcom/bumptech/glide/", "Image Loading"),
        Rule("Picasso", MatchType.DEX_PATH, "Lcom/squareup/picasso/", "Image Loading"),
        Rule("Coil", MatchType.DEX_PATH, "Lcoil/", "Image Loading"),
        Rule("Fresco", MatchType.DEX_PATH, "Lcom/facebook/fresco/", "Image Loading"),
        Rule("Universal Image Loader", MatchType.DEX_PATH, "Lcom/nostra13/universalimageloader/", "Image Loading"),

        // --- Database / Storage ---
        Rule("Room", MatchType.DEX_PATH, "Landroidx/room/", "Database"),
        Rule("Realm", MatchType.DEX_PATH, "Lio/realm/", "Database"),
        Rule("SQLite", MatchType.DEX_PATH, "Landroid/database/sqlite/", "Database"),
        Rule("Firebase Realtime DB", MatchType.DEX_PATH, "Lcom/google/firebase/database/", "Database"),
        Rule("Firestore", MatchType.DEX_PATH, "Lcom/google/firebase/firestore/", "Database"),
        Rule("ObjectBox", MatchType.DEX_PATH, "Lio/objectbox/", "Database"),
        Rule("Hive", MatchType.DEX_PATH, "Lhive/", "Database"), // Flutter Hive often leaves native traces or method channels
        Rule("Supabase", MatchType.DEX_PATH, "Lio/supabase/", "Database"),

        // --- Backend / Cloud ---
        Rule("Firebase Core", MatchType.DEX_PATH, "Lcom/google/firebase/", "Cloud"),
        Rule("Firebase Analytics", MatchType.DEX_PATH, "Lcom/google/firebase/analytics/", "Analytics"),
        Rule("AppCenter", MatchType.DEX_PATH, "Lcom/microsoft/appcenter/", "Cloud"),
        Rule("AWS Amplify", MatchType.DEX_PATH, "Lcom/amplifyframework/", "Cloud"),

        // --- Dependency Injection ---
        Rule("Dagger", MatchType.DEX_PATH, "Ldagger/", "DI"),
        Rule("Hilt", MatchType.DEX_PATH, "Ldagger/hilt/", "DI"),
        Rule("Koin", MatchType.DEX_PATH, "Lorg/koin/", "DI"),
        Rule("Kodein", MatchType.DEX_PATH, "Lorg/kodein/", "DI"),

        // --- Reactive / Async ---
        Rule("RxJava", MatchType.DEX_PATH, "Lio/reactivex/", "Async"),
        Rule("Coroutines", MatchType.DEX_PATH, "Lkotlinx/coroutines/", "Async"),
        Rule("EventBus", MatchType.DEX_PATH, "Lorg/greenrobot/eventbus/", "Async"),

        // --- UI / Design ---
        Rule("Jetpack Compose", MatchType.DEX_PATH, "Landroidx/compose/", "UI"),
        Rule("Material Components", MatchType.DEX_PATH, "Lcom/google/android/material/", "UI"),
        Rule("Lottie", MatchType.DEX_PATH, "Lcom/airbnb/lottie/", "UI"),
        Rule("MPAndroidChart", MatchType.DEX_PATH, "Lcom/github/mikephil/charting/", "UI"),

        // --- Ads / Monetization ---
        Rule("AdMob", MatchType.DEX_PATH, "Lcom/google/android/gms/ads/", "Ads"),
        Rule("Facebook Audience Network", MatchType.DEX_PATH, "Lcom/facebook/ads/", "Ads"),
        Rule("Unity Ads", MatchType.DEX_PATH, "Lcom/unity3d/ads/", "Ads"),
        Rule("AppLovin", MatchType.DEX_PATH, "Lcom/applovin/", "Ads"),
        Rule("IronSource", MatchType.DEX_PATH, "Lcom/ironsource/", "Ads"),

        // --- Maps ---
        Rule("Google Maps", MatchType.DEX_PATH, "Lcom/google/android/gms/maps/", "Maps"),
        Rule("Mapbox", MatchType.DEX_PATH, "Lcom/mapbox/", "Maps"),
        Rule("Osmdroid", MatchType.DEX_PATH, "Lorg/osmdroid/", "Maps"),

        // --- Analytics / Crash Reporting ---
        Rule("Crashlytics", MatchType.DEX_PATH, "Lcom/google/firebase/crashlytics/", "Crash Reporting"),
        Rule("Sentry", MatchType.DEX_PATH, "Lio/sentry/", "Crash Reporting"),
        Rule("Instabug", MatchType.DEX_PATH, "Lcom/instabug/", "Crash Reporting"),
        Rule("Mixpanel", MatchType.DEX_PATH, "Lcom/mixpanel/", "Analytics"),
        Rule("Segment", MatchType.DEX_PATH, "Lcom/segment/", "Analytics"),
        Rule("Adjust", MatchType.DEX_PATH, "Lcom/adjust/sdk/", "Analytics"),
        Rule("AppsFlyer", MatchType.DEX_PATH, "Lcom/appsflyer/", "Analytics"),

        // --- Payments ---
        Rule("Stripe", MatchType.DEX_PATH, "Lcom/stripe/android/", "Payments"),
        Rule("Braintree", MatchType.DEX_PATH, "Lcom/braintreepayments/", "Payments"),
        Rule("Razorpay", MatchType.DEX_PATH, "Lcom/razorpay/", "Payments"),
        Rule("Square", MatchType.DEX_PATH, "Lcom/squareup/", "Payments"), // Careful, might overlap with retrofit
    )
}
