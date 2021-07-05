import std.stdio: stdin, writeln, writefln;
import std.string: strip;
import std.socket: Socket, TcpSocket, SocketOption, SocketOptionLevel, InternetAddress, SocketShutdown, SocketAcceptException;
import std.concurrency: thisTid, Tid, send, spawn, receive, receiveOnly, receiveTimeout;
import std.algorithm.iteration: filter;
import std.array: array;
import std.range.interfaces: InputRange;
import core.time: dur;

class ClientManager
{
    private Socket[] clients;
    private Socket server;

    this() {
        server = new TcpSocket();
        server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
        server.blocking = false;

        server.bind(new InternetAddress(9999));
        server.listen(1);
    }

    ~this() 
    {
        foreach (client; clients) {
            client.close();
            client.shutdown(SocketShutdown.BOTH);
        }
        server.close();
    }

    void acceptConnection() {
        writeln("Checking for new connection");
        try {
            Socket client = server.accept();

            writeln("Sending welcome message to new client");
            client.send("Welcome");

            clients ~= client;
        } catch (SocketAcceptException e) {
            writeln("No new client received.");
        }
    }

    void push(Socket value) {
        clients ~= value;
    }
    
    void cleanup() {
        auto toShutdown = filter!(s => !s.isAlive)(clients);

        foreach (client; toShutdown) {
            client.close();
            client.shutdown(SocketShutdown.BOTH);
        }

        clients = filter!(s => s.isAlive)(clients).array;
    }

    void messageClients(string s) {
        writeln ("Clients before cleanup are: ", clients);
        cleanup();
        writeln ("Clients after cleanup are: ", clients);
        writeln ("Sending message: ", s);
        foreach (client; clients) {
            client.send(s);
        }
    }
}

void keyboardWatcherFunc(Tid parentTid)
{
    while (true) {
        send(parentTid, strip(stdin.readln()));
    }
}

void main()
{
    ClientManager clientManager = new ClientManager();
    auto keyboardWatcher = spawn(&keyboardWatcherFunc, thisTid);

    while(true) {
        clientManager.acceptConnection();

        writeln("Checking for keyboard input.");

        receiveTimeout(
            dur!"msecs"(50),
            (string s) {
                clientManager.messageClients(s);
            }
        );
    }
}
