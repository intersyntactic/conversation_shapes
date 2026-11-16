/// The shapes a journey path's conversation turns on, needed by whichever
/// module carries one, not only the agent: what an agent calls itself, what
/// a person said, and the agent's reply to it.
///
/// Named for what needs these shapes, not for who writes each one:
/// [UserSaid] is person-authored, and this package held it anyway, because
/// the test RULINGS gives a package like this is "which modules need the
/// shape,"
/// the same test that put `Comment`/`Correction`/`Approve`/`Seen` in
/// `is_annotation_shapes` regardless of who annotates. It was named
/// `is_agent_shapes` first and renamed once `UserSaid` made the mismatch
/// visible; `is_agent_shapes` on pub.dev is discontinued in its favour.
///
/// An agent's actor id is `agent:<id>`, an opaque id its install mints once,
/// on first boot, and keeps. Its name is not part of the id: the agent chooses
/// its name, the name can change, and the id never does, so a rename leaves
/// every node the agent has written still naming it. The name is an
/// [AgentName], a node in a journey path like any other.
///
/// How an install mints the id is the install's business: the tail is
/// opaque, so no reader looks inside it, and [ActorId.parse] is the only
/// check it has to pass.
///
/// [UserSaid] and [ReplyText] are the minimum a module needs to carry a
/// Teams or Slack conversation across a journey path: one shape for what
/// a person said, one for the agent's reply to it. Both are facts,
/// written once and never revised, so neither declares `@identity`: every
/// field is identity, the safe default for a node nothing ever corrects.
/// [SourceMessageId] is the typed id [UserSaid.source] carries, so a message
/// id stays a message id and never drifts into a bare [String] that any
/// field could be built from.
///
/// A [UserSaid] may carry a [Quote]: the message it answers or replies to,
/// as its source names it. [QuotedAuthor] is sealed because a quote's
/// author isn't always known, under every way a module might try to
/// resolve one — so a reader has to handle both cases, and a bare display
/// name can never pass for an identity.
///
/// A [UserSaid] may later be edited, deleted, or restored at its source.
/// [WhatChanged] is the module's reading of that, in message terms, before
/// anything maps the message to a [TurnId]; [UserSaidChanged] is the node
/// the apex appends once it has, targeting the turn the way a
/// `Withdrawal` or [ReplyText.answers] does. It is its own shape, not a
/// `Withdrawal<UserSaid>`: a restore has to target the original turn, and
/// a fresh [UserSaid] would mint a new one (Nick, 2026-11-16).
///
/// [ReplyChunk] is not a journey path node at all: it is one piece of a
/// reply as the agent streams it, written to the agent loop's own chain,
/// which RULINGS' apex ruling keeps separate from the journey path's turns
/// ("a loop's chain holds only that loop's turns; each event ... has
/// chains of their own," and a chunk isn't a turn). It is still named here,
/// under the same cross-module test: a renderer outside the loop reads
/// these to show a reply live as it streams
/// (agent-loop-b6/intersyntactic-a8, 2026-11-16).
///
/// [UserSaid] and [WhatChanged] carry strict JSON codecs: encoding and a
/// `fromJson` that refuses an unknown shape, a field missing, extra or of
/// the wrong type, or a malformed id. The walls rule keeps a parser of a
/// stranger's bytes out of any process that holds sign-ins, so a message
/// has to travel already built and typed, in `agent_loop`'s map form
/// (`{"shape": "<class name>", ...its fields}`) — `is_annotation_shapes`'
/// `Verdict` does the same, and the two packages' shape names don't
/// collide (docking-port-e1/annotation-shapes-c9, 2026-11-16).
///
/// It imports `is_shapes` and `checked_json`, so a shape file may import
/// it under import admission's pure list once both are on it.
library;

import 'package:checked_json/checked_json.dart';
import 'package:is_shapes/is_shapes.dart';

/// What an agent calls itself.
///
/// The node is about [agent], its [identity]; [name] is its value. So a rename
/// is a later pass of the same node, at the same anchor, saying a new name,
/// and a reader takes the latest pass. There is no time in it: the journey
/// path's order says which pass is latest.
///
/// A pass counts only when [agent] wrote it. The shape can't check that, so a
/// reader discards a pass written by anyone else: an agent's name is the
/// agent's to choose, and no one else can rename it.
///
/// The name is a plain field, not a [Value]. A [Value] is what another actor
/// can propose a correction to, and no one corrects an agent's name for it.
final class AgentName {
  const AgentName({required this.agent, required this.name});

  /// The agent this names.
  @identity
  final ActorId agent;

