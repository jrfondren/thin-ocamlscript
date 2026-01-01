thin-ocamlscript lets you use OCaml as a scripting language while only paying
the compilation cost once per modification of a script, and while getting
dependencies and preprocessing through ocamlfind.

thin-ocamlscript is very similar to ocamlscript, but

1. the only configuration possible is in the shebang line, in arguments to `ocamlfind ocamlopt`
2. the script is not touched apart from dropping the shebang line
3. there's no provision for multiple source files (skipping examples/calc.ml)

For altered behavior (e.g., tmp files in /tmp, Unix and Ezcurl loaded by
default, the -vm or -debug flags from ocamlscript), the expectation is that
you'll use a fork.

For a shorter name like "ocamlscript", you can rename the binary.

# installing

with opam:
```
opam pin add thin-ocamlscript https://github.com/jrfondren/thin-ocamlscript.git
```

cloning this repo and using dune:
```
git clone https://github.com/jrfondren/thin-ocamlscript && cd thin-ocamlscript
dune install --release
```

using dune and manually placing the binary:
```
dune build --release
mv _build/default/bin/main.exe ~/bin/ocamlscript
```

catting a single .ml together and building that with ocamlfind:
```
cat lib/script.ml > oscript.ml
sed 1d bin/main.ml >> oscript.ml
ocamlfind ocamlopt -O3 -package unix -linkpkg -o oscript oscript.ml
```

# examples

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

# design

A temporary file is required by ocamlc/ocamlopt objecting to #! lines.

The temporary file ending in .ml is required by camlp4.

The .ml.exe is required by shell tab completion: if it was only .exe, then
hello.ml and hello.exe in the same dir would pause completion at 'hello.'.

To not use hidden files for the executable is advised to help differentiate it
from malware.

I preferred to avoid /tmp for compilation for some subtle reasons, including
that sensitive scripts would not accidentally escape filesystem security on the
script, think /root/bin/ping-secret-api.ml

# editing with Merlin

This generated vimscript, which calls :MerlinUse on every package in
first line, improves the editing experience a great deal:

```
autocmd BufReadPost *.ml call SetupMerlinPackages()

function! SetupMerlinPackages()
  let first_line = getline(1)
  let matches = matchlist(first_line, '-package \(\w\+\)')
  let start = 0
  while 1
    let m = matchstr(first_line, '-package \zs\w\+', start)
    if m == ''
      break
    endif
    execute ':MerlinUse ' . m
    let start = matchend(first_line, '-package \w\+', start)
  endwhile
endfunction
```
