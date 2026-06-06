# Google Maps API Key Setup — Client Guide

This document walks you through creating the Google Maps API key BROKKER-SPOT
needs. The app uses Google services in three places, so a **single key** with
the right APIs enabled and the right restrictions will cover everything:

| Used for | Google API |
|---|---|
| Map rendering inside the app (Android & iOS) | Maps SDK for Android, Maps SDK for iOS |
| Reverse-geocoding latitude/longitude → address (the location picker) | **Geocoding API** |
| Address autocomplete in the location search bar | **Places API** |
| (Optional) Map JS in a web build, if you ever ship one | Maps JavaScript API |

> **You will need a credit/debit card.** Google requires a billing account to
> use these APIs, but it provides $200 of free monthly credit which is more
> than enough for normal app usage. You will not be charged unless you exceed
> that credit.

---

## 1. Create or pick a Google Cloud project

1. Open <https://console.cloud.google.com/> and sign in with the Google
   account that should **own** the API key (use a company account, not a
   personal Gmail, if possible).
2. Click the **project picker** in the top bar (next to "Google Cloud") →
   **New Project**.
3. Fill in:
   - **Project name**: `BrokkerSpot` (or any name you'll recognize).
   - **Organization / Location**: leave default unless you use Google
     Workspace.
4. Click **Create** and wait ~30 seconds for the project to be ready, then
   make sure the project picker is showing the new project.

---

## 2. Enable billing

1. From the left menu choose **Billing**.
2. If you don't have a billing account yet, click **Link a billing account
   → Create billing account** and follow the steps (name, country, payment
   method).
3. Link the billing account to the BrokkerSpot project.

> Without billing enabled, every API call returns `REQUEST_DENIED` even if
> everything else is configured correctly.

---

## 3. Enable the APIs

You need to enable each API individually.

1. Left menu → **APIs & Services → Library**.
2. Search for each name below and click **Enable** for each. (If it says
   "Manage" instead of "Enable", it's already on — skip it.)

   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**
   - **Places API**
   - **Maps JavaScript API** *(only if you plan to ship a web build)*

> A common mistake is enabling Maps SDK for Android only. The location
> picker's "select location" button stays disabled if **Geocoding API** is
> not enabled.

---

## 4. Create the API key

1. Left menu → **APIs & Services → Credentials**.
2. Click **+ Create Credentials → API key**.
3. Google generates a key like `AIzaSyD…`. Copy it once — you can reopen
   the key later but it's easier to grab it now.

---

## 5. Restrict the key (important for security)

A bare unrestricted key works but anyone who decompiles the APK can use it
and run up your bill. Restrict it like this:

1. In the Credentials list, click the **pencil/edit icon** next to your new key.
2. Give it a clear name, e.g. `BrokkerSpot Mobile`.

### 5a. Application restrictions

Choose **None** for now (recommended for the first ship). The reason: the
Android-package restriction blocks HTTP calls to Geocoding/Places from inside
the app, which would silently break the location picker.

If you want to lock it down later, you have two options:

**Option A — single unrestricted key (simplest, recommended at first):**
Leave **Application restrictions = None**. Lock it down with **API
restrictions** in step 5b instead. The key can then be used by:
- Maps SDK on Android
- Maps SDK on iOS
- HTTP calls from the app to Geocoding/Places

**Option B — two keys (more secure, more work):**
- Key 1 = Android-restricted (package + SHA-1 fingerprint). Used only for
  Maps SDK Android.
- Key 2 = iOS-restricted (bundle id). Used only for Maps SDK iOS.
- Key 3 = unrestricted or IP-restricted. Used for the in-app Geocoding /
  Places HTTP calls.

Most teams use Option A. Switch to Option B before you have heavy traffic.

### 5b. API restrictions

Choose **Restrict key → Select APIs** and tick only these:

- Maps SDK for Android
- Maps SDK for iOS
- Geocoding API
- Places API
- (Maps JavaScript API if you enabled it in step 3)

Click **Save**.

---

## 6. Give the key to the developer

Share the key value over a secure channel (1Password, encrypted email, etc.
— not plain WhatsApp or screenshots posted publicly).

What the developer needs:
1. **The API key string** (`AIzaSy...`).
2. Confirmation of which APIs are enabled (so they know what features they
   can rely on).
3. *Optional but useful:* the GCP project ID, so the dev can be added as a
   viewer if they need to debug billing/usage.

The developer will paste the key into:

- `android/app/src/main/AndroidManifest.xml` (Maps SDK for Android)
- `ios/Runner/AppDelegate.swift` (Maps SDK for iOS)
- A `.dart` constant for the Geocoding/Places HTTP calls (or, better,
  fetched at runtime from a server-side config so the key isn't baked into
  the APK).

---

## 7. Confirm it works (developer check)

After the key is in place, the developer should see in logcat:

```
🗺️ [Geocode] 200 <- {"results":[...],"status":"OK"}
```

If you see any of these instead, fix as noted:

| Status | Meaning | Fix |
|---|---|---|
| `REQUEST_DENIED` + `This API project is not authorized to use this API` | The API you're calling isn't enabled on this project | Step 3: enable the missing API |
| `REQUEST_DENIED` + `API keys with referer restrictions cannot be used with this API` | Application restriction is Android/iOS only but key is being used over HTTP | Step 5a: switch to "None" (Option A) or create a separate unrestricted key (Option B) |
| `REQUEST_DENIED` + `You must enable Billing` | Billing not enabled on the project | Step 2 |
| `OVER_QUERY_LIMIT` | Daily/monthly free tier exhausted | Wait for reset or raise quota in GCP |
| `ZERO_RESULTS` | Valid call, just no address at that coordinate | Not an error — handled in-app |

---

## 8. Set a budget alert (recommended)

To avoid surprise bills:

1. Left menu → **Billing → Budgets & alerts → Create budget**.
2. Set a monthly limit (e.g. $50) and email alerts at 50%, 90%, 100%.
3. This won't block traffic — it only emails you. To hard-cap usage, set
   quota limits per API under **APIs & Services → Quotas**.

---

## 9. Rotate the key if it leaks

If the key string is accidentally shared publicly (committed to a public
repo, screenshotted in a chat, etc.):

1. Credentials → click the leaked key → **Regenerate Key**.
2. Update the new value in the three places listed in step 6.
3. Old key stops working immediately.

---

## Quick checklist for the client

- [ ] GCP project created
- [ ] Billing enabled
- [ ] Maps SDK for Android — Enabled
- [ ] Maps SDK for iOS — Enabled
- [ ] Geocoding API — Enabled
- [ ] Places API — Enabled
- [ ] API key created
- [ ] API restrictions set to the five APIs above
- [ ] Key shared with the developer via a secure channel
- [ ] Budget alert created
