import 'dart:io';
import 'dart:convert';

typedef OnMessageReceived = void Function(String senderIp, String message);

class UDPService {
  final int port;
  late RawDatagramSocket _socket;
  OnMessageReceived? onMessage;

  UDPService({this.port = 5000});

  Future<void> startListening() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket.broadcastEnabled = true;

    _socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket.receive();
        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          onMessage?.call(datagram.address.address, message);
        }
      }
    });
  }

  void sendMessage(String message) {
    final data = utf8.encode(message);
    _socket.send(data, InternetAddress('255.255.255.255'), port);
  }

  void close() {
    _socket.close();
  }
}