  /// The name the agent chose.
  final String name;
}

/// A message's id in its source's own terms: a Teams activity id, a Slack
/// `ts`. Opaque here, like [ActorId]'s tail — this package doesn't know
/// Teams or Slack, so it can't say what either one's ids look like, only
/// that a [UserSaid] carries one and not a bare [String] that any module
/// could build out of the wrong characters.
///
/// A module that must tell Teams' ids from Slack's wraps this field on its
/// own side, the way `SlackActorId` wraps [ActorId] in `slack_module`.
final class SourceMessageId {
  const SourceMessageId._(this.value);

  /// The id, as its source wrote it.
  final String value;

  /// [s] as a source message id, read back from text; null for an empty
  /// string or one with leading, trailing or inner whitespace, since no
  /// known source's ids have any.
  static SourceMessageId? parse(String s) =>
      s.isNotEmpty && !s.contains(RegExp(r'\s')) ? SourceMessageId._(s) : null;

  @override
  bool operator ==(Object other) =>
      other is SourceMessageId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Who wrote the message a [Quote] quotes.
///
/// Not always resolvable: a quote can name someone who never wrote to the
/// journey path the quoting module hears through — someone in a group chat
/// who never addressed the agent, say — so there has to be a case for that
/// too, under every way a module might go about resolving it. A reader
/// switches on both: a display name is something a source showed alongside
/// the quote, never an identity, so nothing reads [UnknownAuthor] as one.
sealed class QuotedAuthor {
  const QuotedAuthor();

  /// [json] as a [QuotedAuthor], read strictly: an unknown shape, a field
  /// missing, extra or of the wrong type, or a malformed id, is a
  /// [FormatException].
  factory QuotedAuthor.fromJson(JsonObject json) {
    final (author, fields) = switch (json.string('shape')) {
      'KnownAuthor' => (
        KnownAuthor(
          ActorId.parse(json.string('actor')) ??
              (throw JsonFieldException('actor', 'an actor id')),
        ),
        const {'shape', 'actor'},
      ),
      'UnknownAuthor' => (
        UnknownAuthor(json.stringOrNull('displayName')),
        const {'shape', 'displayName'},
      ),
      final shape => throw FormatException(
        '`shape` is not a quoted author: $shape',
      ),
    };
    for (final key in json.keys) {
      if (!fields.contains(key)) {
        throw FormatException(
          '`$key` is not a field of ${json.string('shape')}',
        );
      }
    }
    return author;
  }

  /// This [QuotedAuthor] as JSON, for `jsonEncode` inside a [Quote].
  JsonObject toJson();
}

/// The quoted message's author, resolved to an actor id.
final class KnownAuthor extends QuotedAuthor {
  const KnownAuthor(this.actor);

  /// Who wrote the quoted message.
  final ActorId actor;

  @override
  JsonObject toJson() =>
      JsonObject.of({'shape': 'KnownAuthor', 'actor': actor.value});
}

/// The quoted message's author wasn't in the record, or a module's attempt
/// to resolve one failed or was refused.
final class UnknownAuthor extends QuotedAuthor {
  const UnknownAuthor(this.displayName);

  /// Whatever the source showed alongside the quote, if it showed anything.
  final String? displayName;

  @override
  JsonObject toJson() =>
      JsonObject.of({'shape': 'UnknownAuthor', 'displayName': ?displayName});
}

/// A message a [UserSaid] quotes, as its source carries it.
final class Quote {
  const Quote({required this.source, required this.author, this.preview});

  /// The quoted message's id, in its source's own terms. Always within the
  /// same conversation as the [UserSaid] that quotes it, since a quote
  /// never reaches across sources.
  final SourceMessageId source;

  /// Who wrote the quoted message.
  final QuotedAuthor author;

  /// A shortened copy of the quoted text, if the source showed one
  /// alongside the quote. Matters most when [source] never reached the
  /// journey path: then this is the only trace of what was quoted a reader
  /// can still see.
  final String? preview;

  /// [json] as a [Quote], read strictly: a field missing, extra or of the
  /// wrong type, or a malformed id, is a [FormatException].
  factory Quote.fromJson(JsonObject json) {
    const fields = {'source', 'author', 'preview'};
    for (final key in json.keys) {
      if (!fields.contains(key)) {
        throw FormatException('`$key` is not a field of Quote');
      }
    }
    return Quote(
      source:
          SourceMessageId.parse(json.string('source')) ??
          (throw JsonFieldException('source', 'a source message id')),
      author: QuotedAuthor.fromJson(json.object('author')),
      preview: json.stringOrNull('preview'),
    );
  }

