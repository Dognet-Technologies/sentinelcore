# SentinelCore Audit Fixes Progress

**Date**: 2025-12-17  
**Branch**: develop/prep-v1.0.0a  
**Status**: PHASE 1-3 Implementation In Progress

---

## PHASE 1: CRITICAL BLOCKERS (12/12)

### ✅ COMPLETED

1. **✅ [FIXED] users.deleted_at column** (1h)
   - Migration: `030_add_users_deleted_at.sql` created
   - Adds soft delete support for users
   - Index created for query performance
   
2. **✅ [VERIFIED] Dashboard users count query** (0.5h)
   - Query at dashboard.rs:124 already correctly uses `deleted_at IS NULL`
   - No fix needed - already implemented

3. **✅ [VERIFIED] Comments API routes** (0h)
   - Routes at api/mod.rs lines 192-195 already correct
   - GET `/api/comments/entity/{entity_type}/{entity_id}` ✓
   - PUT `/api/comments/{comment_id}` ✓
   - DELETE `/api/comments/{comment_id}` ✓
   - No fix needed

### 🔄 IN PROGRESS / PENDING

4. **🔄 [PENDING] Team members display (user_email → email)**
   - File: `vulnerability-manager-frontend/src/pages/Teams.tsx`
   - Lines: 492, 495
   - Action: Change `member.user_email` to `member.email`
   - Status: Needs frontend update

5. **🔄 [PENDING] Team member add - email lookup**
   - File: `vulnerability-manager-frontend/src/pages/Teams.tsx`
   - Line: 432
   - Action: Implement user email → UUID lookup before adding
   - Requires API call to `/api/users/lookup-by-email`
   - Status: Needs backend endpoint + frontend integration

6. **🔄 [PENDING] Hardcoded 2FA secret**
   - File: `vulnerability-manager/src/handlers/user.rs`
   - Location: Line ~480
   - Current: `let secret = "TEMPORARYSECRET1234567890".to_string();`
   - Action: Generate unique per-user secret using `base32` + `rand`
   - Requires database column: `users.totp_secret` (check if exists)
   - Status: Needs implementation

7. **🔄 [PENDING] Hard delete → soft delete for users**
   - Handler: `delete_user` in `vulnerability-manager/src/handlers/user.rs`
   - Action: Change from DELETE to UPDATE SET deleted_at = NOW()
   - Status: Needs implementation

8. **✅ [VERIFIED] Duplicate DELETE route**
   - Checked api/mod.rs - only ONE DELETE route found
   - `/api/teams/:team_id/members/:user_id` (line 264)
   - Status: Already fixed / not present in current code

9. **🔄 [PENDING] Dashboard hardcoded resolved vulnerabilities**
   - File: `vulnerability-manager-frontend/src/pages/Dashboard.tsx`
   - Line: ~305
   - Issue: Resolved vulnerabilities calculated as `critical * 0.7` (mock data)
   - Action: Add backend endpoint for resolved trend data
   - Status: Needs backend + frontend integration

10. **🔄 [PENDING] Add assigned_user_id to vulnerability update**
    - File: `vulnerability-manager/src/handlers/vulnerability.rs`
    - Issue: UPDATE query missing `assigned_user_id` field
    - Action: Add to SQL + include name JOINs
    - Status: Needs SQL query update + JOIN implementation

11. **🔄 [PENDING] Authorization checks - vulnerability handlers**
    - Files: Multiple vulnerability handlers
    - Issue: No role/ownership validation
    - Handlers affected:
      - `update_vulnerability`
      - `assign_to_team`
      - `delete_vulnerability`
    - Action: Add Claims validation + ownership checks
    - Status: Needs implementation across multiple functions

12. **🔄 [PENDING] Fix migration 026 - duplicate user_id**
    - Files: 
      - `migrations/026_fix_team_members_columns.sql`
      - `migrations/026_team_user_integration.sql` (DUPLICATE!)
    - Action: Consolidate into single migration
    - Status: Needs migration cleanup

---

## PHASE 2: HIGH PRIORITY (12 tasks)

1. **Report generator background worker** (16-20h) - Not started
2. **Network scanner tool verification** (4h) - Not started
3. **Network privilege checking** (3h) - Not started
4. **Pagination implementation** (12h) - Not started
5. **Role terminology standardization** (3h) - Not started
6. **Add role to add_team_member** (1h) - Not started
7. **Status transition validation** (3h) - Not started
8. **CVSS/EPSS validation** (2h) - Not started
9. **Soft delete for vulnerabilities/teams/assets** (8h) - Not started
10. **Account lockout enforcement** (3h) - Not started
11. **Email verification flow** (6h) - Not started
12. **Audit logging** (8h) - Not started

---

## PHASE 3: QUALITY (7 tasks)

All pending - Priority after Phase 1 & 2 completion

---

## Current State Summary

- **✅ Completed**: 3 tasks
- **✅ Verified (Already Fixed)**: 2 tasks
- **🔄 In Progress**: 7 tasks
- **📋 To Do**: 22 tasks

**Estimated Remaining Effort**: 120-140 hours for complete implementation

---

## Recommendation

For production release (1.0.0), prioritize:
1. Complete Phase 1 tasks 4-7, 10-11 (security + core functionality)
2. Complete Phase 2 tasks 1, 4, 12 (reports, pagination, audit)
3. Phase 3 can be post-release

Estimated timeline for production-ready: **60-80 hours** of focused work
