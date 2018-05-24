module View.Changelog exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.Route as Route exposing (Route)
import View.Nav
import View.Home exposing (viewHeader)
import Date as Date exposing (Date)


entries : List ( Date, List (List (H.Html msg)) )
entries =
    [ ( ymd "2018/05/24"
      , [ [ H.text "Created this changelog." ]
        , [ H.text "Broke existing urls for search, to prepare for some future changes." ]
        ]
      )
    , ( ymd "2018/05/23"
      , [ [ H.text "Initial release and "
          , H.a [ A.href "https://www.reddit.com/r/pathofexile/comments/8lnctd/mapwatch_a_new_tool_to_automatically_time_your/" ] [ H.text "announcement." ]
          ]
        ]
      )
    ]


view : Route -> H.Html msg
view route =
    H.div []
        [ viewHeader
        , View.Nav.view <| Just route
        , H.ul [] (List.map (uncurry viewEntry) entries)
        ]


viewEntry : Date -> List (List (H.Html msg)) -> H.Html msg
viewEntry date lines =
    H.li [] [ viewDate date, H.ul [] <| List.map (H.li []) lines ]


viewDate : Date -> H.Html msg
viewDate date =
    H.text <| String.join " " [ toString <| Date.year date, toString <| Date.month date, toString <| Date.day date ]


ymd : String -> Date
ymd string =
    case Date.fromString string of
        Ok date ->
            date

        Err err ->
            Debug.crash err
