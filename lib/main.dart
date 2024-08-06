import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(FriendListApp());
}

class Friend {
  String name;
  String grade;
  String club;
  String hobby;
  String instaId;
  String meetPlace;
  bool isPinned; //ピンされてるかどうかの属性追加
  DateTime dateAdded;

  Friend(this.name, this.grade, this.club, this.hobby, this.instaId, this.meetPlace,  {this.isPinned = false, required this.dateAdded}); //ピンされているかどうかもフレンドオブジェクトを作ると生成される

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grade': grade,
      'club': club,
      'hobby': hobby,
      'instaId': instaId,
      'meetPlace': meetPlace,
      'isPinned': isPinned, //追加
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  static Friend fromJson(Map<String, dynamic> json) {
    return Friend(
      json['name'],
      json['grade'],
      json['club'],
      json['hobby'],
      json['instaId'],
      json['meetPlace'],
      isPinned: json['isPinned'], //追加
      dateAdded: DateTime.parse(json['dateAdded']),
    );
  }
}

class FriendListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FriendListPage(),
      theme: ThemeData(
        primaryColor: Colors.white,
        hintColor: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FriendListPage extends StatefulWidget {
  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  List<Friend> friends = [];
  bool isSortedByNew = true; //デフォルトを新しい順に表示に設定

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _addFriend() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = '';
        String grade = '';
        String club = '';
        String hobby = '';
        String instaId = '';
        String meetPlace = '';

        return AlertDialog(
          title: Text('友達を追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildTextField('名前', (value) => name = value),
                _buildTextField('学年', (value) => grade = value),
                _buildTextField('部活', (value) => club = value),
                _buildTextField('趣味', (value) => hobby = value),
                _buildTextField('インスタID', (value) => instaId = value),
                _buildTextField('出会った場所', (value) => meetPlace = value),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  friends.add(Friend(name, grade, club, hobby, instaId, meetPlace,dateAdded: DateTime.now()));
                  _saveFriends();
                  _sortFriends(); //ソート機能のメソッド呼び出し
                });
                Navigator.of(context).pop();
              },
              child: Text('追加'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  void _editFriend(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = friends[index].name;
        String grade = friends[index].grade;
        String club = friends[index].club;
        String hobby = friends[index].hobby;
        String instaId = friends[index].instaId;
        String meetPlace = friends[index].meetPlace;

        return AlertDialog(
          title: Text('友達を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildTextField('名前', (value) => name = value, initialValue: name),
                _buildTextField('学年', (value) => grade = value, initialValue: grade),
                _buildTextField('部活', (value) => club = value, initialValue: club),
                _buildTextField('趣味', (value) => hobby = value, initialValue: hobby),
                _buildTextField('インスタID', (value) => instaId = value, initialValue: instaId),
                _buildTextField('出会った場所', (value) => meetPlace = value, initialValue: meetPlace),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  friends[index] = Friend(name, grade, club, hobby, instaId, meetPlace, isPinned: friends[index].isPinned, dateAdded: friends[index].dateAdded);
                  _saveFriends();
                });
                Navigator.of(context).pop();
              },
              child: Text('保存'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  //ピン留め機能実装メソッド
  void _togglePinFriend(int index) {
    setState(() {
      friends[index].isPinned = !friends[index].isPinned;
      _sortFriends(); //ソート機能のメソッドを呼び出し
      _saveFriends();
    });
  }

  void _deleteFriend(int index) {
    setState(() {
      friends.removeAt(index);
      _saveFriends();
    });
  }


  TextField _buildTextField(String label, Function(String) onChanged, {String initialValue = ''}) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      controller: TextEditingController(text: initialValue),
    );
  }

  void _saveFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> friendList = friends.map((friend) => json.encode(friend.toJson())).toList();
    await prefs.setStringList('friendList', friendList);
  }

  void _loadFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? friendList = prefs.getStringList('friendList');

    if (friendList != null) {
      setState(() {
        friends = friendList.map((item) => Friend.fromJson(json.decode(item))).toList();
        _sortFriends();
        });
      }
    }

  //友達リストを並べ替えるメソッド
  void _sortFriends() {
    setState(() {
      // friendsリストを並べ替える
      friends.sort((a, b) {
        //ピン留めされた友達をリストの先頭に移動
        if (a.isPinned && !b.isPinned) return -1; //aがbの前に来るようにする
        if (!a.isPinned && b.isPinned) return 1; //bがaの前に来るようにする

        //ピン留めされていない友達は、指定された順序(新しい順または古い順)で並べ替える
        if (isSortedByNew) {
          return b.dateAdded.compareTo(a.dateAdded); // 新しい順
        } else {
          return a.dateAdded.compareTo(b.dateAdded); // 古い順
        }
      });
    });
  }

  // 並べ替え順序を切り替えるメソッド
  void _toggleSortOrder() {
    setState(() {
      isSortedByNew = !isSortedByNew; // 現在の並べ替え順序を反転
      _sortFriends(); //友達リストを新しい順または古い順に再度並べ替える
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('友達リスト'),
        backgroundColor: Colors.lightBlue[50],
        actions: [
          TextButton(
            onPressed: _toggleSortOrder,
            child: Text(
              isSortedByNew ? '新しい順' : '古い順',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[50],  // Scaffoldの背景色を水色に設定
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(friends[index].name),
            //友達の名前の下に追加日時表示
            subtitle: Text(friends[index].dateAdded.toString()),
            onTap: () => _editFriend(index),
            trailing: Wrap(
              spacing: 12,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    friends[index].isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: friends[index].isPinned ? Colors.lightBlue[900] : null,
                  ),
                  onPressed: () => _togglePinFriend(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteFriend(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: _addFriend,
            child: Icon(Icons.add),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        ],
      ),
    );
  }
}
