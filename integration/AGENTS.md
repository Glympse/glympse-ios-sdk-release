# Glympse Core SDK: iOS integration guide for coding agents

Use this when adding the Glympse Core SDK to an iOS app (Swift or Objective-C). The SDK shares a user's location
through time-limited "Glympses" (tickets) delivered by invites, and views Glympses received from others. There is no
login: an anonymous Glympse user is created the first time the SDK starts and is persisted on the device. The API is the
`GlympseKit` module (`import GlympseKit`); all types carry a `Gly` prefix (`GlyGlympse`, `GlyTicket`, ...) and map 1:1 to
the C++ `Glympse::IGlympse`, `ITicket` names. Swift sees the ObjC API: `getX()` stays a method, constants are class
functions. Full API outline: `llms-full.txt`. Not covered: groups, cards, triggers, places, chat, pickups and the map and
UI controls.

## 1. Install (Swift Package Manager)

Xcode: File > Add Package Dependencies, URL `https://github.com/Glympse/glympse-ios-sdk-release`, rule "Up to Next
Major" from the latest release, add the `GlympseKit` product to your app target. The package declares iOS 12 as its
minimum; check it against your deployment target. You also need a Glympse **API key** (request one from Glympse); keep it
out of source control.

## 2. Requirements and capabilities

- Info.plist: `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription`. Add the legacy
  `NSLocationAlwaysUsageDescription` too if you want the SDK to ask for Always itself (see location below). Add
  `NSMotionUsageDescription` if you enable activity recognition.
- Background Modes: `location` (to keep sharing while backgrounded) and `remote-notification` (push).
- Capability Push Notifications (entitlement `aps-environment`: `development` for debug, `production` for release).
- Location authorization: the SDK prompts by itself the first time it starts location (for example when you send a
  Glympse) if the status is still undetermined: Always when `NSLocationAlwaysUsageDescription` exists, else When In Use
  when `NSLocationWhenInUseUsageDescription` exists. To control timing, request authorization yourself first with
  `CLLocationManager` (When In Use, then Always). Status: `getLocationManager().getLocationPermission()` and
  `getLocationState()` (`GlyCoreConstants.location_PERMISSION_*()` / `location_STATE_*()`).
- Notifications: `UNUserNotificationCenter.requestAuthorization`, then `UIApplication.shared.registerForRemoteNotifications()`
  on every launch while authorized, so the APNs token stays fresh.

## 3. Start-up: exact call order

Create ONE platform per process (a global or app-scoped object) on the main thread.
```swift
import GlympseKit

final class GlympseListener: NSObject, GlyEventListener {
    func eventsOccurred(_ glympse: GlyGlympse!, listener: Int32, events: Int32, object: GlyCommon!) {
        DispatchQueue.main.async { /* switch on listener, test (events & GlyGlympseEvents.x()) != 0 */ }
    }
}

let g = GlyGlympseFactory.createGlympse(with: "api.glympse.com", with: apiKey)!   // 1. create
g.add(listener)                                  // 2. BEFORE start: PLATFORM_STARTED fires synchronously inside start()
g.getConsentManager().exempt(fromConsent: true)  // 3. or collect consent (below). Not persisted: set it every launch
//   Also before start (none are persisted): setRestoreHistory, setHistoryLookback, allowSiblingTickets, setEtaMode
g.start()                                        // 4. silently does nothing if server or API key is empty
_ = g.setActive(true)                            // 5. if the app is currently active (see section 4)
```
- Events after `start()`: `platform_STARTED` (plus `platform_FIRST_LAUNCH` the first time) -> `platform_ACCOUNT_CREATED`
  (only when a new anonymous account is made) -> `platform_LOGIN_SUCCEEDED` (every start) ->
  `platform_SYNCED_WITH_SERVER` (once per instance: history is synced and the account is usable). Gate UI that needs
  the account (nickname, avatar, sending) on `SYNCED`. `platform_SESSION_FAILED` means the token expired and the SDK is
  re-authenticating by itself.
- `platform_ACCOUNT_CREATE_FAILED` and `platform_LOGIN_FAILED` are fatal: the platform stops itself (`platform_STOPPED`) and
  cannot restart. Create a new instance and retry later with backoff.
- A started platform cannot be restarted. After `stop()` (or a fatal stop) create a new instance.
- Account persistence: the anonymous account is kept in the Keychain and survives restarts. After an app reinstall the
  SDK detects a clean environment, removes the stale Keychain entries and creates a new account. `logout()` only works
  while stopped (returns `false` otherwise); it wipes the account, nickname, avatar, history and consent, and the next
  `start()` creates a fresh account and fires `platform_FIRST_LAUNCH` again. `isFirstLaunch()` is valid right after
  creation; `hasUserAccount()` says whether an account exists.

### Consent: the account is not created without it

