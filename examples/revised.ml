#! /usr/bin/env -S thin-ocamlscript -package camlp4 -syntax camlp4r -linkpkg --
value hello () =
  do { print_endline "Hello!";
       print_endline "Goodbye!" }
;

value __ = hello ()
;
