import std.stdio: stdin, writeln, writefln;
import std.string: strip;
import std.socket: Socket, TcpSocket, SocketOption, SocketOptionLevel, InternetAddress, SocketShutdown;
import std.concurrency: thisTid, Tid, send, spawn, receive;
import std.algorithm.iteration: filter;
import std.array: array;
import std.range.interfaces: InputRange;
//import std.array: Range;
//import std.range: Range;
    
class Lock 
{
}

synchronized class ClientSet
{
    // Note: must be private in synchronized
    // classes otherwise D complains.
    private Socket[] clients;

    void push(shared(Socket) value) {
        clients ~= value;
    }
    
    void cleanup() {
        clients = filter!(s => s.isAlive)(clients).array;
    }

    //Range!(Socket) iterator() {
    InputRange!(Socket) iterator() {
        return clients;
    }

    void messageClients()
    {

    }
}

void connectionListener(shared(Lock) lock, shared(ClientSet) connectedClients) 
{
    Socket server = new TcpSocket();
    scope(exit) server.close();
    server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);

    server.bind(new InternetAddress(9999));
    server.listen(1);

    // TODO: handle the client disconection case

    while (true) {
        Socket client = server.accept();

        scope(exit) client.close();
        scope(exit) client.shutdown(SocketShutdown.BOTH);

        writeln("Sending welcome message");
        client.send("Welcome");

        synchronized(lock) {
            connectedClients ~= client;
        }
    }
}

void main()
{
    shared Lock lock = new shared(Lock)();
    shared ClientSet connectedClients = new ClientSet();

    auto connectionListener = spawn(&connectionListener,
            lock, 
            connectedClients);

    while(true) {
        auto barcodeInput = strip(stdin.readln());
        writeln("KeyboardListenFunc got barcode input: ", barcodeInput);

        writeln ("Clients are: ", connectedClients);

        synchronized(lock) {
            connectedClients.cleanSockets();
            foreach (client; connectedClients.iterator()) {
                client.send(barcodeInput);
            }
        }
    }
}
