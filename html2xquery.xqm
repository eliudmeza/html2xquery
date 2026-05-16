(:~
 : Modulo para convertir HTML5 Doc a XQuery 4.0 usando constructores computados 
 : A veces me he topado con casos que leer un doc html5 ya sea despues de un
 : http:send-request o html parser y generar un error 
 : ya sea por las entidades o {, &, o } etc así que generé un módulo para que en BaseX
 : pueda ser leido sin error y poder seguir usando el doc como parte del template
 : 
 : This Source Code Form is subject to the terms of the Mozilla Public
 : License, v. 2.0. If a copy of the MPL was not distributed with this
 : file, You can obtain one at http://mozilla.org/MPL/2.0/.
 :
 : Copyright (c) 2026 Eliud Santiago Meza y Rivera
 : 
 :)

(: --- Convertidor de HTML5  a constructores computados de xquery--- :)

xquery version "4.0" encoding "utf-8";
module namespace xqrsrc = 'anteac/xquerysource';

(: --- Configuración de path --- :)
declare variable $xqrsrc:HTML_INPUT_PATH := 'C:/Program Files (x86)/BaseX/webapp/anteac/index.html';
declare variable $xqrsrc:ENTITIES_LOCAL_PATH := "entities.json"; 
declare variable $xqrsrc:ENTITIES_URL := "https://html.spec.whatwg.org/entities.json";

(: 
   1. CARGA DEL DICCIONARIO DE ENTIDADES
   Corregido para evitar el error XPTY0004 asegurando que siempre haya un mapa, es un dolor de cabeza luego
:)
declare %private variable $xqrsrc:HTML_MAP := 
  let $json-text := 
    try {
      if (file:exists($xqrsrc:ENTITIES_LOCAL_PATH)) then file:read-text($xqrsrc:ENTITIES_LOCAL_PATH)
      else 
        let $fetched := fetch:text($xqrsrc:ENTITIES_URL)
        return (file:write($xqrsrc:ENTITIES_LOCAL_PATH, $fetched), $fetched)[2]
    } catch * { "{}" } (: manda un fallback a JSON vacío si hay error de red o archivo :)
  
  let $json := parse-json($json-text)
  return 
    if ($json instance of map(*)) then $json
    else map { } (: Garantiza que siempre sea un mapa y evitar otro tipo de dato :);