  /// This [Quote] as JSON, for `jsonEncode` inside a [UserSaid] or a
  /// [WhatChanged].
  JsonObject toJson() => JsonObject.of({
    'source': source.value,
    'author': author.toJson(),
    'preview': ?preview,
  });
}

/// What a person said, as a module received it from its source.
///
/// There is no echo-matching here: a module describes a [UserSaid] once, the
/// composition appends it after the airlock has witnessed its arrival, and
/// the journey path delivers the [TurnId] it was given back to the module —
/// that is the id everything after it, not least [ReplyText.answers], points
/// at. A module never has to compare text to tell its own message from an
/// echo of it, and it never appends on its own behalf
/// (https://github.com/intersyntactic/teams_module/pull/13).
///
/// "Who may write a [UserSaid]" is the owner gate: enforced once, outside
/// every module, by whatever appends on their behalf, so one module can
/// never put words in another's mouth.
///
/// It travels as JSON in a node's map form, `{"shape": "UserSaid", ...its
/// fields}`, the same form `agent_loop` writes a turn's node in: a module
/// builds one and hands it on already typed, so nothing downstream parses
/// a stranger's bytes (RULINGS: types at the boundary).
final class UserSaid {
  const UserSaid({
    required this.author,
    required this.source,
    required this.text,
    this.quotes,
  });

  /// Who said it.
  final ActorId author;

  /// The message's id in its source's own terms.
  final SourceMessageId source;

  /// What they said. May be empty when [quotes] is set: a reply that is
  /// only a quote and an @-mention, say, carries nothing of its own to say.
  final String text;

  /// The message this one quotes or replies to, if its source carries one.
  final Quote? quotes;

  /// The `shape` this decodes and encodes as, for whoever checks that no
  /// two packages' top-level node shapes collide (docking_station,
  /// 2026-11-16) — not [QuotedAuthor]'s, which nests inside [Quote] and
  /// is never dispatched at that top level.
  static const String shapeName = 'UserSaid';

  /// [json] as a [UserSaid], read strictly: an unknown shape, a field
  /// missing, extra or of the wrong type, or a malformed id, is a
  /// [FormatException].
  factory UserSaid.fromJson(JsonObject json) {
    if (json.string('shape') != shapeName) {
      throw FormatException('`shape` is not $shapeName: ${json.raw('shape')}');
    }
    const fields = {'shape', 'author', 'source', 'text', 'quotes'};
    for (final key in json.keys) {
      if (!fields.contains(key)) {
        throw FormatException('`$key` is not a field of $shapeName');
      }
    }
    return UserSaid(
      author:
          ActorId.parse(json.string('author')) ??
          (throw JsonFieldException('author', 'an actor id')),
      source:
          SourceMessageId.parse(json.string('source')) ??
          (throw JsonFieldException('source', 'a source message id')),
      text: json.string('text'),
      quotes: json.has('quotes') ? Quote.fromJson(json.object('quotes')) : null,
    );
  }

  /// This [UserSaid] in a node's map form, for `jsonEncode`.
  JsonObject toJson() => JsonObject.of({
    'shape': shapeName,
    'author': author.value,
    'source': source.value,
    'text': text,
    'quotes': ?quotes?.toJson(),
  });
}

/// What an earlier [UserSaid] became, in message terms: the source's own
/// account of the change, before anything maps the message to a [TurnId].
///
/// A module's reading produces this from its relay's arrivals, naming the
/// changed message by its [SourceMessageId] (the docking port's `Changed`
/// carries one), since the module never learns which turn its message
/// became.
///
/// It travels as JSON in a node's map form, the same one [UserSaid] does
/// (`{"shape": "<class name>", ...its fields}`), so it can cross the same
/// boundary already typed.
sealed class WhatChanged {
  const WhatChanged();

  /// Every `shape` a [WhatChanged] may decode from, for whoever checks
  /// that no two packages' top-level node shapes collide (docking_station,
  /// 2026-11-16).
  static const Set<String> shapeNames = {
    Edited.shapeName,
    Deleted.shapeName,
    Restored.shapeName,
  };

  /// [json] as a [WhatChanged], read strictly: an unknown shape, a field
  /// missing, extra or of the wrong type, or a malformed id, is a
  /// [FormatException].
  factory WhatChanged.fromJson(JsonObject json) {
    final (change, fields) = switch (json.string('shape')) {
      Edited.shapeName => (
        Edited(
          text: json.string('text'),
          quotes: json.has('quotes')
              ? Quote.fromJson(json.object('quotes'))
              : null,
        ),
        const {'shape', 'text', 'quotes'},
      ),
      Deleted.shapeName => (const Deleted(), const {'shape'}),
      Restored.shapeName => (const Restored(), const {'shape'}),
      final shape => throw FormatException('`shape` is not a change: $shape'),
    };
    for (final key in json.keys) {
      if (!fields.contains(key)) {
        throw FormatException(
          '`$key` is not a field of ${json.string('shape')}',
        );
      }
    }
    return change;
  }

