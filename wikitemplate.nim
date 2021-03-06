let 
  indexTemplate* = """
  <!doctype html>
<html>
  <head>
    <meta charset="UTF-8">  
    <title>$title</title>
    <link rel='stylesheet' href='styles.css' type='text/css' >
  </head>
  <body>
    <div class='wiki-jump-links' id='page-top'>
      $jump_links
    </div>
    <div class='wiki-body'>
      <table style='width:97%'>
        <tbody>
          <td class='wiki-nav' style='border-radius:12px'>
              $navigation
          </td>
          <td style='width:77%'>
              <div class='wiki-index'>    
                $body
              </div>
          </td>
        </tbody>
      </table>
    </div>
  </body>
</html>  """

let 
  pageTemplate* = """
  <!doctype html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>$title</title>
    <link rel='stylesheet' href='styles.css' type='text/css' >
  </head>
  <body>
    <div class='wiki-header'>$header</div>   
    <div class='wiki-body'>    
      $body
    </div>
  </body>
</html> """

let 
  styleCSS* = """
  
/* Global styles */

DIV { line-height: 1.4; font-weight: 400; }
B { font-weight:700; }

.wiki-body { 
  font-family: Verdana, Geneva, Tahoma, sans-serif; 
  font-weight: normal;
  background-color: #eee;
  margin:0em 1em ;
  padding: 1em ;
  border:1px solid #ccc;
}

BUTTON { 
  border:0px; 
  border-radius: 8px;
  padding:15px 8px; 
  vertical-align: middle;
  font-family: 'Trebuchet MS', 'Lucida Sans Unicode', 'Lucida Grande', 'Lucida Sans', Arial, sans-serif;
  font-size:16px;
  background-color: #5D5E60;
  min-width:3em;
  color: white;
  margin:1px 5px;
}

BUTTON.wide {
  min-width:17em;
}

BUTTON:hover {
  background-color: #A39BA8;
  cursor: pointer;
}

BUTTON.selected { background-color: #721817; }

BUTTON.wiki-link { 
  padding:7px; 
  border-radius: 4px; 
  background-color: #22669E;
  font-size:16px;
}

BUTTON.wiki-link:hover { background-color: #1A7AC9; }

A { 
  text-decoration: none; 
  text-transform: uppercase;
}

A.page-index { 
  font-family: Verdana, Geneva, Tahoma, sans-serif; 
  font-weight: 500;
  font-size:14pt;
  color: currentColor;
}

A.prev BUTTON, A.next BUTTON { background-color: #22669E; }


H1 { font-size: 26px; }
H2 { font-size: 23px; font-family:serif; font-weight:bold;  }
H3 { font-size: 18px; font-style: italic; color: darkblue; }
H4 { font-size: 16px;  }
H5 { font-size: 14px; }

.wiki-title { 
  text-align:left; 
  padding:5px; 
  margin-left:0.5em ; 
}
.wiki-text { padding:5px; }

.wiki-header {   
  border-radius: 5px;
  background-color: #91AEC1;
  text-align:center; 
  padding:0.5em; 
  margin:0.25em 5%;
  width:90%;
  font-size:18pt;
  border:1px solid darkgray;
}

.wiki-header A {
  font-size:16pt;
  margin:0px 15px;
}

/* Index Page styles */
.wiki-nav { 
  width:15%; 
  vertical-align: top; 
  padding:1em;
  background-color:#85BDA6; 
}

.wiki-nav > DIV { margin-top:8px; }

.wiki-nav BUTTON { width:17em; }

.wiki-index { 
  width:82%; 
  min-height:800px;
  vertical-align: top;
  background-color: #BEDCFE;
  padding:1em; 
  text-align: center;
  border-radius:12px
}

.wiki-index BUTTON {
  min-width:25em;
}

.wiki-index DIV.row { margin:4px; } 

/* Nice green #C0D7BB */

.wiki-jump-links {
  padding:1em;
  margin-left:5%;
  width:90%;
  margin-bottom: 1em;
  background-color: #91AEC1;
  text-align: center;
  box-shadow: 6px 3px 3px darkgray;
  border-radius:10px
}
.wiki-jump-links A {
  font-family: Verdana, Geneva, Tahoma, sans-serif;
  font-size:18pt;
  padding-right:4px;
  margin:0;
}

.wiki-jump-links BUTTON {
  min-width:3em;
}

/* Wiki Page styles */

.indent1 { margin-left: 1.5em; }
.indent2 { margin-left: 3em; }
.indent3 { margin-left: 4.5em; }
.indent4 { margin-left: 6em; }
.indent5 { margin-left: 7.5em; }

.wiki-table { 
  border:1px solid black; 
  margin:1em; 
  min-width:25%; 
  max-width:85%; 
  box-shadow: 7px 5px 5px darkgray;
  font-family: Arial, Helvetica, sans-serif;
}
TABLE.wide { width: 80%; }

.wiki-table TBODY TR.even { background-color: #dadada; }
.wiki-table TBODY TR.odd { background-color:#eee; }
.wiki-table tbody { color : black; }
.wiki-table THEAD { background-color: darkcyan; }
.wiki-table THEAD TD { color: white; }
.wiki-table TD { padding: 10px; border:1px solid #999; margin:0px;  }

.wiki-bullet, .wiki-nlist {
  margin-left: 0.5em;
  background-color: rgb(161, 197, 219);
  border:2px solid darkgray;
  margin: 5px;
  width:70%;
  font-weight:normal;
}

ul.wiki-bullet li {
  list-style-type: circle;
  padding: 0.5em;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  font-size:large;
}

ol.wiki-nlist li {
  padding: 0.5em;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  font-size:large;
}

.wiki-code { 
  background-color: #222; 
  color: white;
  border:1px solid #aaa;
  margin-right: 2em; 
  font-family: 'Courier New', Courier, monospace;
  font-size: 12.5pt;
  font-weight: normal;
  border: 1px solid black; 
  padding:1em; 
  width:95%;
  white-space: pre-wrap;
  word-wrap: break-word;
  text-align: justify;
  box-shadow: 8px 4px 4px darkgray;
}

.wiki-code >div { line-height:1em; }

.wiki-code >div >pre { 
  line-height: 1.2em;
  display:inline-block;
  margin-left:15px;
}

.wiki-code .gutter { 
  margin-right:4px;
  padding-right:6px;
  line-height: 1.2em;
  clear: left;
  display:inline-block;
  text-align:right;
  width: 3em;
  background-color: #445;
}
  """
