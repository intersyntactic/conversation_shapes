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
/// It imports only `is_shapes`, so a shape file may import it under import
/// admission's pure list once it is on it.
library;

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
}

/// The quoted message's author, resolved to an actor id.
final class KnownAuthor extends QuotedAuthor {
  const KnownAuthor(this.actor);

  /// Who wrote the quoted message.
  final ActorId actor;
}

/// The quoted message's author wasn't in the record, or a module's attempt
/// to resolve one failed or was refused.
final class UnknownAuthor extends QuotedAuthor {
  const UnknownAuthor(this.displayName);

  /// Whatever the source showed alongside the quote, if it showed anything.
  final String? displayName;
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
}

/// What an earlier [UserSaid] became, in message terms: the source's own
/// account of the change, before anything maps the message to a [TurnId].
///
/// A module's reading produces this from its relay's arrivals, naming the
/// changed message by its [SourceMessageId] (the docking port's `Changed`
/// carries one), since the module never learns which turn its message
/// became.
sealed class WhatChanged {
  const WhatChanged();
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
}

/// The message was deleted.
final class Deleted extends WhatChanged {
  const Deleted();
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

/// The agent's reply to one [UserSaid], written once, when the message it
/// answers is finished.
///
/// A streamed reply is shown live and never stored piece by piece: this is
/// the one pass a message gets, not the latest of several.
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
