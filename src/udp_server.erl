%% Author: tk
%% Created: Sep 5, 2012
%% Description: TODO: Add description to udp_server
-module(udp_server).
-define(ACK,1).
-define(SUCCESS,0).

-define(SVC_ACK_REQ,1).
-define(SVC_RESP_AR,2).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0,init/0,udp_sndr/1,sender/2,rcv_loop/1,packet_decoder/2,send_usr_msg/3]).

%%
%% API Functions
%%
start()->
	init().

init()->
	{ok, Socket} = gen_udp:open(20500,[binary,{ip,{10,100,54,113}}]),
	Pid=spawn_link(udp_server,udp_sndr,[Socket]),
	register(sndr, Pid),
	Pid_rcvr = spawn(udp_server,rcv_loop,[Socket]),
	gen_udp:controlling_process(Socket,Pid_rcvr).
	

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
	case Packet of
		<< Opts:8, MobIdLength:8, MobId:MobIdLength/bytes, MobIdTypeLength:8,MobIdType:8,
			1:8,%% For when Service Type is an acknowledged request
			2:8,%%Rest/binary>> ->  %%Message type = Event Report
			SeqNum:16,UpdateTime:32, TimeOfFix:32,Latitude:32, Longitude:32,
			Altitude:32,Speed:32,Heading:32,Satelites:8,FixStatus:8, Carrier:16,
			Rssi:16, CommState:8, Hdop:8, Inputs:8, UnitStatus:8, EventIndex:8,Rest/binary>> ->
%%			Accums:8, Spare:8, AccumList/binary>> ->
%%			MsgType = 2,
%%			SeqNum = 12,
			MsgType = 1,
			io:format("Event Status Received! ~n");

		<< Opts:8, MobIdLength:8, MobId:MobIdLength/bytes, MobIdTypeLength:8,MobIdType:8,
			1:8,%% For when Service Type is an acknowledged request
			4:8, %%Rest/binary>> -> %%message Type =4
			SeqNum:16,UpdateTime:32, TimeOfFix:32,Latitude:32, Longitude:32,
			Altitude:32,Speed:32,Heading:32,Satelites:8,FixStatus:8, Carrier:16,
			Rssi:16, CommState:8, Hdop:8, Inputs:8, UnitStatus:8,UserMsgRoute:8,UserMsgId:8,UserMessage/binary>> ->

%%			UserMsgId:8,UserMsgeLength:16, UserMessage/binary>> ->
%%			MsgType = 2,
			%%SeqNum = 12,
			
			MsgType = 4,
			io:format("User Message:~s ~n ",[UserMessage]),
			io:format("User Message Received!: ~n");
		
		<< Opts:8, MobIdLength:8, MobId:MobIdLength/bytes, MobIdTypeLength:8,MobIdType:8,
			0:8,%% For when Service Type is an acknowledged request
			2:8,%%Rest/binary>> ->  %%Message type = Event Report
			SeqNum:16,UpdateTime:32, TimeOfFix:32,Latitude:32, Longitude:32,
			Altitude:32,Speed:32,Heading:32,Satelites:8,FixStatus:8, Carrier:16,
			Rssi:16, CommState:8, Hdop:8, Inputs:8, UnitStatus:8, EventIndex:8,Rest/binary>> ->
%%			Accums:8, Spare:8, AccumList/binary>> ->
%%			MsgType = 2,
%%			SeqNum = 12,
			MsgType = 1,
			io:format("Event Status Received! ~n");
		_-> io:format("utter crap ~n"),
			Opts = 1, SeqNum = 1, MsgType = 1, MobIdLength = 1, MobId = 1
	end,

 
%%	io:format("Binary?:~p~n",[is_binary(Packet)]),
%%	io:format("Size:~p~n",[size(Packet)]),
%%	io:format("Host:~p~n",[Host]),
%%	io:format("Options:~p~n",[Opts]),
%%	io:format("MobIdLength:~p~n",[MobIdLength]),
%%	io:format("MobId:~p~n",[MobId]),
%%	io:format("MobIdTypeLength:~p~n",[MobIdTypeLength]),
%%	io:format("MobIdType:~p~n",[MobIdType]),
%%	io:format("ServiceType:~p~n",[ServiceType]),
%%	io:format("MgeType:~p~n",[MsgType]),
%%	io:format("SeqNum:~p~n",[SeqNum]),
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
	io:format("sent to Sender~n"),
	sender(Host, ResponsePacket).

send_usr_msg(Host,Message,MsgId)->
	MsgSize = size(Message),
	Packet = <<16#80:8, %%Options header, include nothing
	1:8, %% Service Type , Acknowldedged Request
	4:8, %% Message Type, User Data message
	0:16,%% sequence Number 0 for now.... should change later for more robustness
	0:8, %%User message route =0
	MsgId:8,  %% to keep track of messages
	MsgSize:16,
	Message/binary>>,
	sender(Host,Packet).

%%
%% Local Functions
%%


