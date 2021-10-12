module Page.Collection exposing (Model, Msg, Data, page, items)

import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import Route
import View exposing (View)
import OptimizedDecoder as Decode exposing (Decoder)
import DataSource exposing (DataSource)
import DataSource.Glob as Glob
import DataSource.File as File
import Html exposing (Html)
import Html.Attributes as Attr
import Path exposing (..)


type alias Model =
    ()


type alias Msg =
    Never

type alias RouteParams =
    { }

page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }






type alias Data =
    {
        title : String,
        items : List Item
        
    }

type alias Item = 
    { filePath : String
    , slug : String
    , title : String
    }

data : DataSource Data
data =
    DataSource.map2 (\a b -> {
        title = a,
        items = b
    }) pageDecoder items
    
pageDecoder : DataSource String
pageDecoder = File.onlyFrontmatter (Decode.field "title" Decode.string) "site/index.md"


items :  DataSource (List Item)
items =
    Glob.succeed
        (\filePath slug ->
            { filePath = filePath
            , slug = slug
            }
        )
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "site/collection/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource
        |> DataSource.map
            (List.map
                (\item ->
                    File.onlyFrontmatter 
                    (postFrontmatterDecoder item.filePath item.slug ) 
                    item.filePath
                )
            )
        |> DataSource.resolve


postFrontmatterDecoder : String -> String -> Decoder Item
postFrontmatterDecoder filePath slug =
    Decode.map3 Item
        (Decode.succeed filePath)
        (Decode.succeed slug)
        (Decode.field "title" Decode.string)


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = "Collection"
    , body = [
        Html.ul [] (List.map (\item -> 
            Html.li [] [
                Html.a [Attr.href <| String.join "/" [Path.toRelative static.path, item.slug]] [Html.text item.title]
                ]) static.data.items
            )
        ]
    }


