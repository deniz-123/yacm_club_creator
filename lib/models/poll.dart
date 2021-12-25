import 'package:mock_data_generator/models/post.dart';

class Poll implements Post {
  final String _author;
  final String _clubID;
  final bool _commentsOn;
  final String _message;
  final DateTime _publishDate;
  final List<String> _options;
  final List<int> _votes;
  final String _question;
  final PostType _type = PostType.POLL;
  final String _id;

  String get author => _author;
  String get clubID => _clubID;
  String get message => _message;
  bool get commentsOn => _commentsOn;
  DateTime get publishDate => _publishDate;
  List<String> get options => _options;
  List<int> get votes => _votes;
  String get question => _question;
  PostType get type => _type;
  String get id => _id;

  Poll(this._author, this._clubID, this._commentsOn, this._message,
      this._publishDate, this._options, this._votes, this._question, this._id);

  Map<String, dynamic> toMap() {
    return {
      "author": _author,
      "clubID": _clubID,
      "message": _message,
      "commentsOn": _commentsOn,
      "publishDate": _publishDate,
      "options": _options,
      "question": _question,
      "votes": _votes,
      "type": _type,
      "id": _id
    };
  }
}
