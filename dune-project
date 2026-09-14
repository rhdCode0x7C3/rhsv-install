(lang dune 3.18)

(name rhsv-install)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "rhdCode0x7C3")

(maintainers "rhdCode0x7C3")

(license MIT)

(documentation https://url/to/documentation)

(package
 (name rhsv-install)
 (synopsis "Void Linux installer for rhsv")
 (description "Void Linux installer for rhsv")
 (depends
  (ocaml
   (>= 5.4.1))
  ;; Dev setup
  (utop :with-dev-setup)
  (ocamlformat :with-dev-setup)
  (ocp-indent :with-dev-setup)
  (merlin :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)
  ;; Test
  (alcotest :with-test)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
