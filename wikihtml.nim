import tables, strutils, sequtils, parseutils, strformat, strtabs, sets, os;
import wikibase, wikitemplate

## Wiki HTML generation Code

# let
#   pageTemplate = $readFile(joinPath( getAppDir(), "page.html") )
#   indexTemplate = $readFile( joinPath( getAppDir(), "index.html"))

type
  Markup = ref object of RootObj

  CData = ref object of Markup
    value : string 

  Tag* = ref object of Markup
    name : string
    classes: seq[string]
    attrs: Table[string,string]
    child: seq[Markup]

  HtmlWriter* = ref object
    wiki : Wiki
    dest_path : string
    parsers : Table[string,Parser]
    folders: Table[string,WikiFolder] # folder_name -> WikiFolder
    current: Parser

  WikiFolder* = ref object
    name : string
    pages: HashSet[string]

  WikiPage* = ref object
    parser: Parser
    title: string
    header: string
    body: string

  IndexPage* = ref object
    wiki: HtmlWriter
    title: string 
    jump_links : seq[string]
    folders: seq[string]
    navigation: string
    body: string


proc escape_html*( s : string ) : string = 
    s.multiReplace( ("<", "&lt;"),  (">", "&gt;"), 
                    ("&", "&amp;"), ("\"", "&quot;") )

proc add*( t : Tag, val : Markup ) : Tag
proc add*( t : Tag, val : string ) : Tag
                    

proc make_tag*( k : string ) : Tag = 
  result = Tag(name:k, child: @[], attrs: initTable[string,string]() )

proc make_tag*( prev: Tag, k : string ) : Tag = 
  result = make_tag(k)
  if prev!=nil:
    discard prev.add( result )


method `$`*( m : Markup ) : string {.base.} = ""

method `$`*( cdata: CData ) : string = cdata.value

method `$`*( t : Tag ) : string = 
  var attr_list : seq[string] = @[]
  if t.classes.len>0:
    attr_list.add( "class='$1'".format( t.classes.join(" ")))
  for k,v in t.attrs:
    attr_list.add( "$1='$2'".format(k,v) )
  var content : string = t.child.mapIt( $it ).join("")
  if len(attr_list)==0: 
    return "<$1>$2</$1>".format( t.name, $content )
  return "<$1 $2>$3</$1>".format( t.name, attr_list.join(" "), content )


proc prop*( tag:Tag, k, v : string ) : Tag =
  tag.attrs[k] = v
  return tag


proc add*( t : Tag, val : string ) : Tag =
  if val.len>0:
    t.child.add( CData(value:val) )
  return t

proc add*( t : Tag, val : Markup ) : Tag =
  if val!=nil:
    t.child.add( val )
  return t
 

proc add_class*( t : Tag, cls : string ) : Tag =
  if cls.len==0:
    return t
  var s = cls.strip()
  if not t.classes.contains(s):
    t.classes.add( s )
  return t

proc button_link*( href , label : string ) : Tag =
  let btn = "button".make_tag.prop("type","button").add( label )
  result = make_tag("a").prop("href", href).add( btn )

proc wide_button*( href, label : string ) : Tag =
  let btn = make_tag("button").prop("type","button").add_class("wide").add( label )
  result = make_tag("a").prop("href",href).add( btn );

proc wiki_link*( href, label : string ) : Tag =
  result = make_tag("a").prop("href",href)
  discard result.make_tag("button").prop("type", "button").add_class("wiki-link").add( label )
  if href.startswith("http"): discard result.prop("target", "_blank")  

proc makeHtmlWriter*( w : Wiki, dest: string ) : HtmlWriter =
  result = HtmlWriter( wiki: w, dest_path: dest, parsers: initTable[string,Parser](), current:nil )
  result.folders = initTable[string,WikiFolder]()

proc makeWikiFolder( name : string ) : WikiFolder =
  new(result)
  result.name = name
  result.pages = initSet[string](32)

proc add( folder: WikiFolder, name : string ) =
  incl(folder.pages, name)

proc get_folder( writer: HtmlWriter, name : string ) : WikiFolder =
  if writer.folders.hasKey( name ):
    result = writer.folders[name]
  else:
    result = makeWikiFolder( name )
    writer.folders[name] = result

proc find_page( writer: HtmlWriter, name : string ) : Page = 
  result = writer.wiki.lookup(name)
  if result==nil: 
    echo "Could not find Link($1) on Page($2) " % [name, writer.current.page.name]

proc write_index(writer: HtmlWriter, filename, title, navigation, body, jump_links : string ) =
  let vars = newStringTable( {"title":title, "body": body, 
                              "navigation": navigation, "jump_links": jump_links } )
  writeFile( joinPath( writer.dest_path, filename), indexTemplate % vars )

