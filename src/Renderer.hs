{-# LANGUAGE OverloadedStrings, QuasiQuotes, TemplateHaskell #-}

-- | This module creates functions that take in data and other
-- rendered templates and give another template in return. Note that
-- these templates don't have the routing renderer applied to them for
-- composability reasons/separation of concerns.
module Renderer (ItsaR(..),
                 renderTwoColumn,
                 renderDefault,
                 renderPosts,
                 renderPost,
                 renderTagList,
                 render404) where

import Control.Lens
import Data.List      (sortBy)
import Data.Monoid
import Data.Ord       (comparing)
import Data.Table     (count, group)
import Data.Text      (Text)
import Text.Hamlet    (HtmlUrl, hamlet)

import Application
import Config
import Post.Types
import RelativeHamlet

-- | The datatype representing a route.
data ItsaR = RootR -- ^ The docroot.
           | TagR Text -- ^ Posts related to a tag.
           | PostR Text -- ^ An individual post.

-- | 'Top-level' renderer that puts its arguments in the default layout.
renderTwoColumn :: HtmlUrl ItsaR -- ^ The HTML to show in the left column.
                 -> HtmlUrl ItsaR -- ^ The HTML to show in the right column.
                 -> AppHandler (HtmlUrl ItsaR)
renderTwoColumn leftColumn rightColumn
    = return $ $(hamletRelativeFile "templates/two-column.hamlet")

-- | Render a page using the default right column; i.e., the tag list.
renderDefault :: HtmlUrl ItsaR -> AppHandler (HtmlUrl ItsaR)
renderDefault tpl = do
    postTable <- getPostTable
    blogTitle <- view $ _config._blogTitle
    subtitle <- view _subtitle
    let pageTitle = maybe blogTitle (<> " | " <> blogTitle) subtitle
    body <- renderTwoColumn tpl
        (postTable^@..group Tags .to count & renderTagList)
    return $(hamletRelativeFile "templates/default-layout.hamlet")


-- | Render a series of posts.
renderPosts :: [Post] -> HtmlUrl ItsaR
renderPosts posts = [hamlet|$forall post <- posts
                                            ^{renderPost post}|]

-- | Render an individual post.
renderPost :: Post -> HtmlUrl ItsaR
renderPost post = $(hamletRelativeFile "templates/post.hamlet")

-- | Render the tag list, given a list of (tag, frequency) tuples.
renderTagList :: [(Text, Int)] -> HtmlUrl ItsaR
renderTagList unsorted = $(hamletRelativeFile "templates/tag-list.hamlet")
  where tagList = reverse $ sortBy (comparing snd) unsorted

-- | Render a 404 page.
render404 :: HtmlUrl ItsaR
render404 = $(hamletRelativeFile "templates/404.hamlet")

-- | Get the route referring to a post.
postRouter :: Post -> ItsaR
postRouter post = PostR $ view _slug post
