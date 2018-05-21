module View.Nav exposing (view, viewDebug)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.Route as Route exposing (Route(..))


viewLinks : List ( String, Route ) -> Route -> H.Html msg
viewLinks links active =
    links
        |> List.map (uncurry <| viewLink active)
        |> H.div [ A.class "nav" ]


links : List ( String, Route )
links =
    [ ( "History", HistoryRoot )
    , ( "Legacy", Home )
    ]


view =
    viewLinks links


debugLinks =
    links
        ++ [ ( "Debug", Debug )
           , ( "DumpLines", DebugDumpLines )
           ]


viewDebug =
    viewLinks debugLinks


viewLink : Route -> String -> Route -> H.Html msg
viewLink active label href =
    let
        cls =
            if active == href then
                "active"
            else
                "inactive"
    in
        H.a [ Route.href href, A.class cls ] [ H.text label ]
