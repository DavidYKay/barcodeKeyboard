import std.stdio;
import std.string;
import std.socket;

void main()
{
    // server
    Socket server = new TcpSocket();
    scope(exit) server.close();
    server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);

    server.bind(new InternetAddress(9999));
    server.listen(1);

    // TODO: Should we accept more than one client? Probably.
    Socket client = server.accept();
    scope(exit) client.close();
    scope(exit) client.shutdown(SocketShutdown.BOTH);

    while(true) {
        auto barcodeInput = strip(stdin.readln());
        writeln("Got barcode input: ", barcodeInput);
        client.send(barcodeInput);
    }
}
