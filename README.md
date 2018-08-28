# wiki
A wiki html generator in Nim ( v 0.18.0 )

From a single exe, will generates static site from a set of markdown-like files.

(Probably not useful to many, I made it for my own use)

After installing nim, to Build:

nim c wiki.nim

an executable will be produced (wiki.exe on windows).

To generate pages:

wiki  <src-dir>  <dest-dir>

This tool was my attempt to stop using wikipad, so I exported those wiki files and parsed them into the following format:

A page is simply a file with a md extension.  It uses non-standard markdown( explained below ).  

A page can be a member of one or more folders as a way to organize your pages.

Features:



Set the folders for a page
```
@@ Folder1 Folder2
```

Headers
```
++ Header 1 (largest)
+++ Header 2
++++ Header 3
+++++ Header 4
++++++ Header 5
```
Lists:
```
**
Bullet List
Of Items
**

## 
Numbered List
Here
##
```

Tables:
```
== This | Is | A | Table | Header
These | Are | Table | Rows | ...
==
```

Code blocks:
```
--
Code block
--
```

Inline formatting:

Links to other pages: `[Page Name]`

External links:`[Github|http://github.com]`
`*Bold text between asterisks*`
`_Text inside underscores will be italic_`
```
`Text between backticks can have any * special _ characters _ * [hello] `
```
