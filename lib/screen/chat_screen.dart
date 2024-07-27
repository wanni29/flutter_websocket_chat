import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_websocket_study/model/chat_message.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> chatMessagList = [];
  //  UUID를 사용하여 고유의 senderId 생성
  final String senderId = Uuid().v4();

  void connectWebSocket({bool forceConnect = false}) {
    if (!forceConnect && _channel != null) {
      return;
    }

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.0.7:3000'),
    );

    _channelSubscription = _channel!.stream.listen(
      (message) {
        log('Received message : $message');
        setState(() {
          final jsonMessage = jsonDecode(message);
          final chatMessage = ChatMessage.fromJson(jsonMessage);
          chatMessagList.add(chatMessage);
        });
      },
      onDone: () {
        log('WebSocket connection closed');
      },
      onError: (error) {
        log('WebSocket error : $error');
      },
    );

    _channel!.sink.add(json.encode({'action': 'ping'}));
    log('WebSocket connected and ping message sent.');
  }

  void disconnectWebSocket() {
    _channelSubscription?.cancel();
    _channel?.sink.close(1001);
    _channel = null;
    _channelSubscription = null;
  }

  @override
  void initState() {
    super.initState();
    connectWebSocket(forceConnect: true);
  }

  @override
  void dispose() {
    log('웹 소켓 연결이 종료됩니다 : )');
    disconnectWebSocket();
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      // JSON 형식으로 메세지 보내기
      final message = jsonEncode(
        {
          'event': 'message',
          'data': {
            'message': _controller.text,
            'senderId': senderId,
          },
        },
      );
      _channel!.sink.add(message);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chat App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: chatMessagList.length,
                itemBuilder: (context, index) {
                  final chatMessage = chatMessagList[index];
                  final isMe = chatMessage.senderId == senderId;
                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: EdgeInsets.symmetric(vertical: 4),
                      color: isMe ? Colors.blue : Colors.grey,
                      child: Text(
                        chatMessage.message,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Send a message',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _sendMessage,
              child: Text('Send'),
            )
          ],
        ),
      ),
    );
  }
}
