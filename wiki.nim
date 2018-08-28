import wikibase, wikihtml
import os, system, strutils

# Wiki HTML generator utility

# currently invoke like this:
# wiki <src> <dest>
# eventually this will be the following commands:
# 1. wiki html <src> <dest>     this converts md files to static html wiki
# 2. wiki http <src>            this serves up html from a webserver
# 3. wiki 

if paramCount()==2:
  let src = paramStr(1)
  let dest = paramStr(2)
  let wiki = newWiki( src ) # dest needed here?
  let html = makeHtmlWriter( wiki, dest )
  html.generate()
else:
  echo("Usage:\nwiki <src-dir> <dest-dir>\n\n")



