let tmpname script = script ^ ".tmp.ml"
let exename script = script ^ ".exe"

let cleanup script =
  List.iter
    (fun ext ->
      try Unix.unlink (script ^ ext) with
      | Unix.Unix_error (Unix.ENOENT, _, _) -> ()
      | exn -> raise exn)
    [".tmp.ml"; ".tmp.o"; ".tmp.cmx"; ".tmp.cmi"]

let needs_recompile source exe =
  (not (Sys.file_exists exe))
  || (Unix.stat exe).st_mtime <= (Unix.stat source).st_mtime

let recompile flags source =
  let buflen = 4096 in
  let perm = (Unix.stat source).st_perm in
  let oflags = Out_channel.[Open_wronly; Open_creat; Open_trunc; Open_binary] in
  In_channel.with_open_bin source (fun inp ->
      Out_channel.with_open_gen oflags perm (tmpname source) (fun out ->
          (* drop first line only if it's #! *)
          let line = In_channel.input_line inp |> Option.get in
          if not @@ String.starts_with ~prefix:"#!" line then
            Printf.fprintf out "%s\n" line;

          (* underlying I/O buffers; all this does is avoid line-handling *)
          let buffer = Bytes.make buflen '\000' in
          let rec loop () =
            match In_channel.input inp buffer 0 buflen with
            | 0 -> ()
            | n when n = buflen ->
              Out_channel.output_bytes out buffer;
              loop ()
            | n ->
              Out_channel.output_bytes out (Bytes.sub buffer 0 n);
              loop ()
          in
          loop ()));
  let args =
    Array.append
      [|"ocamlfind"; "ocamlopt"|]
      (Array.append flags [|"-o"; exename source; "-impl"; tmpname source|])
  in
  let pid =
    Unix.create_process "ocamlfind" args Unix.stdin Unix.stdout Unix.stderr
  in
  match Unix.waitpid [] pid with
  | p, Unix.WEXITED 0 when p = pid -> ()
  | _, _ -> failwith ("attempted: " ^ String.concat " " (Array.to_list args))