On a clean install the SDK does NOT create the account until the user has consented or the app is exempt. It fires
`listener_CONSENT` / `consent_REQUIRED` and waits; `send(_:)` returns `false` meanwhile. Choose one:
- **Exempt** (only if consent does not apply to your app): `getConsentManager().exempt(fromConsent: true)` before `start()`.
- **Collect consent**: show the agreement (text key `glympse_gdpr_message` in `glympse_api.strings`; if your build does not
  include it, take the wording from Glympse's User Consent guide; links `GlyGlympseConstants.privacy_POLICY_URL()` and
  `terms_AND_CONDITIONS_URL()`), then `getConsentManager().grantConsent(GlyGlympseConstants.consent_TYPE_SUBJECT(),
  partnerId: id)` (`consent_TYPE_GUARDIAN()` for a guardian). This starts account creation. On decline call
  `revokeConsent(partnerId)` and disable Glympse features. `partnerId` is the numeric id Glympse issues with your API key.
  Results: `consent_SUCCEEDED` / `consent_FAILED`. The grant is cached locally, so later launches skip the prompt.

## 4. Lifecycle, threading, state

- The API is not thread safe. Call it only from the thread that created the platform, which needs a run loop (normally
  main). Callbacks arrive on that thread; keep them short. There are no blocking calls. Never call `stop()` from inside
  `eventsOccurred`; post it.
- `getUserManager()`, `getHistoryManager()` and most other managers are nil until `start()`. `getConfig()` and
  `getConsentManager()` work earlier. Do not hold managers; read them from the platform while it runs. User, ticket,
  invite and place objects can be kept for UI.
- `setActive(true/false)` is reference counted and MUST be reciprocal: `true` when the app becomes active, `false` when it
  goes to the background (SwiftUI `scenePhase` `.active` / `.background`, or `UIApplication.didBecomeActiveNotification`
  / `didEnterBackgroundNotification`). It is required even if you rely on background modes. `start()` resets the count to
  0, so call `setActive(true)` right after it when the app is active. SwiftUI's `onChange(of: scenePhase)` does not fire
  for the starting value: pass `initial: true` (iOS 17) or the first activation is never reported.
- Location runs only while a Glympse of yours is active (foreground and background); in the foreground without one it
  stays off. Override with `getLocationManager().startLocation()` / `stopLocation(_:)`.
- Call `stop()` when the app terminates or Glympse is no longer needed. Then drop your reference.
- Events: `eventsOccurred(_:listener:events:object:)`. `listener` is a single value (`GlyGlympseEvents.listener_PLATFORM()`,
  `listener_TICKET()`, `listener_USER()`, `listener_INVITE()`, `listener_CONSENT()`), `events` is a bitmask. Add the same
  listener to the platform and to any sink you care about (a ticket, a user, the `decodeInvite` sink) with `add(_:)`,
  and `remove` it when done. The SDK clears listeners on removed objects and on `stop()`. Low-level events (ticket, user)
  are duplicated on the platform, so subscribing to the platform alone is enough for list-level changes.
- Time: all timestamps are server time in milliseconds. Use `g.getTime()`; `ticket.getExpireTime() - g.getTime()` is the
  remaining time (negative when expired).
- Do not implement SDK model protocols (`GlyTicket`, `GlyInvite`, ...) yourself; get them from `GlyGlympseFactory`. The only
  protocol you implement is `GlyEventListener`. Do not mutate a `GlyArray` while iterating it; read it with `count()` and
  `object(at:)`.
- Your platform properties (`setRestoreHistory`, ETA mode, siblings) are not persisted. `getConfig()` properties
  (expire-on-arrival, speed sharing) are persisted and need setting once, for example on `platform_FIRST_LAUNCH`.

## 5. Main flows

**Send a Glympse**
1. Wait for `platform_SYNCED_WITH_SERVER`, consent granted or exempt, and location authorized.
2. `let t = GlyGlympseFactory.createTicket(durationMs, message: msg, destination: place)!` (`place` from
   `GlyGlympseFactory.createPlace(lat, longitude: lng, name: n)`, optional). Minimum 10 s; the default maximum is 4 hours
   (`getConfig().getMaximumTicketDuration()`).
3. `let inv = GlyGlympseFactory.createInvite(with: GlyGlympseConstants.invite_TYPE_LINK(), with: name, with: address)!`;
   `t.add(inv)`. Types: `LINK` (your app delivers the URL), `EMAIL`, `SMS`, `ACCOUNT`, `GROUP`, ...; name/address
   meaning per type is in `llms-full.txt`.
4. `t.add(listener)` (or react to `platform_TICKET_ADDED`), then `g.send(t)`. It returns `false` when not started, without
   consent, already sent, or nil; otherwise creation continues in the background.
5. Events on the ticket: `ticket_CREATED` (created on the server; invite codes and URLs are NOT ready yet) ->
   `ticket_INVITE_CREATED` (client-delivered invites such as `LINK`: state `invite_STATE_NEEDTOSEND()`, read
   `invite.getUrl()`) or `ticket_INVITE_SENT` (server-delivered) -> `ticket_INVITE_UPDATED` (viewers) -> `ticket_EXPIRED`
   -> `ticket_COMPLETED` (data fully uploaded). Failures: `ticket_FAILED` (discard and retry with a new ticket),
   `ticket_INVITE_FAILED` (add a NEW invite object).
6. For a `LINK` invite share `getUrl()` yourself, then `initiateClientSideSend()` (optional) and
   `completeClientSideSend(true/false)` to report the outcome.
