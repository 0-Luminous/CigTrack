# Core Data SettingsStore Migration (Sketch)

1. **Model shape**
   - Create an entity `NicotineSettings` with a single record (use a known UUID or a singleton fetch request).
   - Attributes:
     - `profileData` (`Binary Data`, Allows external storage) to persist the encoded `NicotineProfile`.
     - `currencyCode` (`String`, 3 chars) to mirror the preferred currency picker.
     - `updatedAt` (`Date`) to help with debugging migrations.
   - Keep a lightweight fetch request (`fetchLimit = 1`) so the store behaves like a key-value record.

2. **Core Data store**
   - Implement `final actor CoreDataSettingsStore: SettingsStore`.
   - Inject an `NSManagedObjectContext` (background context recommended) and reuse the existing JSON encoder/decoder from the in-memory store.
   - On `loadProfile()`, fetch or create `NicotineSettings`, decode `profileData`, and fall back to defaults if decoding fails.
   - On `save(profile:)`, encode to `Data`, update `profileData`, `currencyCode`, `updatedAt`, and call `context.saveIfNeeded()`.
   - Publish changes via `@MainActor` bridge (e.g., `PassthroughSubject`) if you need real-time UI updates.

3. **Migration steps**
   1. Ship the new Core Data entity in `PuffQuest.xcdatamodeld`.
   2. Add the `CoreDataSettingsStore` implementation next to `InMemorySettingsStore`.
   3. Inject the desired store through dependency inversion (e.g., `OnboardingViewModel(settingsStore: store)`), so previews/tests can still supply the in-memory version.
   4. When enabling Core Data for users, load any existing data from `InMemorySettingsStore` once, persist it to Core Data, and then delete the `UserDefaults` keys (`onboarding.nicotine.profile`, `onboarding.preferred.currency`).
   5. After verifying telemetry/crash-free sessions, remove the temporary migration bridge.

This approach keeps the view model/API unchanged while letting you swap persistence layers by changing the injected `SettingsStore`.
