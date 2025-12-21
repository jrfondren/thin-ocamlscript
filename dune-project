(lang dune 3.20)
(name thin-ocamlscript)
(generate_opam_files true)
(source
 (github jrfondren/thin-ocamlscript))

(authors "Julian Fondren <julian.fondren@gmail.com>")
(maintainers "Julian Fondren <julian.fondren@gmail.com>")
(license MIT)
(documentation https://github.com/jrfondren/thin-ocamlscript)

(package
 (name thin-ocamlscript)
 (synopsis "OCaml as a scripting language with ocamlfind")
 (description "Similar to ocamlscript, but configuration is restricted to the shebang line.")
 (depends
  (ocaml (>= 5.2)) ;; or 5.1 which introduced Array.find_index
  (ocamlfind (>= 1.9.8)))) ;; latest
