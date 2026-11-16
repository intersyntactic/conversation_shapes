# is_conversation_shapes

Shapes for a journey path's conversation, needed by whichever modules
carry one, not only the agent: what an agent calls itself, what a person
said, and the agent's reply to it.

```dart
import 'dart:typed_data';

import 'package:is_conversation_shapes/is_conversation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';

// The id the install minted on first boot and keeps.
final id = ActorId.parse('agent:7f3a9c21')!;

// The first node the agent writes says what it is called.
final named = AgentName(agent: id, name: 'Wren');

// A rename: a later pass of the same node, written by the same agent.
final renamed = AgentName(agent: id, name: 'Kestrel');

// A person's message, as a module received it from its source.
final peter = ActorId.parse('teams:f6a2.../b901...')!;
final said = UserSaid(
  author: peter,
  source: SourceMessageId.parse('1234567890.123456')!,
  text: 'how is the demo coming?',
);

// A reply that only quotes another message and @-mentions the agent: no
// text of its own, but it names what it's about.
final onlyAQuote = UserSaid(
  author: peter,
  source: SourceMessageId.parse('1234567890.654321')!,
  text: '',
  quotes: Quote(
    source: SourceMessageId.parse('1234567890.123456')!,
    author: KnownAuthor(id),
  ),
);

// The journey path delivers back a TurnId for `said` once it's appended;
// the agent's reply answers it by that id, never by matching text.
final saidId = TurnId.of(Uint8List(0)); // stood in here; nothing is stored
final reply = ReplyText(by: id, answers: saidId, text: 'nearly there');
```

## What is here

- `AgentName`: what an agent calls itself. Its `agent` is marked `@identity`,
  so the node is about the agent, and its `name` is its value. A rename is a
  later pass of the same node, at the same anchor, and a reader takes the
  latest. It holds no time, because the journey path's order already says
  which pass is latest.
- `UserSaid`: what a person said, as a module received it from its source —
  who said it, the message's id in its source's own terms, the text, and
  optionally the `Quote` it answers or replies to. Written once and never
  revised, so every field is identity. `text` may be empty when `quotes` is
  set, since a reply that is only a quote and an @-mention has nothing of
  its own to say. It carries a strict JSON codec — `toJson()` and
  `UserSaid.fromJson`, in `agent_loop`'s node map form — so a module can
  hand one on already built and typed, and nothing downstream parses a
  stranger's bytes.
- `SourceMessageId`: the typed id `UserSaid.source` carries, opaque here like
  `ActorId`'s tail, since this package doesn't know Teams or Slack and can't
  say what either one's ids look like.
- `Quote`: a message a `UserSaid` quotes, as its source carries it — the
  quoted message's `source: SourceMessageId` and its `author: QuotedAuthor`.
  A quote never reaches across sources, so the quoted message is always
  within the same conversation.
- `QuotedAuthor`: sealed, `KnownAuthor(ActorId)` or `UnknownAuthor(String?
  displayName)`.
  A quote's author isn't always resolvable — someone in a group chat who
  never wrote to the agent, say — under every way a module might try, so a
  reader handles both cases. A display name is whatever the source showed
  alongside the quote; it is never read as an identity.
- `WhatChanged`: sealed, what an earlier `UserSaid` became at its source —
  `Edited(text, quotes)`, `Deleted()`, or `Restored()`. A module's reading
  of the change in message terms, before anything maps the message to a
  `TurnId`. Carries the same kind of strict JSON codec as `UserSaid`, in
  the same map form.
- `UserSaidChanged`: the node the journey path's apex appends for a
  `WhatChanged`, once it knows which `TurnId` the changed message became —
  `by` who changed it, `target` the `TurnId`, and `change` the
  `WhatChanged`. Not a `Withdrawal<UserSaid>`: a restore has to target the
  original turn, and a fresh `UserSaid` would mint a new one, orphaning
  anything already pointing at it.
- `ReplyChunk`: one piece of a reply as the agent streams it — a delta, not
  the reply so far. Written to the agent loop's own chain, not the journey
  path: a chunk isn't a turn, so it carries no `TurnId` and no index; the
  chain's own hash-chaining gives every chunk its order.
- `ReplyText`: the agent's reply to one `UserSaid`, written once, when the
  message it answers is finished. It `answers` by the `TurnId` the journey
  path delivered back for that `UserSaid`, which is what makes two replies
  two different nodes — no turn number or index needed alongside it.

## The rule a reader keeps

**A pass of `AgentName` counts only when the agent it names wrote it.** A
reader discards a pass from anyone else. The shape can't check this, so the
reader has to: an agent's name is the agent's to choose, and no one else can
rename it. It is the same kind of rule as `Withdrawal`'s, which counts only
from the target's author.

**A `UserSaidChanged` counts only when `by` is who wrote the `UserSaid` at
its `target`.** The same rule again: changing a message is its author's to
do, and a reader discards one from anyone else.

**Who may write a `UserSaid` is the owner gate.** Enforced once, outside
every module, by whatever appends on a module's behalf, so one module can
never put words in another's mouth.

The name on `AgentName` is a plain field, not a `Value` from
[`is_shapes`](https://github.com/intersyntactic/shapes). A `Value` is what
another actor can propose a correction to, and no one corrects an agent's
name for it. `UserSaid` and `ReplyText` are facts, not values either: both
are written once and never revised.

## Why this package, not one per module

A shape only some modules need is declared once, in a package of its own,
because two declarations with one name are two types, and neither binds
where the other is accepted. That test is "which modules need the shape,"
not "who authors it" — the same test that put `Comment`, `Correction` and
`Approve` in `is_annotation_shapes` regardless of who annotates. `UserSaid`
is person-authored and still belongs here, because the Teams and Slack
modules both need it to carry a conversation across a journey path. This
package was named `is_agent_shapes` until that mismatch became visible; it
is now discontinued on pub.dev in this package's favour.

## What it doesn't do

It declares shapes and nothing that runs. The install mints an agent's id on
first boot, in whatever form it likes as long as `ActorId.parse` reads it,
and keeps it. The tail is opaque, so no reader looks inside it, and its form
is no one else's contract.

## The pure list

A shape file may import only what import admission's pure list allows. This
package imports `is_shapes` and `checked_json`, so both have to be on that
list. `test/pure_list_test.dart` holds it to the list, and it reads
directives from the parse tree, so every branch of a conditional import is
read.

## Depending on it

```yaml
dependencies:
  is_conversation_shapes: ^0.8.0
```

It is published after `is_shapes`, which it depends on.
