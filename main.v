From Praecia Require Import TCP.
From FreeSpec Require Exec.

Generalizable All Variables.

Definition main `{Provide ix TCP} : impure ix unit :=
  do var server <- new_tcp_socket "127.0.0.1:8080" in
     listen_incoming_connection server;

     var client <- accept_connection server in
     read_socket client >>= write_socket client;

     close_socket client;
     close_socket server
  end.

Exec main.
