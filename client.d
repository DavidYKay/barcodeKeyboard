// a test client to verify functionality of the server

import std.stdio;
import std.socket;
        
void main() {
  Socket client = new TcpSocket();
  client.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
  client.connect(new InternetAddress("127.0.0.1", 9999));
  scope(exit) client.close();

  auto buffer = new ubyte[2056];
  ptrdiff_t amountRead;

  while (true) {
      auto received = client.receive(buffer);
      auto msg = buffer[0.. received];
      writeln("Received msg: ", msg);
  }
}
