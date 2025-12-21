open Thin_ocamlscript.Script

let split_args a =
  let len = Array.length a in
  match Array.find_index (( = ) "--") a with
  | None -> ([||], a.(1), Array.sub a 1 (len - 1))
  | Some i ->
    (Array.sub a 1 (i - 1), a.(i + 1), Array.sub a (i + 1) (len - i - 1))

let () =
  if Array.length Sys.argv = 1 then (
    Printf.printf
      "usage: #! /usr/bin/env -S %s -package unix -linkpkg --\n\
       The -- should always be present and always at the end of the line\n\
       Arguments are to ocamlfind ocamlopt\n\
       For more, https://github.com/jrfondren/thin-ocamlscript\n"
      (Filename.basename Sys.argv.(0));
    exit 1);
  let oargs, script, sargs = split_args Sys.argv in
  let exe = exename script in
  if needs_recompile script exe then
    Fun.protect
      ~finally:(fun () -> cleanup script)
      (fun () -> recompile oargs script);
  Unix.execv exe sargs
