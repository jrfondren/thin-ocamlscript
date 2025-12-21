thin-ocamlscript lets you use OCaml as a scripting language while only paying
the compilation cost once per modification of a script, and while getting
dependencies and preprossing through ocamlfind.

thin-ocamlscript is very similar to ocamlscript, but

1. the only configuration possible is in the shebang line, in arguments to `ocamlfind ocamlopt`
2. the script is not touched apart from dropping the shebang line
3. there's no provision for multiple source files (skipping examples/calc.ml)

For altered behavior (e.g., tmp files in /tmp, Unix and Ezcurl loaded by
default, the -vm or -debug flags from ocamlscript), the expectation is that
you'll use a fork.

# installing

```
$ opam install thin-ocamlscript   # with opam

$ dune install --release          # with dune

$ dune build --release            # dune, manual install
$ mv _build/default/bin/main.exe ~/bin/thin-ocamlscript

$ cat lib/script.ml > oscript.ml  # manual, single-file 
$ sed 1d bin/main.ml >> oscript.ml  # skip 'open'
$ vi oscript.ml                   # make it print "recompiling! ..."
$ ocamlfind ocamlopt -O3 -package unix -linkpkg -o oscript oscript.ml
```

# very brief examples

```ocaml
#! /usr/bin/env -S thin-ocamlscript -package unix -linkpkg --
let () = Printf.printf "%.0f\n" (Unix.time ())
```

```ocaml
#! /usr/bin/env -S thin-ocamlscript -package ppx_deriving.show -linkpkg --
type args = string array [@@deriving show]
let () = Format.printf "%a\n" pp_args Sys.argv
```

examples/ has replications of ocamlscript's examples

# env

`env -S` and `--` are required for reasonable behavior. Without the latter your
script cannot itself receive a `--`. With `env` and no `-S` you can't pass any
arguments to ocamlfind, and you'll still have the `--` limitation on the
script's own arguments.

Even if you'd rather not search through PATH to find thin-ocamlscript, you need
`env -S`, and in this case it should be an absolute path or it'll depend on the
caller's working directory:

```ocaml
#! /usr/bin/env -S /opt/ocaml/bin/thin-ocamlscript -package unix -linkpkg --
(* ... *)
```

# files

```ocaml
let tmpname script = script ^ ".tmp.ml"
let exename script = script ^ ".exe"

let cleanup script =
  List.iter
    (fun ext ->
      try Unix.unlink (script ^ ext) with
      | Unix.Unix_error (Unix.ENOENT, _, _) -> ()
      | exn -> raise exn)
    [".tmp.ml"; ".tmp.o"; ".tmp.cmx"; ".tmp.cmi"]
```

The exename is compiled if not newer than the script. The tmpname is deleted
after compilation. There is no protection against you doing something placing a
hello.ml script next to a hello.tmp.ml that you would regret losing.

# defects

1. Editors do not understand that the shebang line affects the environment of the script, and will e.g. complain about an "Unbound module Unix" in the first example. For this reason I think a 'dune-ocamlscript' (ocamlscript-dune?) that unpacks/repacks a script from an ephemeral dune repo would make for a generally more pleasant experience.

2. The name's too long. It should probably also be 'ocamlscript-thin' but to me that suggests a relationship with ocamlscript.

# design

A temporary file is required by ocamlc/ocamlopt objecting to #! lines.

The temporary file ending in .ml is required by camlp4.

The .ml.exe is required by shell tab completion: if it was only .exe, then
hello.ml and hello.exe in the same dir would pause completion at 'hello.'.

To not use hidden files for the executable is advised to help differentiate it
from malware.

I preferred to avoid /tmp for compilation for some subtle reasons, including
that sensitive scripts would not accidentally scape filesystem security on the
script, think /root/bin/ping-secret-api.ml
