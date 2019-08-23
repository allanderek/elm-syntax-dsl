module Elm.Pretty exposing (pretty)

import Elm.Syntax.Comments exposing (Comment)
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.Exposing exposing (ExposedType, Exposing(..), TopLevelExpose(..))
import Elm.Syntax.Expression exposing (Case, CaseBlock, Expression(..), Function, FunctionImplementation, Lambda, LetBlock, LetDeclaration(..), RecordSetter)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Infix exposing (Infix, InfixDirection(..))
import Elm.Syntax.Module exposing (DefaultModuleData, EffectModuleData, Module(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..), QualifiedNameRef)
import Elm.Syntax.Range exposing (Location, Range, emptyRange)
import Elm.Syntax.Signature exposing (Signature)
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import Pretty exposing (Doc)


denode =
    Node.value


denodeAll =
    List.map denode


denodeMaybe =
    Maybe.map denode


pretty : File -> Doc
pretty file =
    Pretty.lines
        [ prettyModule (denode file.moduleDefinition)
        , prettyComments (denodeAll file.comments)
        , prettyImports (denodeAll file.imports)
        , prettyDeclarations (denodeAll file.declarations)
        ]


prettyModule : Module -> Doc
prettyModule mod =
    case mod of
        NormalModule defaultModuleData ->
            prettyDefaultModuleData defaultModuleData

        PortModule defaultModuleData ->
            prettyDefaultModuleData defaultModuleData

        EffectModule effectModuleData ->
            prettyEffectModuleData effectModuleData


prettyModuleName : ModuleName -> Doc
prettyModuleName name =
    List.map Pretty.string name
        |> Pretty.join dot


prettyDefaultModuleData : DefaultModuleData -> Doc
prettyDefaultModuleData moduleData =
    Pretty.join Pretty.space
        [ Pretty.string "module"
        , prettyModuleName (denode moduleData.moduleName)
        , Pretty.string "exposing"
        , prettyExposing (denode moduleData.exposingList)
        ]


prettyEffectModuleData : EffectModuleData -> Doc
prettyEffectModuleData moduleData =
    Pretty.join Pretty.space
        [ Pretty.string "module"
        , prettyModuleName (denode moduleData.moduleName)
        , prettyExposing (denode moduleData.exposingList)
        , prettyMaybe Pretty.string (denodeMaybe moduleData.command)
        , prettyMaybe Pretty.string (denodeMaybe moduleData.subscription)
        ]


prettyComments : List Comment -> Doc
prettyComments comments =
    List.map Pretty.string comments
        |> Pretty.lines


prettyImports : List Import -> Doc
prettyImports imports =
    List.map prettyImport imports
        |> Pretty.lines


prettyImport : Import -> Doc
prettyImport import_ =
    Pretty.join Pretty.space
        [ Pretty.string "import"
        , prettyModuleName (denode import_.moduleName)
        , prettyMaybe prettyModuleName (denodeMaybe import_.moduleAlias)
        , prettyMaybe prettyExposing (denodeMaybe import_.exposingList)
        ]


prettyExposing : Exposing -> Doc
prettyExposing exposing_ =
    case exposing_ of
        All _ ->
            Pretty.string ".."
                |> Pretty.parens

        Explicit tll ->
            prettyTopLevelExposes (denodeAll tll)
                |> Pretty.parens


prettyTopLevelExposes : List TopLevelExpose -> Doc
prettyTopLevelExposes exposes =
    List.map prettyTopLevelExpose exposes
        |> Pretty.join (Pretty.string ",")


prettyTopLevelExpose : TopLevelExpose -> Doc
prettyTopLevelExpose tlExpose =
    case tlExpose of
        InfixExpose val ->
            Pretty.string val

        FunctionExpose val ->
            Pretty.string val

        TypeOrAliasExpose val ->
            Pretty.string val

        TypeExpose exposedType ->
            case exposedType.open of
                Nothing ->
                    Pretty.string exposedType.name

                Just _ ->
                    Pretty.string exposedType.name
                        |> Pretty.a (Pretty.string "(..)")


prettyDeclarations : List Declaration -> Doc
prettyDeclarations decls =
    List.map prettyDeclaration decls
        |> Pretty.lines


