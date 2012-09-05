%% Author: tk
%% Created: Sep 5, 2012
%% Description: TODO: Add description to udp_server
-module(udp_server).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([init/0,udp_sndr/1,sender/2]).

%%
%% API Functions
%%

init()->
	{ok, Socket} = gen_udp:open(20510),
	Pid=spawn_link(udp_server,udp_sndr,[Socket]),
	register(sndr, Pid).
	

udp_sndr(Socket)->
	receive
		{Addr,Msg}->
			gen_udp:send(Socket, Addr, 20500, Msg),
			udp_sndr(Socket)
	end.


sender(Address, Message)->	
	sndr !{Address,Message}.
	
	



	

%%
%% Local Functions
%%

