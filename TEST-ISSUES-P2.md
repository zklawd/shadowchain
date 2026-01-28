# ShadowChain Test Issues — Player 2 (0x8c87...09E9)

**Test Date:** 2026-01-28
**Game:** Arena #2 (https://shadowchain.netlify.app/game/2)
**Player 1:** 0x1387...f7f8 (Dev Wallet 1)
**Player 2:** 0x8c87...09E9 (Dev Wallet 2)
**Environment:** Netlify production (shadowchain.netlify.app), Sepolia testnet

---

## Issue 1: Dev Wallet Disconnects Across Tabs (Shared Browser State)
- **Severity:** critical
- **Flow:** Multiplayer testing / Dev wallet
- **Description:** When two dev wallets are connected in different tabs of the same browser, disconnecting one wallet (via wagmi's disconnect) also disconnects the other. The wagmi connector state is shared via localStorage, so when Player 1's tab triggers a disconnect or reconnect event, Player 2's tab loses its wallet connection. This happened repeatedly — every 15-30 seconds the wallet would revert to "Connect Wallet" state.
- **Expected:** Each tab should maintain its own independent wallet session. At minimum, the dev wallet connector should use tab-specific storage (sessionStorage or in-memory only) rather than shared localStorage.
- **Impact:** Makes same-browser multiplayer testing impossible. The "Start Game" button appeared but couldn't be clicked reliably because the wallet would disconnect between snapshot and click.

## Issue 2: Game Does Not Auto-Start When maxPlayers Reached
- **Severity:** major
- **Flow:** Game start
- **Description:** The lobby showed the game was created for 4 players (0/4), but the game page showed Players (2/2). Despite both players joining, the game state remained "WAITING" and a manual "Start Game" button was displayed. The game did not auto-start when the player count reached the configured maximum.
- **Expected:** When maxPlayers is reached, the game should automatically transition to "LIVE" state. If manual start is intentional, this should be clearly documented and only available to the game creator.

## Issue 3: Inconsistent Player Count Between Lobby and Game Page
- **Severity:** major
- **Flow:** Lobby display / Game state
- **Description:** The lobby displayed "0/4 players" for Arena #2, while the game page showed "Players (2/2)" and "2/2 players joined". The maxPlayers value was inconsistent between the two views (4 in lobby vs 2 in game page sidebar). This suggests either a data sync issue or the maxPlayers value is being read differently.
- **Expected:** Lobby and game page should show consistent player counts and maxPlayers values. The contract's maxPlayers should be the single source of truth.

## Issue 4: Wallet State Lost on Page Navigation (Lobby → Game)
- **Severity:** major
- **Flow:** Navigation / Dev wallet
- **Description:** After connecting the dev wallet on the lobby page (/lobby), clicking "Join Game" navigated to /game/2. The wallet connection was lost during this navigation — the game page showed "Connect Wallet" instead of the connected address. Had to reconnect the dev wallet on every page.
- **Expected:** Dev wallet state should persist across client-side navigation. Since this is a Next.js app with client-side routing, React state should be preserved. If full page reload is required, dev wallet state should be persisted in sessionStorage.

## Issue 5: Dev Wallet Input Requires JavaScript Workaround
- **Severity:** minor
- **Flow:** Dev wallet connection
- **Description:** The dev wallet input field (textbox with placeholder "0x...") could not be filled using standard Playwright fill/type actions — they timed out. Required a JavaScript workaround using `nativeInputValueSetter` + `dispatchEvent` to fill the input. This suggests the input has custom event handling that blocks standard browser automation.
- **Expected:** Standard HTML input behavior should work. The input should accept programmatic value changes via standard fill/type methods.

## Issue 6: Header Shows "WAITING" After Players Joined
- **Severity:** minor
- **Flow:** Game status display
- **Description:** The header badge continued showing "WAITING" even after both players joined and the "Start Game" button appeared. The game state in the sidebar also showed "waiting" throughout. Even after clicking "Start Game", no state transition occurred.
- **Expected:** After clicking "Start Game", the header should transition to "LIVE" and the game state should update accordingly.

## Issue 7: Players Panel Shows (0/0) Initially Then (1/1) Before Second Player
- **Severity:** minor
- **Flow:** Game page initial load
- **Description:** When first loading the game page, the Players panel showed "Players (0/0)" even though Player 1 had already joined. After the page detected the wallet, it updated to "Players (1/1)". The maxPlayers denominator changed from 0 → 1 → 2 as players were detected, rather than showing the actual maxPlayers from the contract.
- **Expected:** The maxPlayers value should always reflect the contract's configured maxPlayers (4 according to lobby, or whatever the actual value is), not dynamically change based on player count.

## Issue 8: ZK Prover Shows "Loading…" After Wallet Reconnect
- **Severity:** minor
- **Flow:** ZK proof system
- **Description:** After wallet disconnection and reconnection, the ZK Prover status showed "Loading…" instead of "Ready ✓". The WASM modules needed to be reinitialized. This adds significant delay if the wallet frequently disconnects.
- **Expected:** WASM module initialization should be independent of wallet state. The ZK prover should remain "Ready" regardless of wallet connection status.

## Issue 9: Combat Log Shows "You" for Other Player's Actions
- **Severity:** cosmetic
- **Flow:** Combat log
- **Description:** When viewing the game without a connected wallet (after disconnect), the combat log showed two entries both saying "You joined the arena at a hidden position" — one for Player 1 and one for Player 2. Without wallet context, both show as "You."
- **Expected:** Without a connected wallet, the combat log should show generic messages like "A player joined" or display the address, not "You."

## Issue 10: Base Account SDK COOP Warning
- **Severity:** cosmetic
- **Flow:** Page load
- **Description:** Console shows: "Base Account SDK requires the Cross-Origin-Opener-Policy header to not be set to 'same-origin'." This appears on every page load.
- **Expected:** Either configure the correct COOP header or suppress the warning if Base smart wallets are not actively used.

---

## Summary of Test Flow

### What Worked ✅
- Dev wallet connection via 🔧 button (after JS workaround for input)
- Lobby correctly displays games with status, fee, grid size, creator
- Game page shows 16×16 grid with fog-of-war, walls, and player position
- ZK proof generation (position_commit circuit) — ~5 seconds per proof
- Join transaction submitted and confirmed on Sepolia
- Both players visible in Players panel (2/2) with stats (HP, ATK, DEF, Score)
- Fog-of-war correctly hides distant cells
- Combat log records join events with ZK verification status

### What Didn't Work ❌
- Game never transitioned from WAITING → LIVE (couldn't play moves)
- Start Game button appeared but clicking it had no visible effect
- Wallet kept disconnecting due to shared browser (critical blocker)
- Could not test: movement, ZK move proofs, combat, artifacts, forfeiting

### Root Cause
The primary blocker was **shared browser state**. Both Player 1 and Player 2 used the same Chromium instance (profile="clawd"), so wagmi's localStorage-based connector state was shared. Any wallet change in one tab affected the other. The sandbox browser was unavailable, making true isolated testing impossible.

### Recommendation
1. **Immediate**: Make dev wallet use sessionStorage or pure in-memory state (no localStorage) so tabs are independent
2. **Short-term**: Add auto-start when maxPlayers reached (or make it configurable)
3. **Medium-term**: Fix maxPlayers inconsistency between lobby and game page
