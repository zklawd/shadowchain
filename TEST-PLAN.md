# ShadowChain E2E Test Plan

## App URL
https://zklawd.github.io/shadowchain/
(Netlify paused due to usage limits — using GitHub Pages)

**Last Validated:** 2026-01-28

## Dev Wallets
- **Player 1 (P1):** `0xe50e4f3d55f41ce8c245f8b226da9cc76528e7559df40981b50c9a33ab052e32`
  - Address: `0x1387895435ac9777dA595e41650b7EFd6559f7f8`
- **Player 2 (P2):** `0x5f811339ae2b46129c59ccbacb109e0c5539022e33eda5365f2492116a6680bb`
  - Address: `0x8c871b46d08632e3775B6CCfAdB8Dd4E080409E9`

## Test Flows

### Flow 1: Landing Page ✅
- [x] Page loads at /
- [x] Shows on-chain stats (1 active game, 2 players, 0.012 ETH pot, 4 proofs)
- [x] Navigation links work (Enter Arena → /lobby)

### Flow 2: Lobby Page ✅
- [x] /lobby loads, shows game list from chain (5 games)
- [x] Filter tabs work (All 5, Waiting 2, Active 1, Ended 2)
- [x] Create Arena button visible
- [x] Game #0 filtered out (phantom game fix working)

### Flow 3: Dev Wallet Connect ⚠️ PARTIAL
- [x] 🔧 button visible next to "Connect Wallet"
- [x] Clicking opens popover with key input
- [x] Pasting valid key shows address preview (0x1387…f7f8)
- [ ] Pasting invalid key shows error (not tested)
- [x] Submit connects wallet, shows ⚠️ DEV badge
- [x] Address displays correctly in header
- **BUG:** ❌ Wallet disconnects on page navigation (known issue)

### Flow 4: Create Game (P1) ✅ (previously tested)
- [x] Click "Create Arena" in lobby
- [x] Modal opens with fee + max players settings
- [x] Set entry fee + max players
- [x] Click Deploy Arena
- [x] Transaction submits and confirms (~15s)
- [x] Game appears in lobby as "WAITING"
- **Note:** maxPlayers default was 4 not 2 (UI issue documented in TEST-ISSUES.md)

### Flow 5: Join Game (P1) ✅ (previously tested)
- [x] Navigate to /game/<id>
- [x] Game page loads, shows "Waiting" phase
- [x] Click "Join Game" button
- [x] ZK position_commit proof generates (~5s)
- [x] Transaction submits with commitment
- [x] UI shows "You've joined this game"
- [x] Map grid appears with player position

### Flow 6: Join Game (P2) → Start ⚠️ PARTIAL
- [x] P2 connects different dev wallet
- [x] P2 navigates to same game page
- [x] P2 clicks "Join Game"
- [x] ZK proof generates
- [x] Transaction submits
- [ ] ❌ Game does NOT auto-start when maxPlayers reached
- [x] Manual "Start Game" button appears, works when clicked
- **Note:** Same-browser testing has issues due to shared localStorage

### Flow 7: Submit Move (P1) ✅
- [x] Movement controls visible (↑←●→↓ + WASD/Arrow keys)
- [x] Click direction button
- [x] ZK valid_move proof generates (~5-6s)
- [x] Transaction submits with new commitment + proof
- [x] Player position updates on grid (tested: 8,12 → 8,11)
- [x] Move event appears in Combat Log ("moved N — ZK proof 16256 bytes")

### Flow 8: Advance Turn ✅ (previously tested)
- [x] "Advance Turn ▶" button visible
- [x] Click advances to next turn
- [x] Turn counter increments

### Flow 9: Claim Artifact ⏳ NOT TESTED
- [ ] Move player to a treasure cell
- [ ] "✦ Claim Artifact" button appears
- [ ] Click generates ZK claim_artifact proof
- [ ] Transaction claims the artifact
- [ ] Player stats update
- **Note:** Requires positioning at treasure cell (amber/gold)

### Flow 10: Forfeit ⚠️ PARTIAL (previously tested)
- [x] Click "Forfeit" button
- [x] Transaction submits
- [x] Player status changes to Forfeited
- [x] If only 1 player remains, game resolves
- [x] Winner receives prize pool
- **BUG:** ❌ No confirmation dialog before forfeit (known issue)

### Flow 11: Game Resolution ✅ (previously tested)
- [x] Game resolves after forfeit
- [x] Winner displayed
- [x] Prize pool paid out
- [x] Game shows "ENDED" status in lobby

## Test Summary

| Flow | Status | Notes |
|------|--------|-------|
| 1. Landing Page | ✅ Pass | Stats, nav all working |
| 2. Lobby Page | ✅ Pass | Filters, game list, Game #0 filtered |
| 3. Dev Wallet Connect | ⚠️ Partial | Works but disconnects on navigation |
| 4. Create Game | ✅ Pass | maxPlayers default unclear in UI |
| 5. Join Game (P1) | ✅ Pass | ZK proof + tx working |
| 6. Join Game (P2) | ⚠️ Partial | No auto-start when full |
| 7. Submit Move | ✅ Pass | ZK proof, position update working |
| 8. Advance Turn | ✅ Pass | Turn increments correctly |
| 9. Claim Artifact | ⏳ Untested | Needs treasure cell positioning |
| 10. Forfeit | ⚠️ Partial | Works but no confirmation dialog |
| 11. Game Resolution | ✅ Pass | Winner + payout working |

**Overall:** 7/11 fully passing, 3 partial, 1 untested

## Known Issues (Blocking/Major)

1. **Wallet disconnects on navigation** — Dev wallet state lost when moving between pages. Requires reconnecting on each page.

2. **Game doesn't auto-start** — When maxPlayers reached, game stays in WAITING state. Manual "Start Game" button required.

3. **No forfeit confirmation** — Clicking "Forfeit" immediately submits the transaction without warning.

## Known Issues (Minor/Cosmetic)

4. **maxPlayers default unclear** — UI doesn't visually indicate default selection in Create Arena modal.

5. **Entry fee missing "ETH" suffix** — Game page shows "Entry fee: 0" instead of "0 ETH".

6. **Adjacent cells clickable in WAITING** — Cells show pointer cursor before game starts.

7. **Console warnings** — Deprecated WASM init parameters, COOP header warning.

## Full Issue Details

See `TEST-ISSUES.md` and `TEST-ISSUES-P2.md` for complete issue documentation with reproduction steps and severity ratings.
