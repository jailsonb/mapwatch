port module Ports exposing (..)

import Time as Time exposing (Time)


port inputClientLogWithId : String -> Cmd msg


port logline : (String -> msg) -> Sub msg


type alias Progress =
    { val : Int, max : Int, startedAt : Time, updatedAt : Time }


port progress : (Progress -> msg) -> Sub msg