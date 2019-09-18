module View.Home exposing (formatBytes, formatDuration, formatSideAreaType, maskedText, selfUrl, viewDate, viewHeader, viewInstance, viewMaybeInstance, viewParseError, viewProgress, viewSideAreaName)

-- TODO: This used to be its own page. Now it's a graveyard of functions that get
-- called from other pages. I should really clean it up and find these a new home.

import Dict
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Mapwatch as Mapwatch exposing (Model, Msg(..))
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Mapwatch.Zone as Zone
import Route
import Time
import View.Icon as Icon
import View.Nav
import View.Setup


viewMaybeInstance : Route.HistoryParams -> Maybe Instance -> Html msg
viewMaybeInstance qs instance =
    case instance of
        Just (Instance.Instance i) ->
            if Zone.isMap i.zone then
                -- TODO preserve before/after
                a [ Route.href <| Route.History { qs | search = Just i.zone }, title i.addr ] [ Icon.mapOrBlank i.zone, text i.zone ]

            else
                span [ title i.addr ] [ text i.zone ]

        Just Instance.MainMenu ->
            span [] [ text "(none)" ]

        Nothing ->
            span [] [ text "(none)" ]


viewInstance : Route.HistoryParams -> Instance -> Html msg
viewInstance qs =
    Just >> viewMaybeInstance qs


time =
    { second = 1000
    , minute = 1000 * 60
    , hour = 1000 * 60 * 60
    , day = 1000 * 60 * 60 * 24
    }


formatDuration : Int -> String
formatDuration dur =
    let
        sign =
            if dur >= 0 then
                ""

            else
                "-"

        d =
            abs <| dur // truncate time.day

        h =
            abs <| remainderBy (truncate time.day) dur // truncate time.hour

        m =
            abs <| remainderBy (truncate time.hour) dur // truncate time.minute

        s =
            abs <| remainderBy (truncate time.minute) dur // truncate time.second

        ms =
            abs <| remainderBy (truncate time.second) dur

        pad0 : Int -> Int -> String
        pad0 length =
            String.fromInt
                >> String.padLeft length '0'

        hpad =
            if h > 0 then
                [ pad0 2 h ]

            else
                []

        dpad =
            if d > 0 then
                [ String.fromInt d ]

            else
                []
    in
    -- String.join ":" <| [ pad0 2 h, pad0 2 m, pad0 2 s, pad0 4 ms ]
    sign ++ String.join ":" (dpad ++ hpad ++ [ pad0 2 m, pad0 2 s ])


viewParseError : Maybe LogLine.ParseError -> Html msg
viewParseError err =
    case err of
        Nothing ->
            div [] []

        Just err_ ->
            div [] [ text <| "Log parsing error: " ++ LogLine.parseErrorToString err_ ]


formatBytes : Int -> String
formatBytes b =
    let
        k =
            toFloat b / 1024

        m =
            k / 1024

        g =
            m / 1024

        t =
            g / 1024

        ( val, unit ) =
            if t >= 1 then
                ( t, " TB" )

            else if g >= 1 then
                ( g, " GB" )

            else if m >= 1 then
                ( m, " MB" )

            else if k >= 1 then
                ( k, " KB" )

            else
                ( toFloat b, " bytes" )

        places n val_ =
            String.fromFloat <| (toFloat <| floor <| val_ * (10 ^ n)) / (10 ^ n)
    in
    places 2 val ++ unit


viewProgress : Mapwatch.Progress -> Html msg
viewProgress p =
    if Mapwatch.isProgressDone p then
        div [] [ br [] [], text <| "Processed " ++ formatBytes p.max ++ " in " ++ String.fromFloat (toFloat (Mapwatch.progressDuration p) / 1000) ++ "s" ]

    else if p.max <= 0 then
        div [] [ Icon.fasPulse "spinner" ]

    else
        div []
            [ progress [ value (String.fromInt p.val), A.max (String.fromInt p.max) ] []
            , div []
                [ text <|
                    formatBytes p.val
                        ++ " / "
                        ++ formatBytes p.max
                        ++ ": "
                        ++ (String.fromInt <| floor <| Mapwatch.progressPercent p * 100)
                        ++ "%"

                -- ++ " in"
                -- ++ String.fromFloat (Mapwatch.progressDuration p / 1000)
                -- ++ "s"
                ]
            ]


viewDate : Time.Posix -> Html msg
viewDate d =
    let
        i =
            d |> ISO8601.fromPosix

        months =
            [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]

        monthNum =
            ISO8601.month i

        m =
            if monthNum < 1 then
                String.fromInt monthNum

            else
                months |> List.drop (monthNum - 1) |> List.head |> Maybe.withDefault (String.fromInt monthNum)

        timestamp =
            String.join " "
                [ m
                , ISO8601.day i |> String.fromInt |> String.padLeft 2 '0'
                , String.join ":"
                    [ ISO8601.hour i |> String.fromInt |> String.padLeft 2 '0'
                    , ISO8601.minute i |> String.fromInt |> String.padLeft 2 '0'
                    ]
                ]
    in
    span [ title (ISO8601.toString i) ]
        [ text timestamp ]


formatSideAreaType : Instance -> Maybe String
formatSideAreaType instance =
    case Zone.sideZoneType <| Instance.unwrap Nothing (Just << .zone) instance of
        Zone.OtherSideZone ->
            Nothing

        Zone.ZanaMission ->
            Just "Zana mission"

        Zone.ElderGuardian guardian ->
            Just <| "Elder Guardian: The " ++ Zone.guardianToString guardian


viewSideAreaName : Route.HistoryParams -> Instance -> Html msg
viewSideAreaName qs instance =
    case formatSideAreaType instance of
        Nothing ->
            viewInstance qs instance

        Just str ->
            span [] [ text <| str ++ " (", viewInstance qs instance, text ")" ]


maskedText : String -> Html msg
maskedText str =
    -- This text is hidden on the webpage, but can be copypasted. Useful for formatting shared text.
    span [ style "opacity" "0", style "font-size" "0", style "white-space" "pre" ] [ text str ]


selfUrl =
    "https://mapwatch.github.io"


viewHeader : Html msg
viewHeader =
    div []
        [ h1 [ class "title" ]
            [ maskedText "["

            -- , a [ href "./" ] [ Icon.fas "tachometer-alt", text " Mapwatch" ]
            , a [ href "#/" ] [ text " Mapwatch" ]
            , maskedText <| "](" ++ selfUrl ++ ")"
            ]
        , small []
            [ text " - automatically time your Path of Exile map clears" ]
        ]
