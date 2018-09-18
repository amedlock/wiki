import os, strutils, tables, sequtils, deques, parseutils;
from ospaths import joinPath
from algorithm import sorted

## Wiki Data Model and Parsing Code

# You could theoretically support multiple dialects of wiki files
# which fit the following model Wiki -> Page -> Chunk -> Span

type 
  Page* = ref object
    wiki* : Wiki
    name* : string
    filename : string  
    pos*: int           # position alphabetically within its wiki
    
  Wiki* = ref object 
    src_path* : string
    pages*: OrderedTable[string,Page]
    lc_names*: OrderedTable[string,Page]
    files*: OrderedTable[string,Page]

  # Base chunk, which is a block of N lines of text
  Chunk* = ref object of RootObj
    margin*: int
    pos*: int

  # single line of styled text
  Text* = ref object of Chunk
    spans*: Span

  # line of text which is subdued 
  Comment* = ref object of Chunk
    text*: string

  # block of unstyled text, typically source code
  Code* = ref object of Chunk
    lang*: string
    lines*: seq[string]

  RowChunk* = ref object of Chunk
    cells*: seq[Cell]

  TableChunk* = ref object of Chunk
    header*: RowChunk
    body*: seq[RowChunk]

  Cell* = ref object of Chunk
    spans*: Span

  Title* = ref object of Chunk
    size*: 1..5
    text*: Text

  Bullet* = ref object of Chunk
    items*: seq[Text]

  NList* = ref object of Chunk
    items*: seq[Text]


  # missing strikeout style
  SpanStyle* = enum
    Raw,        # unformatted text 
    Bold,       
    Italic,     
    Link        

  Span* = ref object
    styles*: set[SpanStyle]
    text*: string
    next*: Span

  # Parser object for my wiki dialect
  Parser* = ref object 
    page*: Page
    margin*: int
    chunks*: seq[Chunk]
    folders*: seq[string]


proc debug*( s : Span ) =
  if s!=nil: 
    echo("Span( $1 '$2' )".format( s.styles, s.text ))
    debug( s.next )
    

proc parse_spans*( line : string, styles: set[SpanStyle] = {} ) : Span


# create a new page 
proc make_page( wiki:Wiki, name, filename : string ) : Page =
  assert( not filename.contains(":") ) 
  result = Page( wiki:wiki, name : name, filename: filename )
  wiki.pages[name] =  result 
  wiki.lc_names[name.replace("_").toLowerAscii] = result

proc make_text( txt: string ) : Text = Text( spans: txt.parse_spans() )

proc make_code(lang: string) : Code = Code(lang:lang, lines: @[])

proc make_comment(txt:string) : Comment = Comment(text: txt)

proc make_row(): RowChunk = RowChunk( cells: @[] )

proc make_table() : TableChunk = TableChunk( body: @[] )

proc add_cell( row: RowChunk, txt :string ) =
  row.cells.add( Cell(spans: txt.parse_spans() ) )

proc add( tbl: TableChunk, tr: RowChunk ) =
  tbl.body.add( tr )

proc make_bullet( ) : Bullet = Bullet(items: @[])

proc make_nlist( ) : NList = NList(items: @[])

proc add( bullet : Bullet, txt: string ) =
  bullet.items.add( make_text(txt))

proc add( nlist : NList, txt: string ) =
  nlist.items.add( make_text(txt))

proc make_title( txt : string, sz = 1 ) : Title = Title( size: sz, text: make_text(txt))


# find page alphabetically after the one passed in 
proc next*( p : Page ) : Page = 
  for p2 in p.wiki.pages.values():
    if p2.pos == p.pos + 1:
      result = p2
      break

# find page alphabetically before the one passed in 
proc prev*( p : Page ) : Page = 
  for p2 in p.wiki.pages.values():
    if p.pos == p2.pos + 1:
      result = p2
      break
    
# Change a filename into a normalized page name
proc sanitize*( s : string, sep = "_" ) : string = 
  let toks = s.split( AllChars - (Letters+Digits)).filterIt( not it.isNilOrEmpty )
  result = toks.join(sep)

# scan files in the src path for wiki *.md files
proc scan_files*( wiki: Wiki ) =
  wiki.lc_names.clear()
  wiki.files.clear()
  wiki.pages.clear()  
  for fname in walkFiles(joinPath(wiki.src_path, "*.md")):
    let (_, name, _) = ospaths.splitFile( fname )
    let sname = name.sanitize()
    discard wiki.make_page( sname, name & ".md" )
  for index,name in  toSeq(wiki.pages.keys).sorted( cmpIgnoreCase):
    wiki.pages[name].pos = index


# create a new Wiki
proc newWiki*( src: string ) : Wiki = 
  if not dirExists( src ):
    raise newException(IOError, "Could not find source directory:$1".format(src) )
  result = Wiki(  src_path: src, 
                  pages: initOrderedTable[string,Page]() ,
                  lc_names : initOrderedTable[string,Page]() )
  result.scan_files()


# find a page by name, tries to allow for some error, should use levenstein distance...
proc lookup*(wiki: Wiki, name: string) : Page = 
  let safe = name.sanitize()
  let short = name.sanitize("").toLowerAscii
  if wiki.pages.hasKey(safe): 
    result = wiki.pages[safe]
  elif wiki.lc_names.hasKey( short ):
    result = wiki.lc_names[short]


# ----------------- Chunk Parsing code -----------------

# add a chunk to a PageParser
proc add_chunk*( p: Parser, chunk: Chunk ) =
  chunk.margin = p.margin
  chunk.pos = len(p.chunks)
  p.chunks.add( chunk )


