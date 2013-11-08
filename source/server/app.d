import core.stdc.stdlib;
import derelict.enet.enet;
import random.markovchain;
import std.file: readText;
import std.stdio: writefln, writeln;
import std.string: toLower;
import msgpack;
import packets;

int main()
{
    DerelictENet.load();

    auto source = readText("../data/testnames.txt").toLower();
    auto letterChain = new MarkovChain!(string)(source, 2);

    bool running = true;
    uint timeout = 50_000;
    ENetAddress address;
    ENetHost *server;
    ENetEvent event;
    int eventStatus;

    if(enet_initialize() != 0)
        return EXIT_FAILURE;

    address.host = ENET_HOST_ANY;
    address.port = 24718;
    server = enet_host_create(&address, 32, 1, 0, 0);
    if(server == null)
        return EXIT_FAILURE;

    while(running)
    {
        eventStatus = enet_host_service(server, &event, timeout);
        if(eventStatus > 0)
        {
            switch(event.type)
            {
                case ENET_EVENT_TYPE_CONNECT:
                    break;
                case ENET_EVENT_TYPE_RECEIVE:
                    ubyte[] outData = event.packet.data[0..event.packet.dataLength];
                    connect c;
                    msgpack.unpack(outData, c);
                    writeln(c.name);
                    enet_packet_destroy(event.packet);
                    break;
                case ENET_EVENT_TYPE_DISCONNECT:
                    break;
                default:
                    break;
            }
        }
    }

    enet_deinitialize();
    return EXIT_SUCCESS;
}
