module Elm.Comments exposing (Comment(..), CommentPart(..), DocComment, FileComment)

{-| A component DSL that helps with building comments.

It is useful to have this in a structured way, so that it can be re-flowed by
the pretty printer, and so that an understanding of the layout of the doc tags
can be extracted to order the exposing clause by.

-}


type DocComment
    = DocComment


type FileComment
    = FileComment


type Comment a
    = Comment (List CommentPart)


type CommentPart
    = Markdown String
    | Code String
    | DocTags (List String)


{-| Pretty prints a document comment.

Where possible the comment will be re-flowed to fit the specified page width.

-}
prettyDocComment : Comment DocComment -> Int -> String
prettyDocComment (Comment parts) width =
    List.foldr
        (\part accum -> accum ++ partToString part width)
        ""
        parts


{-| Pretty prints a file comment.

Where possible the comment will be re-flowed to fit the specified page width.

-}
prettyFileComment : Comment FileComment -> Int -> ( String, List (List String) )
prettyFileComment (Comment parts) width =
    List.foldr
        (\part ( strAccum, tagsAccum ) ->
            let
                ( str, tags ) =
                    partToStringAndTags part width
            in
            ( strAccum ++ str, tags :: tagsAccum )
        )
        ( "", [] )
        parts


partToString : CommentPart -> Int -> String
partToString part width =
    case part of
        Markdown val ->
            val

        Code val ->
            "    " ++ val

        DocTags tags ->
            "@doc " ++ String.join ", " tags


partToStringAndTags : CommentPart -> Int -> ( String, List String )
partToStringAndTags part width =
    case part of
        Markdown val ->
            ( val, [] )

        Code val ->
            ( "    " ++ val, [] )

        DocTags tags ->
            ( "@doc " ++ String.join ", " tags, tags )
