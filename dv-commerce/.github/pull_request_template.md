# JIRA Ticket

https://pizzahut.atlassian.net/browse/

# Description

This is what changes in this PR...

# Media

![](https://placehold.co/600x400)

# PCI Compliance - Change Management (Requirement 6.5.1)

## Change Documentation
- [ ] Reason for change documented in JIRA ticket and PR description
- [ ] Detailed description of which system components are affected
- [ ] Security impact assessment completed (see below)

## Security Impact Assessment
- [ ] Documented whether this change adds, removes, or modifies system components in production
- [ ] Confirmed existing security controls remain in place OR are replaced with equal/stronger controls
- [ ] No adverse impact to system security expected

**Security Impact Summary:**
<!-- Describe the security impact of this change. If none, state "No security impact - this change does not affect security controls or system components handling sensitive data" -->

## Testing & Verification
- [ ] Testing performed to verify the change does not adversely impact system security
- [ ] For custom software changes: Compliance with Requirement 6.2.4 verified (if applicable)

## Rollback Plan
- [ ] Documented procedures to address failures and return to secure state
- [ ] Rollback tested or plan verified

**Rollback Procedure:**
<!-- Describe how to rollback this change if it fails or adversely affects security -->

# Checks

- [ ] If this is a significant changed to a shared resource (changing a commonly used API, base functionality that multiple domains will leverage) or a change that impacts everyone (adding a new lib, reorganizing code, etc). Please get at least one approval from a member of each domain team before merging. Request approvals from the [@pizzahutuk/dv-commerce](https://github.com/orgs/pizzahutuk/teams/dv-commerce) group.
- [ ] If shared functionality is touched make sure check Mobile checks. Make sure that the specific functionality touched on web doesn't break the mobile one. If it does -> there should be a followup mobile task created for that and mobile team should be notified

## Memory & Learning

- [ ] Checked relevant CLAUDE_MEMORY.md files for patterns that apply to these code changes
- [ ] No anti-patterns from memories present (or explained why they don't apply)
- [ ] If this change revealed a gotcha/edge case/important learning:
  - [ ] Added to appropriate CLAUDE_MEMORY.md file
  - [ ] Used #memory tag in commit message if significant

<!-- If adding a memory, preview it here:
### 🏷️ [Title]
- **PR**: #[this PR number]
- **What happened**: [the situation]
- **The revelation**: [what we learned]
- **The learning**: [wisdom to remember]
-->

## Mobile checks

- [ ] Ticket link attached
- [ ] Documentation is written if it's a technically new feature and was not implemented previously. Leave the campground cleaner than you found it. Review any related documentation and make sure it's added or updated if was previously added.
- [ ] Video is attached to the ticket and PR in order to recheck the functionality and simplify the QA process
- [ ] Additional details for QA are added to the ticket. For example a way to test the feature if it requires some special setup
- [ ] Application runs in dev mode
  - [ ] Checked on IOS simulator
  - [ ] Checked on Android simulator
- [ ] The feature doesn't compromise the animations and responsiveness guidelines - https://pizzahutinternational.atlassian.net/wiki/spaces/MM1/pages/3598057526/UI+UX+by+developers. If you are not sure contact mobile team lead or designer
  - [ ] If compromises (the animations are better to be added) -> create a ticket for that after consultancy.
- [ ] If any shared or web code is touched
  - [ ] Make sure that specific functionality which was touched works fine for web as well
  - [ ] Web feature preview links in the PR load correctly for all markets and environments
- [ ] Performance is not affected. The app does not show any significant performance degradation, keeping it smooth and responsive
  - [ ] The application can be run on real device without significant issues and is responsible most of the time. Ideally on Android and IOS (depending on the devices you have)
  - [ ] Desired FPS on the IOS emulator doesn't drop lower than 40 fps for more than 1 second. This might be irrelevant when the computer the emulator runs in is under high load. In this case, it might be skipped

## Additional checks if updates to the packages or any other significant updates

- [ ] Application runs in dev and prod mode - https://docs.expo.dev/workflow/development-mode/#production-mode
