(in-package :om)


;--------------------------------------------------
;Variable definiton with files to load
;--------------------------------------------------

(defvar *proj-source-dir* nil)
(setf *proj-source-dir* (append (pathname-directory *load-pathname*) (list "sources")))


(defvar *proj-lib-files* nil)
(setf *proj-lib-files* '("main"))

;--------------------------------------------------
;Loading files
;--------------------------------------------------
(defvar *pre-palette*  (om-load-pixmap "palette" *om-pict-type* (om-relative-path '("resources" "picture") nil)))

(mapc #'(lambda (file) (compile&load (om-relative-path '("sources") file))) *proj-lib-files*)

(addclass2pack '(presentador) *current-lib*)