  /// This [WhatChanged] in a node's map form, for `jsonEncode`.
  JsonObject toJson();
}

/// The message was edited: [text] and, if the source now shows one,
/// [quotes] replace what the original [UserSaid] said, wholesale — Teams
/// sends the full new content on an edit, never a diff.
final class Edited extends WhatChanged {
  const Edited({required this.text, this.quotes});

  /// What the message says now.
  final String text;

  /// What it quotes now, if anything.
  final Quote? quotes;

  /// The `shape` this decodes and encodes as.
  static const String shapeName = 'Edited';

  @override
  JsonObject toJson() => JsonObject.of({
    'shape': shapeName,
    'text': text,
    'quotes': ?quotes?.toJson(),
  });
}

/// The message was deleted.
final class Deleted extends WhatChanged {
  const Deleted();

  /// The `shape` this decodes and encodes as.
  static const String shapeName = 'Deleted';

  @override
  JsonObject toJson() => const JsonObject.of({'shape': shapeName});
}

/// A deleted message was restored.
///
/// Not a new [UserSaid]: re-appending one would mint a new [TurnId] for
/// what is semantically the same message, orphaning anything that already
/// points at the turn the original [UserSaid] was given — a [ReplyText]
/// answering it, a later [WhatChanged] of it. A restore has to target that
/// same turn, so it is this shape, not a fresh [UserSaid].
final class Restored extends WhatChanged {
  const Restored();

  /// The `shape` this decodes and encodes as.
  static const String shapeName = 'Restored';

  @override
  JsonObject toJson() => const JsonObject.of({'shape': shapeName});
}

/// The node the journey path's apex appends for a [WhatChanged]: the
/// author changed the [UserSaid] at [target], the [TurnId] the journey
/// path delivered back for it — the apex is who knows that id, since it
/// wrote the turn and the turn's envelope names the arrival it came from.
///
/// [by] counts only when it is who wrote [target]: the same rule
/// [AgentName]'s rename and `is_shapes`' `Withdrawal` both keep. A reader
/// discards a [UserSaidChanged] from anyone else — changing a message is
/// the author's to do, and no one else can do it on their behalf.
///
/// An admin deleting another's message is wanted later (Nick, 2026-11-16)
/// but not this shape: that needs its own rule for who may count, decided
/// when it's built, not guessed at now.
final class UserSaidChanged {
  const UserSaidChanged({
    required this.by,
    required this.target,
    required this.change,
  });

  /// Who changed it. Counts only if this is who wrote [target].
  final ActorId by;

  /// The [UserSaid] this changes, by the [TurnId] the journey path
  /// delivered back for it.
  final TurnId target;

  /// What it became.
  final WhatChanged change;
}

/// One piece of a reply as the agent streams it: a delta, not the reply
/// so far. Written to the agent loop's own chain, not the journey path —
/// a chunk isn't a turn, so it carries no [TurnId] and no index of its
/// own. The chain itself gives every chunk its order, each hashed over
/// its predecessor; once streaming ends, the closing [ReplyText] (or
/// whatever the loop writes to the journey path) references the chain's
/// tip by hash, the only place the chunk chain and the journey path meet.
final class ReplyChunk {
  const ReplyChunk(this.text);

  /// This chunk's own text.
  final String text;
}

/// The agent's reply to one [UserSaid], written once, when the message it
/// answers is finished.
///
/// A streamed reply is shown live as its [ReplyChunk]s arrive, but this is
/// the only pass the journey path sees: the one node, written when
/// streaming ends, not the latest of several.
///
/// [answers] is the [TurnId] the journey path delivered back for the
/// [UserSaid] once it was appended. It is how a module knows which
/// conversation to post into and which message to thread under, and it is
/// what makes two replies two different nodes: each answers a different
/// message, so no turn number or index is needed alongside it.
final class ReplyText {
  const ReplyText({
    required this.by,
    required this.answers,
    required this.text,
  });

  /// The agent that wrote the reply.
  final ActorId by;

  /// The [UserSaid] this replies to, by the [TurnId] it was delivered back.
  final TurnId answers;

  /// What the agent said back.
  final String text;
}