proc write_page( writer: HtmlWriter, filename, title, body, header : string ) =
  let vars = newStringTable({"title": title, "header": header, "body" : body })
  writeFile( joinPath(writer.dest_path,filename), pageTemplate % vars )
  
proc add_folder( writer:HtmlWriter, name, pname: string ) =
  writer.get_folder(name).add( pname )


# sets the indent on a tag based on chunk's margin value
proc indent( t : Tag, ch: Chunk ) : Tag =
  if ch.margin > 0:
    discard t.add_class("indent$1".format(ch.margin))
  return t

proc content_to_html( writer: HtmlWriter, content: string ) : string;

method to_html( writer:HtmlWriter, chunk: Chunk ) : string {.base.} = "<!-- Not implemented -->"

method to_html( writer:HtmlWriter, comment: Comment ) : string = "<!-- $1 -->".format( comment.text )

method to_html( writer:HtmlWriter, text: Text ) : string = 
  result = "<div>$1</div>".format( writer.content_to_html( text.content ))

method to_html( writer:HtmlWriter, cell: Cell ) : string = 
  result = writer.content_to_html( cell.content )

method to_html( writer:HtmlWriter, code: Code ) : string =
  let tag =  make_tag("pre").add_class("wiki-code").indent(code)
  for i,x in code.lines:
    let gutter = "span".make_tag.add_class("gutter").add( $(i+1) )
    let pre = "code".make_tag.add( x.escape_html )
    let row = "div".make_tag.add( gutter ).add( pre )
    discard tag.add( row )
  return $tag

method to_html( writer:HtmlWriter, table: TableChunk ) : string =
  let tag = make_tag("table").add_class("wiki-table").indent(table)
  if table.header!=nil:
    let tr = tag.make_tag("thead").make_tag("tr")
    for x in table.header.cells:
      discard tr.make_tag("td").add( $writer.to_html(x) )
  for i,row in table.body:
    let cell_size = formatFloat( 100.0 / float(len(row.cells)), ffDecimal, 2 )
    let width_str = "width:$1%".format(cell_size)    
    let tr = tag.make_tag("tr").add_class( ["odd", "even"][i mod 2] )
    for cell in row.cells:
      discard tr.make_tag( "td" ).prop("style", width_str).add( writer.to_html(cell) )
  return $tag

method to_html( writer:HtmlWriter, bullet: Bullet ) : string =
  let tag = make_tag("ul").add_class("wiki-bullet").indent(bullet)
  for it in bullet.items:
    discard tag.add( make_tag("li").add( writer.to_html(it) ))
  return $tag

method to_html( writer:HtmlWriter, nlist: NList ) : string =
  let tag = make_tag("ol").add_class("wiki-nlist").indent(nlist)
  for it in nlist.items:
    discard tag.add( make_tag("li").add( writer.to_html(it) ))
  return $tag

method to_html( writer:HtmlWriter, title: Title ) : string =
  let tag = make_tag("h$1".format(title.size)).indent(title)
  return $tag.add( writer.to_html( title.text ) )


## ----------------- Content To Html -----------------

const Specials = {'*', '_', '`', '['}

const HtmlChars = {'<': "&lt;",
                   '>': "&gt;",
                   '"': "&quot;",
                   '&': "&amp;", 
                   '\'': "&apos;" }.toTable

proc parse_link( pos: var int, text: string ) : string = 
  let sz = text.parseUntil( result, ']', pos ) 
  if sz>0:
    pos += (sz+1)

proc parse_raw( pos: var int, text: string ) : string = 
  let sz = text.parseUntil( result, '`', pos )
  if sz>0:
    pos += (sz+1)


proc is_external_link( s : string ) : bool =
  result = s.startsWith("http://") or s.startsWith("https://")
    
proc create_link( writer: HtmlWriter, txt : string ) : string =
  if txt.len==0:
    return "<a href='#'>(Empty Link)</a>"
  var 
    label = txt.strip()
    href = label
  if label.contains( '|' ):
    let tok = label.split('|',1)
    label = tok[0].strip()
    href = tok[1].strip()
  if not href.toLowerAscii.is_external_link:
    let page = writer.find_page( href )
    if page==nil:
      return $make_tag("[$1]".format( label ) ) # give up
    else:
      href = page.name & ".html"
  return $wiki_link(href, escape_html(label))

proc close_all_tags( styles: set[char]) : string = 
  if '*' in styles:
    result &= "</b>"
  if '_' in styles:
    result &= "</i>"