prettyDeclaration : Declaration -> Doc
prettyDeclaration decl =
    case decl of
        FunctionDeclaration fn ->
            prettyFun fn

        AliasDeclaration tAlias ->
            Pretty.string "alias"

        CustomTypeDeclaration type_ ->
            Pretty.string "type"

        PortDeclaration sig ->
            Pretty.string "sig"

        InfixDeclaration infix_ ->
            Pretty.string "infix"

        Destructuring pattern expr ->
            Pretty.string "pattern"


prettyFun : Function -> Doc
prettyFun fn =
    Pretty.lines
        [ prettyMaybe prettyDocumentation (denodeMaybe fn.documentation)
        , prettyMaybe prettySignature (denodeMaybe fn.signature)
        , prettyFunctionImplementation (denode fn.declaration)
        ]


prettyDocumentation : Documentation -> Doc
prettyDocumentation docs =
    Pretty.string docs


prettySignature : Signature -> Doc
prettySignature sig =
    Pretty.string "sig"


prettyFunctionImplementation : FunctionImplementation -> Doc
prettyFunctionImplementation impl =
    Pretty.words
        [ Pretty.string (denode impl.name)
        , prettyArgs (denodeAll impl.arguments)
        , Pretty.string "="
        ]
        |> Pretty.a Pretty.line
        |> Pretty.a (prettyExpression (denode impl.expression))
        |> Pretty.hang 4


prettyArgs : List Pattern -> Doc
prettyArgs args =
    List.map prettyPattern args
        |> Pretty.words


prettyPattern : Pattern -> Doc
prettyPattern pattern =
    Pretty.string "pat"


prettyExpression : Expression -> Doc
prettyExpression expression =
    case expression of
        UnitExpr ->
            Pretty.string "()"

        Application exprs ->
            List.map prettyExpression (denodeAll exprs)
                |> Pretty.lines
                |> Pretty.group

        OperatorApplication symbol direction exprl exprr ->
            [ prettyExpression (denode exprl)
            , Pretty.empty
                |> Pretty.a (Pretty.string symbol)
                |> Pretty.a Pretty.space
                |> Pretty.a (prettyExpression (denode exprr))
            ]
                |> Pretty.lines
                |> Pretty.group

        FunctionOrValue modl val ->
            case modl of
                [] ->
                    Pretty.string val

                _ ->
                    prettyModuleName modl
                        |> Pretty.a dot
                        |> Pretty.a (Pretty.string val)

        IfBlock exprBool exprTrue exprFalse ->
            Pretty.string "if"

        PrefixOperator symbol ->
            Pretty.string "op"

        Operator symbol ->
            Pretty.string "op"

        Integer val ->
            Pretty.string "int"

        Hex val ->
            Pretty.string "hex"

        Floatable val ->
            Pretty.string "float"

        Negation expr ->
            Pretty.string "neg"

        Literal val ->
            Pretty.string val
                |> quotes

        CharLiteral val ->
            Pretty.string "char"

        TupledExpression exprs ->
            Pretty.string "(tuple)"

        ParenthesizedExpression expr ->
            prettyExpression (denode expr)
                |> Pretty.parens

        LetExpression letBlock ->
            Pretty.string "let"

        CaseExpression caseBlock ->
            Pretty.string "case"

        LambdaExpression lambda ->
            Pretty.string "\\lambda"

        RecordExpr recordSetters ->
            Pretty.string "set"

        ListExpr exprs ->
            List.map prettyExpression (denodeAll exprs)
                |> Pretty.lines
                |> Pretty.group
                |> Pretty.sqParens

        RecordAccess expr field ->
            Pretty.string "record.get"

        RecordAccessFunction field ->
            Pretty.a (Pretty.string field) dot

        RecordUpdateExpression expr setters ->
            Pretty.string "[val|set]"

        GLSLExpression val ->
            Pretty.string "glsl"



--== Helpers


prettyMaybe : (a -> Doc) -> Maybe a -> Doc
prettyMaybe prettyFn maybeVal =
    Maybe.map prettyFn maybeVal
        |> Maybe.withDefault Pretty.empty


dot : Doc
dot =
    Pretty.string "."


quotes : Doc -> Doc
quotes doc =
    Pretty.surround (Pretty.char '"') (Pretty.char '"') doc


sqParens : Doc -> Doc
sqParens doc =
    Pretty.surround (Pretty.char '[') (Pretty.char ']') doc
