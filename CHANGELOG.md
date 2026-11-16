# Changelog

## 0.5.0

- New sealed `WhatChanged`: a `UserSaid` edited, deleted, or restored at its
  source, in message terms — a module's reading of that before anything maps
  the message to a `TurnId`. Cases `Edited(text, quotes)`, `Deleted()`,
  `Restored()`.
- New `UserSaidChanged`: the node the journey path's apex appends for a
  `WhatChanged`, targeting the `TurnId` of the `UserSaid` it changes. Not a
  `Withdrawal<UserSaid>`: a restore has to target the original turn, and a
  fresh `UserSaid` would mint a new one. `by` counts only when it is who
  wrote the target, the same rule `Withdrawal` and `AgentName`'s rename
  keep.

## 0.4.0

- `Quote` gains an optional `preview: String?`: a shortened copy of the
  quoted text, if the source showed one. Matters most when `source` never
  reached the journey path, leaving this the only trace of what was quoted.

## 0.3.0

- **Breaking:** `QuotedAuthor`'s two cases are renamed `Known` → `KnownAuthor`
  and `Unknown` → `UnknownAuthor` (teams-module-e2's call, while nothing yet
  depended on the names): `Known(actor)` read in isolation without saying
  what was known, and these are shape types meant to be read across modules.

## 0.2.0

- `UserSaid` gains an optional `quotes: Quote?`: the message it answers or
  replies to, as its source names it. `text` may be empty when `quotes` is
  set — a reply that is only a quote and an @-mention has nothing of its
  own to say.
- New `Quote`, carrying the quoted message's `source: SourceMessageId` and
  its `author: QuotedAuthor`.
- New sealed `QuotedAuthor`, `Known(ActorId)` or `Unknown(String?
  displayName)`: a quote's author isn't always resolvable, so a reader
  handles both cases, and a bare display name never passes for an identity.

## 0.1.2

- Widened `is_shapes` to `^0.4.0`, which renames `Withdraw` to `Withdrawal`
  — a rename this package never touches — so modules can take that rename
  without `is_conversation_shapes` blocking the solve.

## 0.1.1

- Dropped every link to a private issue tracker from docs and comments;
  the prose they supported stays, minus the citation.

## 0.1.0

- First release as `is_conversation_shapes`: named for which modules need a
  shape, not for who writes it — `UserSaid` is person-authored, and belongs
  here on that test regardless.
- `AgentName`: what an agent calls itself. Its identity is the agent's
  `agent:<id>`, which names the agent in every node it writes, and its value
  is the name, which can change while the id never does.
- `UserSaid`: what a person said, as a module received it from its source —
  carries who said it, the message's id in its source's own terms, and the
  text. Ends echo-matching: a reply answers it by the `TurnId` the journey
  path delivers back, never by comparing text.
- `ReplyText`: the agent's reply to one `UserSaid`, written once, when the
  message it answers is finished.
- `SourceMessageId`: the typed id `UserSaid.source` carries, so a message id
  never drifts into a bare `String`.
