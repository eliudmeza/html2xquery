# **HTML5 to XQuery 4.0 Transformer for BaseX**

Este módulo desarrollado para **BaseX** procesa documentos HTML5 y los reconstruye dinámicamente generando código ejecutable en **XQuery 4.0** utilizando elementos computados (*computed constructors*). Es una herramienta diseñada para tareas de metaprogramación, migración de plantillas web y manipulación estructural avanzada de documentos dentro de bases de datos XML nativas.

## **Características Principales**

* **Soporte Nativo HTML5:** Aprovecha las capacidades de parseo de BaseX para procesar estructuras HTML5, gestionando etiquetas y atributos de forma semántica.  
* **Generación a XQuery 4.0:** Transpila nodos del DOM a constructores computados estructurados compatibles con la última especificación de XQuery 4.0.  
* **Elementos Computados Dinámicos:** Reconstruye de manera precisa elementos (computed element), atributos (computed attribute) y nodos de texto preservando fielmente la jerarquía original.  
* **Integración en BaseX:** Diseñado como un módulo modular (.xqm) optimizado para el motor de base de datos BaseX.

## **Estructura del Proyecto**

`.`  
`├── README.md                           # Descripción e instrucciones del proyecto`  
`├── LICENSE                             # Archivo de licencia (Mozilla Public License 2.0)`  
`└── OOXML-Library-XQuery-BaseXdb.xqm    # Módulo principal de funciones en XQuery`

## **Requisitos del Sistema**

* **BaseX:** Versión 11.0 o superior (necesaria para el soporte experimental y sintaxis de características alineadas a XQuery 4.0).  
* Entorno de ejecución de BaseX configurado correctamente para la importación de módulos locales.

## **Referencia de la API (Funciones del Módulo)**

El módulo expone las siguientes funciones principales bajo el namespace xqrsrc:

### **1\. xqrsrc:file-to-xquery**

`declare function xqrsrc:file-to-xquery($file-path)`  
Lee un archivo HTML5 desde la ruta especificada y lo transforma directamente en una cadena de texto que contiene la estructura equivalente en constructores computados de XQuery 4.0.

### **2\. xqrsrc:file-to-render**

`declare function xqrsrc:file-to-render($file-path)`  
Procesa el archivo HTML5 provisto y ejecuta la transformación internamente para renderizar el resultado final directamente en el entorno de BaseX.

### **3\. xqrsrc:text-to-xquery**

`declare function xqrsrc:text-to-xquery($string, $bindings as map((xs:string|xs:QName), item()*)? := {})`  
Transforma una cadena de texto directa que contenga estructura HTML5 a su representación en XQuery 4.0. Permite pasar un mapa opcional de variables externas ($bindings) para inyectar datos dinámicos durante el proceso de reconstrucción elemental.

## **Instalación y Uso**

### **Ejemplo de Implementación**

`import module namespace xqrsrc = "http://eliudmeza.com/modules/html5-to-xquery4";`

`(: Ejemplo usando transformación de texto con bindings opcionales :)`  
`let $html := '<div class="container"><p>Texto Base</p></div>'`  
`return xqrsrc:text-to-xquery($html)`

### **Resultado Esperado (Código XQuery 4.0 Generado)**

`element div {`  
  `attribute class { "container" },`  
  `element p { "Texto Base" }`  
`}`

## **Licencia**

Este proyecto está bajo la licencia **Mozilla Public License 2.0 (MPL 2.0)**. Esto significa que:

* Puedes integrar este módulo libremente en aplicaciones propietarias o comerciales sin tener que liberar el código de tu aplicación principal.  
* Cualquier modificación, optimización o corrección directa sobre los archivos de este módulo **debe ser compartida públicamente** bajo la misma licencia MPL 2.0.

## **Autor**

* **Eliud Meza** \- Desarrollador Principal