## ----------------- Span parsing code -----------------

proc len*( s : Span ): int = 
  if s!=nil: 
    result = 1 + len(s.next)


proc makeSpan( text: string, styles: set[SpanStyle]) : Span =
  if text==nil :
    return nil
  new(result)
  result.styles = styles
  result.text = text

const Specials = {'*', '_', '`', '['}

proc parse_inner( line : string, pos: int, styles: set[SpanStyle] = {} ) : Span

proc parse_raw( line : string, pos: int, styles: set[SpanStyle] ) : Span =
  var last = line.find('`', pos)
  let rawStyle = styles + { SpanStyle.Raw }
  if last < 0:
    return makeSpan(line, rawStyle)
  else:
    if last-1 >= pos:
      result = makeSpan(line[pos .. last-1], rawStyle )
    if last < len(line)-1:
      result.next = line.parse_inner( last+1, styles )

proc parse_link( line : string, pos: int, styles: set[SpanStyle] ) : Span =
  var last = line.find(']', pos+1 )
  let linkStyle = styles + { SpanStyle.Link }
  if last < 0 or last==pos+1:
    result = line.parse_inner( pos+1, styles );
    if result!=nil: result.text = '[' & result.text # hacky but works
  else:
    result = makeSpan(line[pos .. last-1], linkStyle )
    if last < len(line)-1:
      result.next = line.parse_inner( last+1, styles )

proc toggle( styles: set[SpanStyle], s : SpanStyle ) : set[SpanStyle] = 
  if s in styles:
    return styles - {s}
  else:
    return styles + {s}

proc parse_inner( line : string, pos: int, styles: set[SpanStyle] = {} ) : Span =
  let next = line.find(Specials, pos)
  if next<0:
    return makeSpan(line[pos..line.len-1], styles)
  result = makeSpan( line[pos..next-1], styles )
  if line[next]=='*':
    result.next = line.parse_inner( next+1, styles.toggle( SpanStyle.Bold) )
  elif line[next]=='_':
    result.next = line.parse_inner( next+1, styles.toggle( SpanStyle.Italic) )
  elif line[next]=='`':
    result.next = line.parse_raw(next+1, styles )
  elif line[next]=='[':
    result.next = line.parse_link(next+1, styles)


# Parse text into a linked list of spans with zero or more styles
proc parse_spans*( line : string, styles : set[SpanStyle] ) : Span =
  if line==nil: return nil
  return line.parse_inner( 0, styles )


## ----------------- Chunk parsing code -----------------

# skip some number of characters of s
proc skip( s: string, n : int ) : string =
  if s==nil or (len(s) <= n): result = ""
  else: result = s[n..s.len-1]


# changes the current identation 
proc indent*( p : Parser, n : int ) =
  p.margin = max( min( n + p.margin, 5 ) , 0 )
    


# remove (and return) lines from "lines" until the end or a prefix is seen
proc parse_until( lines: var Deque[string], prefix: string ) : seq[string] =
  result = @[]
  while len(lines)>0:
    var t = lines.popFirst()
    if t.startsWith(prefix):
      break
    else:
      result.add( t )

# parse | delimited cells for table rows
proc parse_cells( row: RowChunk, txt : string ) =
  let items : seq[string] = txt.split("|").mapIt( it.strip() )
  for value in items:
    row.add_cell( value )

# parse a table with optional header row
proc parse_table( p:Parser, head : string, lines: var Deque[string] ) =
  let table = make_table()
  p.add_chunk( table )
  if head!=nil and not head.strip().isNilOrEmpty:
    table.header = make_row()
    table.header.parse_cells(head)
  table.body = @[]
  while len(lines)>0:
    let t = lines.popFirst()
    if t.startsWith("=="):
      break
    let tr = make_row()
    tr.parse_cells( t )
    table.add( tr )


# parse all chunks in the passed lines
proc parse_chunks( p: Parser, lines: var Deque[string] ) =
  while len(lines)>0:
    var t = lines.popFirst()
    if t.startsWith("//"):
      p.add_chunk( make_comment(t.skip(2)) )
    elif t.startsWith("@@"):
      p.folders = skip(t,2).split().filterIt( not it.isNilOrEmpty )
    elif t.startsWith(">>"):
      p.indent(t.count(">")-1)
    elif t.startsWith("<<"):
      p.indent( -(t.count("<")-1) )
    elif t.startsWith("--"):
      var code = make_code( t.skip(2) )
      code.lines = lines.parse_until("--")
      p.add_chunk(code)
    elif t.startsWith("**"):
      var bullet = make_bullet()
      for it in lines.parse_until("**"):
        bullet.add( it )
      p.add_chunk(bullet)
    elif t.startsWith("##"):
      var nlist = make_nlist()
      for it in lines.parse_until("##"):
        nlist.add( it )
      p.add_chunk(nlist)
    elif t.startsWith("++"):
      var 
        pos = 2
        size = 1
      while pos < len(t) and size < 5 and t[pos]=='+':
        if t[pos]!='+':
          break
        else:
          inc(pos)
          inc(size)
      p.add_chunk( make_title( t.skip(pos), size ) )
    elif t.startsWith("=="):
      p.parse_table(t.skip(2), lines)
    else:
      p.add_chunk( make_text(t))

proc parse*( p: Page ) : Parser =
  result = Parser( page: p, margin:0, chunks: @[], folders: @[] )
  var content = readFile( joinPath( p.wiki.src_path, p.filename ) )
  if content!=nil:
    var lines = initDeque[string]()
    for it in content.splitLines():
      lines.addLast(it)
    result.parse_chunks( lines )



