// An agent naming itself, a person's message, and the agent's reply to it.
import 'dart:typed_data';

import 'package:is_conversation_shapes/is_conversation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';

void main() {
  // The id the install minted on first boot and keeps. Its tail is opaque.
  final id = ActorId.parse('agent:7f3a9c21')!;

  // The first node the agent writes says what it is called.
  final named = AgentName(agent: id, name: 'Wren');

  // A rename is a later pass of the same node, at the same anchor, written
  // by the same agent. A reader takes the latest.
  final renamed = AgentName(agent: id, name: 'Kestrel');

  print('${named.agent} was ${named.name}, and is ${renamed.name}');

  // A person's message, as Teams received it.
  final peter = ActorId.parse('teams:f6a2.../b901...')!;
  final said = UserSaid(
    author: peter,
    source: SourceMessageId.parse('1234567890.123456')!, // the activity id
    text: 'how is the demo coming?',
  );
  print('${said.author} said: ${said.text}');

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
  print('${onlyAQuote.author} quoted ${onlyAQuote.quotes?.author}');

  // The journey path delivers back a TurnId for `said` once it's appended;
  // here we stand one in, since nothing is actually being stored.
  final saidId = TurnId.of(Uint8List(0));

  // The agent's reply answers it by that id, not by matching text.
  final reply = ReplyText(by: id, answers: saidId, text: 'nearly there');

  print('${reply.by} answers ${reply.answers}: ${reply.text}');
}