(: 2. DECODIFICADOR DE ENTIDADES HTML5 :)
declare %private function xqrsrc:decode-html($text as xs:string) as xs:string {
  (: El regex busca patrones de entidades comunes en HTML :)
  let $regex := "&amp;([a-zA-Z0-9]+;?|#[0-9]+;|#x[0-9a-fA-F]+;)"
  return analyze-string($text, $regex)
    /* => (function($parts) {
      string-join(
        for $part in $parts
        return typeswitch($part)
          case element(fn:non-match) return string($part)
          case element(fn:match) return
            let $entity-name := "&amp;" || $part/fn:group
            (: El mapa de WHATWG tiene la clave completa incluyendo el & y el ; :)
            let $match := $xqrsrc:HTML_MAP?($entity-name)
            return 
              if (exists($match)) then $match?characters
              else if (starts-with($part/fn:group, "#x")) then 
                char(fold-left(
                  string-to-codepoints(
                    upper-case(substring($part/fn:group, 3, string-length($part/fn:group)-3))
                  ), 0, 
                  function($a, $b) { 
                    $a * 16 + (if ($b gt 64) then $b - 55 else $b - 48) 
                  }))
              else if (starts-with($part/fn:group, "#")) then 
                char(xs:integer(substring($part/fn:group, 2, string-length($part/fn:group)-2)))
              else $entity-name (: Si no existe en el mapa, se deja como está :)
          default return ""
      )
    })()
};

(: 3. ESPACE PARA CÓDIGO FUENTE (Protección importante para xquery:eval) :)
declare function xqrsrc:escape-for-eval($text as xs:string) as xs:string {
  $text 
    => replace("'", "''")            (: Escape de comilla simple para literal de XQuery :)
    => replace("&amp;", "&amp;amp;") (: Escape de & para que el parser de eval() no busque entidades :)
};

(: 4. RENDER RECURSIVO ESTILO XQUERY 3.1:)
declare function xqrsrc:render($nodes as node()*, $level as xs:integer) as xs:string* {
  let $indent := string-join(for $i in 1 to $level return "  ", "")
  for $node in $nodes
  return typeswitch($node)    
    case element() return
      let $name := local-name($node)
      let $is-script := $name = "script"      
      let $attrs := for $attr in $node/@*
                    let $val := xqrsrc:decode-html(string($attr))
                    return $indent || "  attribute { '" || local-name($attr) || "' } { '" || xqrsrc:escape-for-eval($val) || "' }"      
      let $children := 
        if ($is-script) then
          let $js := xqrsrc:decode-html(string-join($node/text(), ""))
          return $indent || "  '<![CDATA[" || xqrsrc:escape-for-eval($js) || "]]>'"
        else 
          xqrsrc:render($node/node(), $level + 1)      
      let $content := string-join(($attrs, $children), ",&#10;")
      return 
        if ($content = "") then $indent || "element { '" || $name || "' } { }"
        else $indent || "element { '" || $name || "' } {&#10;" || $content || "&#10;" || $indent || "}"
    case text() return
      let $txt := xqrsrc:decode-html(string($node))
      return if (normalize-space($txt) = "") then ()
             else $indent || "'" || xqrsrc:escape-for-eval($txt) || "'"
    case comment() return
      let $comm := xqrsrc:decode-html(string($node))
      return $indent || "comment { '" || xqrsrc:escape-for-eval($comm) || "' }"
    default return ()
};

(: 4. RENDER RECURSIVO ESTILO XQUERY 4.0:)
declare function xqrsrc:render-4($nodes as node()*, $level as xs:integer) as xs:string* {
  let $indent := string-join(for $i in 1 to $level return "  ", "")
  for $node in $nodes
  return typeswitch($node)    
    case element() return
      let $name := local-name($node)
      let $is-script := $name = "script"      
      let $attrs := for $attr in $node/@*
                    let $val := xqrsrc:decode-html(string($attr))
                    return $indent || "  attribute #" || local-name($attr) || " { '" || xqrsrc:escape-for-eval($val) || "' }"      
      let $children := 
        if ($is-script) then
          let $js := xqrsrc:decode-html(string-join($node/text(), ""))
          return $indent || "  '<![CDATA[" || xqrsrc:escape-for-eval($js) || "]]>'"
        else 
          xqrsrc:render-4($node/node(), $level + 1)      
      let $content := string-join(($attrs, $children), ",&#10;")
      return 
        if ($content = "") then $indent || "element { '" || $name || "' } { }"
        else $indent || "element #" || $name || " {&#10;" || $content || "&#10;" || $indent || "}"
    case text() return
      let $txt := xqrsrc:decode-html(string($node))
      return if (normalize-space($txt) = "") then ()
             else $indent || "'" || xqrsrc:escape-for-eval($txt) || "'"
    case comment() return
      let $comm := xqrsrc:decode-html(string($node))
      return $indent || "#comment { '" || xqrsrc:escape-for-eval($comm) || "' }"
    default return ()
};

(: --- EJECUCIÓN --- :)
declare function xqrsrc:file-to-xquery($file-path) {
  if (not(file:exists($file-path))) then 
    error(xs:QName("FILE-ERROR"), "No se encontró el archivo: " || $file-path)
  else
    let $raw-html := file:read-text($file-path)
    let $doc := html:parse($raw-html, map { 'nons': true() })
    let $xquery-source := xqrsrc:render($doc/*:html, 0)
    return xquery:eval(string-join($xquery-source, "&#10;"))  
};

declare function xqrsrc:file-to-render($file-path) {
  if (not(file:exists($file-path))) then 
    error(xs:QName("FILE-ERROR"), "No se encontró el archivo: " || $file-path)
  else
    let $raw-html := file:read-text($file-path)
    let $doc := html:parse($raw-html, map { 'nons': true() })
    let $xquery-source := xqrsrc:render($doc/*:html, 0)
    return string-join($xquery-source, "&#10;")
};

declare function xqrsrc:text-to-xquery($string, $bindings  as map((xs:string|xs:QName), item()*)?  := {}) {
  let $doc := html:parse($string, map { 'nons': true() })
  let $xquery-source := xqrsrc:render($doc/*:html, 0)
  return xquery:eval(string-join($xquery-source, "&#10;"),$bindings)
};

(:
xquery version "4.0" encoding "utf-8";
import module namespace xqrsrc = 'anteac/xquerysource' at 'C:\Program Files (x86)\BaseX\webapp\anteac\api\html2xquery.xqm';
xqrsrc:file-to-render('C:\Program Files (x86)\BaseX\webapp\anteac\static\copilot_windows_8_1_launcher_widget_claude.html')
:)
