// UserSaid and WhatChanged travel as JSON in agent_loop's node map form
// ({"shape": "<class name>", ...fields}), read strictly: an unknown shape, a
// field missing, extra or of the wrong type, or a malformed id, is refused
// (docking-port-e1, 2026-11-16).
import 'package:checked_json/checked_json.dart';
import 'package:is_conversation_shapes/is_conversation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';
import 'package:test/test.dart';

void main() {
  group('UserSaid', () {
    test('round-trips without a quote', () {
      final said = UserSaid(
        author: ActorId.parse('teams:f6a2.../b901...')!,
        source: SourceMessageId.parse('1234567890.123456')!,
        text: 'how is the demo coming?',
      );
      final back = UserSaid.fromJson(JsonObject.parse(said.toJson())!);
      expect(back.author, said.author);
      expect(back.source, said.source);
      expect(back.text, said.text);
      expect(back.quotes, isNull);
    });

    test('round-trips with a quote of a known author and a preview', () {
      final said = UserSaid(
        author: ActorId.parse('teams:f6a2.../b901...')!,
        source: SourceMessageId.parse('1234567890.654321')!,
        text: '',
        quotes: Quote(
          source: SourceMessageId.parse('1234567890.123456')!,
          author: KnownAuthor(ActorId.parse('agent:7f3a9c21')!),
          preview: 'nearly there',
        ),
      );
      final back = UserSaid.fromJson(JsonObject.parse(said.toJson())!);
      expect(back.quotes, isNotNull);
      expect(back.quotes!.source, said.quotes!.source);
      expect(
        (back.quotes!.author as KnownAuthor).actor,
        ActorId.parse('agent:7f3a9c21'),
      );
      expect(back.quotes!.preview, 'nearly there');
    });

    test('round-trips a quote of an unknown author with no display name', () {
      final said = UserSaid(
        author: ActorId.parse('teams:f6a2.../b901...')!,
        source: SourceMessageId.parse('1234567890.654321')!,
        text: 'who said that?',
        quotes: Quote(
          source: SourceMessageId.parse('1234567890.123456')!,
          author: const UnknownAuthor(null),
        ),
      );
      final back = UserSaid.fromJson(JsonObject.parse(said.toJson())!);
      expect(back.quotes!.author, isA<UnknownAuthor>());
      expect((back.quotes!.author as UnknownAuthor).displayName, isNull);
      expect(back.quotes!.preview, isNull);
    });

    test('refuses an unknown shape', () {
      expect(
        () => UserSaid.fromJson(
          const JsonObject.of({
            'shape': 'SomethingElse',
            'author': 'teams:a',
            'source': 's',
            'text': 't',
          }),
        ),
        throwsFormatException,
      );
    });

    test('refuses a missing field', () {
      expect(
        () => UserSaid.fromJson(
          const JsonObject.of({
            'shape': 'UserSaid',
            'author': 'teams:a',
            'source': 's',
          }),
        ),
        throwsA(isA<JsonFieldException>()),
      );
    });

    test('refuses an extra field', () {
      expect(
        () => UserSaid.fromJson(
          const JsonObject.of({
            'shape': 'UserSaid',
            'author': 'teams:a',
            'source': 's',
            'text': 't',
            'extra': 'nope',
          }),
        ),
        throwsFormatException,
      );
    });

    test('refuses a malformed actor id', () {
      expect(
        () => UserSaid.fromJson(
          const JsonObject.of({
            'shape': 'UserSaid',
            'author': 'not an id',
            'source': 's',
            'text': 't',
          }),
        ),
        throwsA(isA<JsonFieldException>()),
      );
    });

    test('refuses a malformed source message id', () {
      expect(
        () => UserSaid.fromJson(
          const JsonObject.of({
            'shape': 'UserSaid',
            'author': 'teams:a',
            'source': 'has space',
            'text': 't',
          }),
        ),
        throwsA(isA<JsonFieldException>()),
      );
    });
  });

  group('WhatChanged', () {
    test('round-trips Edited with a new quote', () {
      final changed = Edited(
        text: 'actually, tomorrow',
        quotes: Quote(
          source: SourceMessageId.parse('1234567890.123456')!,
          author: KnownAuthor(ActorId.parse('agent:7f3a9c21')!),
        ),
      );
      final back = WhatChanged.fromJson(JsonObject.parse(changed.toJson())!);
      expect(back, isA<Edited>());
      expect((back as Edited).text, 'actually, tomorrow');
      expect(back.quotes, isNotNull);
    });

    test('round-trips Edited with no quote', () {
      final changed = const Edited(text: 'fixed a typo');
      final back = WhatChanged.fromJson(JsonObject.parse(changed.toJson())!);
      expect(back, isA<Edited>());
      expect((back as Edited).quotes, isNull);
    });

    test('round-trips Deleted', () {
      final back = WhatChanged.fromJson(
        JsonObject.parse(const Deleted().toJson())!,
      );
      expect(back, isA<Deleted>());
    });

    test('round-trips Restored', () {
      final back = WhatChanged.fromJson(
        JsonObject.parse(const Restored().toJson())!,
      );
      expect(back, isA<Restored>());
    });

    test('refuses an unknown shape', () {
      expect(
        () => WhatChanged.fromJson(const JsonObject.of({'shape': 'Archived'})),
        throwsFormatException,
      );
    });

    test('refuses an extra field on Deleted', () {
      expect(
        () => WhatChanged.fromJson(
          const JsonObject.of({
            'shape': 'Deleted',
            'text': 'should not be here',
          }),
        ),
        throwsFormatException,
      );
    });

    test('refuses a missing field on Edited', () {
      expect(
        () => WhatChanged.fromJson(const JsonObject.of({'shape': 'Edited'})),
        throwsA(isA<JsonFieldException>()),
      );
    });
  });
}
