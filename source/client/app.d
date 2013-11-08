import core.stdc.stdlib;
import derelict.enet.enet;
import derelict.sdl2.sdl;
import std.stdio;
import msgpack;
import packets;

int main()
{
    DerelictENet.load();
    DerelictSDL2.load();
    SDL_CreateWindow("keleworld", 200, 300, 200, 300, 0);
    bool running=true;
    SDL_Event e;

    ENetAddress address;
    ENetHost *client;
    ENetPeer *peer;
    ENetEvent event;
    int eventStatus;

    if(enet_initialize() != 0)
        return EXIT_FAILURE;

    enet_address_set_host(&address, "localhost");
    address.port = 23718;
    client = enet_host_create(null, 1, 1, 0, 0);
    if(client == null)
        exit(EXIT_FAILURE);

    peer = enet_host_connect(client, &address, 1, 0);
    if(peer == null)
        exit(EXIT_FAILURE);

    while(running)
    {
        while(SDL_PollEvent(&e))
        {
            switch(e.type)
            {
                case SDL_KEYDOWN:
                    break;
                case SDL_QUIT:
                    running = false;
                    break;
                default:
                    break;
            }
        }

        eventStatus = enet_host_service(client, &event, 0);
        if(eventStatus > 0)
        {
            switch(event.type)
            {
                case ENET_EVENT_TYPE_CONNECT:
                    connect c = connect("Kelet");
                    ubyte[] inData = msgpack.pack(c);
                    ENetPacket *packet = enet_packet_create(&inData[0], inData.sizeof, ENET_PACKET_FLAG_RELIABLE);
                    enet_peer_send(peer, 0, packet);
                    break;
                case ENET_EVENT_TYPE_RECEIVE:
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
