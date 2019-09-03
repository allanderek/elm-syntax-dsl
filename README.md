# elm-syntax-dsl

Provides a DSL that makes it simpler to write code in Elm that generates Elm code; simpler
than `stil4m/elm-syntax` on which this DSL is based.

## Simpler code generation as a DSL.

`stil4m/elm-syntax` uses a lot of records to capture parameters, and also wraps parts of the
AST in `Node`s that capture source code lines and rows corresponding to parts of the AST.
This DSL inlines most of the records as function parameters.

Any parts of the AST needing to be wrapped in nodes are automatically wrapped in nodes with
zeroed out source code position information. As the purpose of this package is code generation
of Elm from scratch, rather than the analysis or manipulation of existing Elm, it is ok to
have the source code positional information zeroed out.

## Pretty printed results stable under `elm-format`.

The pretty printer aims to be fully stable with respect to `elm-format` in the sense that
running `elm-format` on the output should have no effect at all. The advantage of this is
that if generated code moves to being edited by hand, there will not be a large white-space
only diff created when `elm-format` is applied.

Known deviations from `elm-format`:

* Not printing port signatures.
* Escaping in Strings has some issues (" and \n, others?)
* Needs brackets in signatures around functions.
* Needs brackets in signatures around nested type arguments that have arguments - List (Maybe String)