proc gen_style_tag( ch: char, styles: var set[char], openTag, closeTag: string ) : string =
  if ch in styles:
    excl( styles, ch )
    result = closeTag
  else:
    incl( styles, ch )
    result = openTag

proc content_to_html( writer: HtmlWriter, content: string ) : string = 
  result = ""
  var styles : set[char] = {}
  var pos = 0
  while pos < content.len:
    let ch = content[pos]
    inc(pos)
    if ch=='[':
      let linkText = parse_link( pos, content )
      result &= $writer.create_link( linkText )
    elif ch=='`':
      let rawText = parse_raw( pos, content )
      result &= styles.close_all_tags()
      result &= $make_tag("span").add( rawText.escape_html )
    elif ch=='*':
      result &= gen_style_tag( ch, styles, "<b>", "</b>")
    elif ch=='_':
      result &= gen_style_tag( ch, styles, "<i>", "</i>")
    elif ch in HtmlChars:
      result &= HtmlChars[ch]
    else:
      result &= ch


proc generate_html( writer:HtmlWriter, page: Page ) : string = 
  var parser = page.parse()
  for name in parser.folders:
    writer.add_folder( name, page.name )
  writer.current = parser
  var items = parser.chunks.mapIt( writer.to_html(it) )
  writer.current = nil
  result = items.join("\n")

proc generate_index*( writer: HtmlWriter )

proc generate*( writer: HtmlWriter ) =  
  if not dirExists( writer.dest_path ):
    createDir( writer.dest_path )
  writeFile( joinPath(writer.dest_path, "styles.css"), styleCSS )
  writer.folders.clear()
  let index_link = wide_button("index.html", "Back to Index")
  for page in writer.wiki.pages.values:
    echo("Generating page:$1".format( page.name ))
    var links : seq[Tag] = @[]
    let pre = page.prev()
    if pre!=nil:
      links.add( wide_button(pre.name & ".html", pre.name).add_class("prev"))
    links.add( index_link )
    let nxt = page.next()
    if nxt!=nil:
      links.add( wide_button(nxt.name & ".html", nxt.name).add_class("next"))
    let content = writer.generate_html(page)
    let filename = page.name & ".html"
    let backlink = links.mapIt( $it ).join("")
    writer.write_page( filename, page.name, content, backlink )
  writer.generate_index()

proc jump_key( s : string ) : string =
  const hash = "#";
  if s[0] in Letters:
    return s[0..0].toLowerAscii
  else:
    return hash

iterator jump_characters(writer:HtmlWriter): string =
  # Returns all the leading characters for any pages in the wiki (sorted) 
  var seen : set[char]
  for name in writer.wiki.pages.keys():
    let jkey = jump_key( name )
    if not seen.contains( jkey[0] ):
      incl(seen, jkey[0] )
      yield jkey.toUpperAscii

proc jump_links(writer:HtmlWriter): string =
  # List of jump links for all wiki pages 
  result = ""
  for x in writer.jump_characters():
    result &= $button_link("index.html#$1-section".format(x), x )

proc folder_links( writer: HtmlWriter ) : string =
  # Return a list of links to folder pages in this wiki 
  result = ""
  for name in writer.folders.keys():
    let btn = button_link("_folder_$1.html".format(name), name )
    result &= $( "div".make_tag.add_class("row").add( btn ) )

proc generate_folder( writer: HtmlWriter, folder: WikiFolder, all_folders: string ) =
  # Writes a folder link page 
  let filename = "_folder_$1.html".format( folder.name )
  var navlinks = $button_link("index.html", "All Pages") & all_folders
  var links = ""
  for name in folder.pages:
    links &= $"div".make_tag.add_class("row").add( $button_link("$1.html".format(name), name ) )
  let title = "Folder $1".format( folder.name )
  writer.write_index( filename, title, navlinks, links, writer.jump_links() )


# Write the index.html file and any folder index files
proc generate_index*( writer: HtmlWriter ) =
  let all_folders = writer.folder_links()
  for folder in writer.folders.values:
    writer.generate_folder( folder, all_folders )
  var links = ""  
  var letters : set[char] = {}
  for name,page in writer.wiki.pages.pairs():
    let filename = "$1.html".format( name )
    let jkey = jump_key( name )
    var id = ""
    if not letters.contains(jkey[0]):
      id = "$1-section".format( jkey.toUpperAscii )
    let row = make_tag("div").add_class("row").prop("id", id).add( wide_button(filename, name))
    links.add( $row )
  writer.write_index( "index.html", "Wiki Index", all_folders, links, writer.jump_links())