7. Change a sent ticket: `modify(_:message:destination:)`, `clear(...)`, `extend(_:)`, `add(_:)` / `deleteInvite` for invites,
   `expire()`. After expiry the ticket is immutable.
8. After a restart the platform restores your active tickets from the server (`getHistoryManager().getTickets()`, with
   `platform_TICKET_ADDED`). Expired history only comes back with `setRestoreHistory(true)` (look-back via
   `setHistoryLookback`, server default about 30 days). Tickets from your other apps/devices ("siblings") are excluded
   unless `allowSiblingTickets(true)`.

**View a Glympse**
1. Pass the invite code to `g.decodeInvite(with: code, with: mode)` or, for free-form text containing a Glympse URL, to
   `g.openUrl(text, mode: mode, invite: nil)`. `extractInviteCodes(_:)` is safe from any thread, but decode on the main thread.
2. `mode = GlyGlympseConstants.invite_MODE_DEFAULT() | GlyGlympseConstants.invite_MODE_ACTIVATE_USER()` views the ticket
   automatically AND starts pulling updates. `invite_MODE_DEFAULT()` alone views it but does not track it.
   `invite_MODE_PROMPT_BEFORE_VIEWING()` sends `platform_INVITE_TICKET` with a `GlyUserTicket`; show a confirmation, then
   call `g.viewTicket(userTicket)`.
3. Live updates come only for tracked users, and only while the platform is active (foreground). If you did not use
   `ACTIVATE_USER`, call `getUserManager().startTracking(user)` (reference counted; pair with `stopTracking`, or use
   `startTrackingAll()`).
4. Events: `platform_USER_ADDED` (a `GlyUser`), `user_ACTIVE_TICKET_CHANGED`, `user_TICKET_ADDED/REMOVED`, then ticket
   events (`ticket_TRACK_CHANGED`, `ticket_ETA_CHANGED`, `ticket_EXPIRED`, `ticket_ARRIVED`). Subscribe to a user and its
   active ticket on `platform_USER_ADDED`; drop the old ticket on `user_ACTIVE_TICKET_RESIGNING`; unsubscribe on
   `user_TICKET_REMOVED` and `platform_USER_REMOVED`. No events fire for expired or sibling tickets.
5. Read `user.getNickname()`, `user.getAvatar()` (an image: call `load()`, wait for `image_CHANGED`), `user.getLocation()`,
   `ticket.getTrack()`, `getEta()`, `getDestination()`, `getExpireTime()`, `getState()`.
6. A request invite never auto-replies: `platform_INVITE_REQUEST` carries a `GlyUserTicket`; ask the user first. Stop
   watching with `user.stopWatching()`.

**Profile**: read `getUserManager().getSelf()`; call `setNickname(_:)` / `setAvatar(_:)` only after `SYNCED`, after checking
the current value (they are persisted, so set them once). Updating them needs network access.

**Push**: after the APNs callback convert the token `Data` to a lowercase hex string and call
`g.registerDeviceToken(with: hex)` (the default token type is `apple_background`). This call is ignored until the
platform has started, so keep the token yourself and register it right after `start()`, and again whenever APNs gives
you a new one. In `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` pass
`userInfo["payload"] as? String` to `g.handleRemoteNotification(with:)`, then call the completion handler. It is also
ignored until the platform has started: if the app is launched in the background by a push, create and start the
platform first. Glympse must hold your app's APNs credentials: contact your Glympse representative.

## 6. Pitfalls

- Fresh install, nothing happens: you have neither consent nor exemption, or the server or API key is empty.
- Adding the listener after `start()` misses `platform_STARTED` and `platform_FIRST_LAUNCH`.
- `ticket_CREATED` does not mean the invite is ready. Wait for `ticket_INVITE_CREATED` or `ticket_INVITE_SENT`.
- Viewing a ticket with the default mode does not give live updates (see "View a Glympse", steps 2 and 3).
- `platform_SYNCED_WITH_SERVER` fires once per instance; `platform_TICKET_SYNC_COMPLETED` fires on every later sync.
- The server can reject requests as rate limited. The SDK then fires `platform_RATE_LIMITED` and does not retry those
  requests. Treat it as a signal to back off. The limits are server-side; the SDK's own data-rate
  optimizations are separate and send no such event.
- Do not default the nickname or avatar before `SYNCED`; you may overwrite the user's saved values.
- Swift overload quirk: `ticket.add(_:)` takes an invite or an event listener, so keep the argument types explicit.

## 7. Testing against Sandbox

- Create the platform with server `sandbox.glympse.com` and a Sandbox API key (ask Glympse). Production is `api.glympse.com`.
- Every install gets its own anonymous account. For a clean account, stop the platform, call `logout()`, then create
  a new instance (or reinstall the app).
- Event order on a normal relaunch: `STARTED`, `LOGIN_SUCCEEDED`, `SYNCED`. On the first run: `STARTED` and `FIRST_LAUNCH` (same callback),
  `ACCOUNT_CREATED`, `LOGIN_SUCCEEDED`, `SYNCED`.
