import std.stdio: stdin, writeln, writefln;
import std.string: strip;
import std.socket: Socket, TcpSocket, SocketOption, SocketOptionLevel, InternetAddress, SocketShutdown;
import std.concurrency: thisTid, Tid, send, spawn, receive;
    
Socket[] clients = [];

void socketSendFunc(Tid owner, Socket client) {
    receive((string s) {
            writefln("SocketSendFunc (%s) got message: %s ", owner, s);
            client.send("Welcome from thread!");
            });
}

void connectionListenerFunc(Tid owner) {
    Socket server = new TcpSocket();
    scope(exit) server.close();
    server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);

    server.bind(new InternetAddress(9999));
    server.listen(1);

    while (true) {
        Socket client = server.accept();

        scope(exit) client.close();
        scope(exit) client.shutdown(SocketShutdown.BOTH);

        writeln("Sending welcome message");
        client.send("Welcome");

        // Pass this client to a global list
        //send(owner, client);
        clients ~= client;
    }
}

void keyboardListenFunc(Tid owner) {
    auto barcodeInput = strip(stdin.readln());
    writeln("KeyboardListenFunc got barcode input: ", barcodeInput);

    send(owner, barcodeInput);
}

void main()
{
    auto keyboardListener   = spawn(&keyboardListenFunc,     thisTid);
    auto connectionListener = spawn(&connectionListenerFunc, thisTid);

    while(true) {
        receive(
                // TODO: handle the client disconection case

                //(Socket client) {
                //    // add to global list
                //    client.send("Hello from main loop.");
                //    clients ~= client;
                //}
                
                (string barcodeInput) {
                    writeln ("Clients are: ", clients);

                    writeln ("Sending message: ", barcodeInput);
                    foreach (client; clients) {
                        client.send(barcodeInput);
                    }
                }
               );
    }
}
