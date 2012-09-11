%% Author: tk
%% Created: Sep 5, 2012
%% Description: TODO: Add description to udp_server
-module(udp_server).
-define(ACK,1).
-define(SUCCESS,0).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0,init/0,udp_sndr/1,sender/2,rcv_loop/1,packet_decoder/2]).

%%
%% API Functions
%%
start()->
	init().

init()->
	{ok, Socket} = gen_udp:open(20500,[binary]),
	Pid=spawn_link(udp_server,udp_sndr,[Socket]),
	%%Packet1 = <<131,8,53,134,150,4,149,0,80,15,1,2,1,2,0,16,80,71,115,52,80,71,115,53,24,63,227,197,211,228,89,72,0,0,0,0,0,0,0,16,0,5,5,32,1,4,255,159,15,18,28,0,34,62,2,0,0,0,0,0,0,0,47,67>>,
	%%<<Opts:8,Rest/binary>> = Packet1,

	register(sndr, Pid),
	rcv_loop(Socket).

	

udp_sndr(Socket)->
	receive
		{Addr,Msg}->
			gen_udp:send(Socket, Addr, 20510, Msg),
			udp_sndr(Socket)
	end.


sender(Address, Message)->	
	io:format("MessageSent~n"),
	sndr ! {Address,Message}.
	
	
rcv_loop(Socket) ->
    inet:setopts(Socket, [{active, once}, binary]),
	io:format("rcvr started.~n"),
    receive
        {udp, Socket, Host, Port, Bin} ->
            packet_decoder(Host,Bin),
            rcv_loop(Socket)
	end.

		
packet_decoder(Host,Packet)->
	io:format("Binary?:~p~n",[is_binary(Packet)]),
	io:format("Size:~p~n",[size(Packet)]),
	<< Opts:8, MobIdLength:8, MobId:MobIdLength/bytes, MobIdTypeLength:8,MobIdType:8, ServiceType:8, MsgType:8, SeqNum:16, Rest/binary >> = Packet,
	io:format("Host:~p~n",[Host]),
	io:format("Options:~p~n",[Opts]),
	io:format("MobIdLength:~p~n",[MobIdLength]),
	io:format("MobId:~p~n",[MobId]),
	io:format("MobIdTypeLength:~p~n",[MobIdTypeLength]),
	io:format("MobIdType:~p~n",[MobIdType]),
	io:format("ServiceType:~p~n",[ServiceType]),
	io:format("MgeType:~p~n",[MsgType]),
	io:format("SeqNum:~p~n",[SeqNum]),
	ResponsePacket = <<Opts:8,MobIdLength:8,MobId:MobIdLength/bytes,
	1:8, %% MobIdTypeLength Always 1
	2:8, %% Mobile ID Type 2 = IMEI
	2:8, %% Service Type 1 = Acknowledged Request
	?ACK:8,
	SeqNum:16,
	MsgType:8,
	?SUCCESS:8,
	0:8, %% Spare Unused (always 0
	100:24>>,
	sender(Host, ResponsePacket).

%%
%% Local Functions
%%

