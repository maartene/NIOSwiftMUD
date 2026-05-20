# Architecture Improvement Backlog

Based on solution architect review (2026-05-20) after ports/adapters refactor.

---

## Blocking

### 1. `SessionStorage` global cuts across the hexagon boundary

**Problem:** `World` and commands (`WhisperCommand`, `SayCommand`) call `SessionStorage` directly, which holds NIO `Channel` objects. The domain model is coupled to networking infrastructure. Tests require manual `defer { SessionStorage.deleteSession(...) }` cleanup.

**Fix:**
- Define a `SessionRepository` protocol (secondary port) with `find(playerID:)`, `store(_:)`, `delete(_:)`, `all()`
- Implement `InMemorySessionRepository` (no NIO imports) for tests
- `SessionStorage` becomes a NIO-coupled adapter implementing the protocol (stays in Server layer)
- Inject `SessionRepository` into `World` alongside existing repositories
- Remove all direct `SessionStorage` calls from `World` and commands

- [ ] Define `SessionRepository` protocol
- [ ] Implement `InMemorySessionRepository`
- [ ] Make `SessionStorage` conform to `SessionRepository`
- [ ] Inject into `World`
- [ ] Remove direct `SessionStorage` calls from `World` and commands
- [ ] Remove `defer`-based session cleanup from tests

---

### 2. `World` is a concrete struct, not a protocol

**Problem:** Every command receives the full concrete `World` struct. Adding any cross-cutting concern (session repo, event bus, logger) requires modifying `World` and recompiling every command.

**Fix:** Introduce a `CommandContext` protocol that `World` satisfies. Change `MudCommand.execute(in:)` to accept `any CommandContext`. Tests can inject focused doubles per command without building a full `World`.

- [ ] Define `CommandContext` protocol
- [ ] Make `World` conform to `CommandContext`
- [ ] Update `MudCommand.execute(in:)` signature
- [ ] Update all command implementations

---

### 3. `InMemoryRepository` is not thread-safe

**Problem:** `InMemoryRepository.storage` is an unprotected mutable array. `ParseHandler.channelRead` dispatches commands via `completeWithTask`, which runs on the Swift concurrency runtime — concurrent connections produce concurrent writes to the same repository instances.

**Fix:** Mark `InMemoryRepository` as `actor`. Most call sites are already `async`, so the actor hop is transparent.

- [ ] Convert `InMemoryRepository` to `actor`
- [ ] Update call sites (find any that become `await`)

---

## Security

### 4. `Hasher.verify` has a misleading contract

**Problem:** `Hasher.verify(password:hashedPassword:)` only hashes the raw password, but users are stored with `hash(password + username.uppercased())`. `LoginCommand` compensates by applying the salt at the call site — any future caller using `verify` with a raw password gets silent auth failure.

**Fix:** `Hasher.verify(password: String, username: String, hashedPassword: String) -> Bool` — apply the salt internally.

- [ ] Update `Hasher.verify` signature to include `username`
- [ ] Move salt construction inside `Hasher.verify`
- [ ] Update `LoginCommand` call site

---

## Non-blocking improvements

### 5. `HelpCommand.HELP_STRING` will drift from `MudCommandFactory.allCommands`

Already missing WHISPER. If a command is added to `allCommands` but not `HELP_STRING`, it is undiscoverable.

**Fix:** Add `static var helpText: String?` to `MudCommand`. `HelpCommand` assembles output by iterating `MudCommandFactory().allCommands` and collecting non-nil entries. Help text stays co-located with each command.

- [ ] Add `static var helpText: String?` to `MudCommand` protocol
- [ ] Migrate descriptions from `HelpCommand.HELP_STRING` into each command file
- [ ] Update `HelpCommand.execute` to assemble from commands
- [ ] Add test: all commands with non-nil `helpText` appear in help output

---

### 6. `Repository` protocol is missing `delete`

Needed before persistence is reintroduced. `SessionStorage` already has `deleteSession` — the protocol should have parity.

- [ ] Add `func delete(_ id: T.ID) async` to `Repository`
- [ ] Implement in `InMemoryRepository`

---

### 7. Typos in player-visible strings

- `GoCommand.swift:27` — `"Cound not find room"` → `"Could not find room"`
- `GoCommand.swift:35` — `"Cound not find target room"` → `"Could not find target room"`
- `OpenDoorCommand.swift:35` — `"Cound not find room"` → `"Could not find room"`
- `SessionStorage.swift:36` — `"Succesfully"` → `"Successfully"`

- [ ] Fix typos

---

### 8. Stale comment in `PipelineTests.swift:56`

Comment references `AwesomeDB` actor hops, but `AwesomeDB` is gone. The sleep is still needed due to `ParseHandler.completeWithTask` — update the comment to explain the actual reason.

- [ ] Update comment to reference `InMemoryRepository` + `ParseHandler`'s `completeWithTask`

---

### 9. `NIOMultiClientTestEnvironment` is unused

Defined in `NIOPipelineTestHarness.swift` but no test uses it. Either add a test that exercises it, or remove it.

- [ ] Decide: add multi-client test or delete `NIOMultiClientTestEnvironment`

---

## Known / deferred

- Hardcoded SSH key — fix when persistence is re-implemented
- Swift 6 strict concurrency warnings — related to item 3 above; will improve together
