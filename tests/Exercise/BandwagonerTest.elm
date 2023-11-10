module Exercise.BandwagonerTest exposing (tests)

import Comment exposing (Comment, CommentType(..))
import Dict
import Exercise.Bandwagoner as Bandwagoner
import Review.Rule exposing (Rule)
import Review.Test
import RuleConfig
import Test exposing (Test, describe, test)
import TestHelper


tests : Test
tests =
    describe "BandwagonerTest"
        [ exemplar
        , noRecordUpdate
        , noExtensibleRecord
        , noRecordPatternMatching
        ]


rules : List Rule
rules =
    Bandwagoner.ruleConfig |> .rules |> List.map RuleConfig.analyzerRuleToRule


exemplar : Test
exemplar =
    test "should not report anything for the exemplar" <|
        \() ->
            TestHelper.expectNoErrorsForRules rules
                """
module Bandwagoner exposing (..)

type alias Coach =
    { name : String
    , formerPlayer : Bool
    }

type alias Stats =
    { wins : Int
    , losses : Int
    }

type alias Team =
    { name : String
    , coach : Coach
    , stats : Stats
    }

createTeam : String -> Stats -> Coach -> Team
createTeam name stats coach =
    { name = name, stats = stats, coach = coach }

replaceCoach : Coach -> Team -> Team
replaceCoach newCoach team =
    { team | coach = newCoach }

rootForTeam : { a | stats : Stats } -> Bool
rootForTeam { stats } =
    stats.wins > stats.losses
"""


noRecordUpdate : Test
noRecordUpdate =
    let
        comment =
            Comment "replaceCoach doesn't use record update syntax" "elm.bandwagoner.use_record_update_syntax" Actionable Dict.empty
    in
    test "replaceCoach doesn't use record update syntax" <|
        \() ->
            """
module Bandwagoner exposing (..)

type alias Coach =
    { name : String
    , formerPlayer : Bool
    }

type alias Stats =
    { wins : Int
    , losses : Int
    }

type alias Team =
    { name : String
    , coach : Coach
    , stats : Stats
    }

replaceCoach newCoach team =
    Team team.name newCoach team.coach 
"""
                |> Review.Test.run (Bandwagoner.replaceCoachUsesRecordUpdateSyntax comment)
                |> Review.Test.expectErrors
                    [ TestHelper.createExpectedErrorUnder comment "replaceCoach" ]


noExtensibleRecord : Test
noExtensibleRecord =
    let
        comment =
            Comment "rootForTeam has no extensible record" "elm.bandwagoner.use_extensible_record_signature" Essential Dict.empty
    in
    describe "rootForTeam doesn't use an extensible record in the signature"
        [ test "no signature" <|
            \() ->
                """
module Bandwagoner exposing (..)

type alias Coach =
    { name : String
    , formerPlayer : Bool
    }

type alias Stats =
    { wins : Int
    , losses : Int
    }

type alias Team =
    { name : String
    , coach : Coach
    , stats : Stats
    }

rootForTeam { stats } =
    stats.wins > stats.losses
"""
                    |> Review.Test.run (Bandwagoner.rootForTeamHasExtensibleRecordSignature comment)
                    |> Review.Test.expectErrors
                        [ TestHelper.createExpectedErrorUnder comment "rootForTeam" ]
        , test "wrong signature" <|
            \() ->
                """
module Bandwagoner exposing (..)

type alias Coach =
    { name : String
    , formerPlayer : Bool
    }

type alias Stats =
    { wins : Int
    , losses : Int
    }

type alias Team =
    { name : String
    , coach : Coach
    , stats : Stats
    }

rootForTeam : Team -> Bool
rootForTeam { stats } =
    stats.wins > stats.losses
"""
                    |> Review.Test.run (Bandwagoner.rootForTeamHasExtensibleRecordSignature comment)
                    |> Review.Test.expectErrors
                        [ TestHelper.createExpectedErrorUnder comment "rootForTeam"
                            |> Review.Test.atExactly { start = { row = 21, column = 1 }, end = { row = 21, column = 12 } }
                        ]
        ]


noRecordPatternMatching : Test
noRecordPatternMatching =
    let
        comment =
            Comment "rootForTeam doesn't use pattern matching in argument" "elm.bandwagoner.use_pattern_matching_in_argument" Essential Dict.empty
    in
    test "rootForTeam doesn't pattern matching in the rootForTeam argument" <|
        \() ->
            """
module Bandwagoner exposing (..)

type alias Coach =
    { name : String
    , formerPlayer : Bool
    }

type alias Stats =
    { wins : Int
    , losses : Int
    }

type alias Team =
    { name : String
    , coach : Coach
    , stats : Stats
    }

rootForTeam : { a | stats : Stats } -> Bool
rootForTeam x =
    x.stats.wins > x.stats.losses

"""
                |> Review.Test.run (Bandwagoner.rootForTeamUsesPatternMatchingInArgument comment)
                |> Review.Test.expectErrors
                    [ TestHelper.createExpectedErrorUnder comment "rootForTeam"
                        |> Review.Test.atExactly { start = { row = 21, column = 1 }, end = { row = 21, column = 12 } }
                    ]