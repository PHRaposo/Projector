(in-package :om)


;=======================================
;MENU
;=======================================

(defclass! presentador () 
 ((folder :initform nil :initarg :folder :accessor folder)
  (patch-list :accessor patch-list)) (:icon 128))

(defun load-patches-in (folder) ;phraposo(2024)
 "This function allows presentador to load all patches and patches inside subfolders inside <folder>."
 (remove nil
  (flat (loop for item in (elements folder)
              collect (cond ((folder-p item)
                             (load-patches-in item))
	                    ((and (patch-p item) (not (maquette-p item)))
                             (load-patch item))
                       (t nil))))))

(defmethod initialize-instance :after ((self presentador) &rest l )
  (declare (ignore l))
  (let ((folder (search-the-folder *current-workspace* (list! (folder self)))))
    (when folder
      (setf (patch-list self) (load-patches-in folder)) ;<==
            ;(loop for item in (elements folder)
            ;      when (and (patch-p item) (not (maquette-p item)))
            ;      collect (load-patch item)))

      (setf (patch-list self)
            (sort (patch-list self) 'string< :key 'name)))))


(defun find-folder (cont name)
  (let ((elems (elements cont))
        rep)
    (loop for item in elems
          while (not rep) do
          (when (folder-p item)
            (setf rep (if (string-equal name (name item)) item))))
    rep))

(defun search-the-folder (container list)
   (cond
    ((null list) nil); (om-beep-msg  "bad folder name"))
    ((= (length list) 1)
     (let ((folder (find-folder container (car list))))
       (if folder folder (om-beep-msg " bad folder name"))))
    (t
     (let ((folder (find-folder container (car list))))
       (if folder (search-the-folder folder (cdr list))
           (om-beep-msg  " bad folder name"))))))

;=======================================
;EDITOR
;=======================================
(in-package :om)

(defmethod Class-has-editor-p ((self presentador)) (patch-list self))

(defmethod get-boxsize ((self presentador)) (om-make-point 40 70))

(defmethod get-editor-class ((self presentador)) 'preEditor)

(defmethod draw-obj-in-rect ((self  presentador) x x1 y y1 edparams  view)
   t)

;------------------------------------
; EDITOR
;------------------------------------

(defclass preeditor (object-editor patchEditor)
  ((current :initform 0 :accessor current)
   (mode :initform nil :accessor mode)))

(defmethod object ((Self preeditor))
  (nth (current self) (patch-list (slot-value self 'object))))

(defmethod hwmanypatches ((Self preeditor))
  (length (patch-list (slot-value self 'object))))

(defmethod get-editor-panel-class ((self preeditor))  'prePanel)

(defclass prePanel (patchpanel) ())

(defmethod object ((Self prePanel))
  (object (om-view-container self)))

(defmethod set-editor-patch ((Self preeditor) num)
  (let (object)
    (setf (editorframe (object self)) nil)
    (setf (current self) num)
    (setf object (object self))
    (setf (editorframe (object self)) self)

    (om-set-window-title (om-view-window self) "Patch Presenter")
    (loop for item in (om-subviews (panel self)) do (om-remove-subviews (panel self) item ))
    (mapc #'(lambda (elem)
              (let ((newframe (make-frame-from-callobj elem)))
                (om-add-subviews  (panel self) newframe)
                (add-subview-extra newframe))) (get-elements object)
          )
    (mapc #'(lambda (elem)
              (update-graphic-connections elem (get-elements object))) (get-subframes (panel self)))
    #+(or linux win32) (add-window-buttons (panel self))
    #+macosx (change-text (title-bar self) (name object))
    ;#+(or linux win32)(om-set-view-position (title-bar (editorframe object)) (om-make-point 20 20))
   )
  (om-invalidate-view self))

(defmethod initialize-instance :after ((Self preeditor) &rest L)
   (declare (ignore l))
   (set-editor-patch self 0))

;------------------------------------
;ACTIONS
;------------------------------------
#+macosx
(defmethod init-titlebar ((self preeditor))
  (call-next-method)
  (apply 'om-add-subviews
         (cons (title-bar self)
               (loop for icon in '("first" "prev" "next" "last")
                     for fun in '(start-patch back-patch fw-patch last-patch)
                     for xx = 180 then (+ xx 21)
                     collect
                     (let ((f fun))
                       (om-make-view 'om-icon-button :position (om-make-point xx 2) :size (om-make-point 22 22)
                                     :icon1 icon :icon2 (string+ icon "-pushed")
                                     :action #'(lambda (item) (funcall f (panel self)))))
                 ))
         ))

#+(or linux win32)
(defmethod add-window-buttons ((self prePanel))
  "Add the input and output buttons at the top-button in 'self'."
 (om-add-subviews self  ;(title-bar (editorframe (object self)))))==> title-bar <- preeditor <- ompatch <- prepanel
                (om-make-view 'editor-titlebar :position (om-make-point 0 0)
                                                        :size (om-make-point (w self) *titlebars-h*)
                                                        :bg-color *editor-bar-color*
                                                        :c++ *editor-bar-color++*
                                                        :c+ *editor-bar-color+*
                                                        :c-- *editor-bar-color--*
                                                        :c- *editor-bar-color-*
                                                        ))
 (let ((name (name (object self)))
       (titlebar (last-elem (om-subviews self))))
  (setf (title-bar (editorframe (object self))) titlebar)
     (om-add-subviews titlebar ;self
                     (om-make-dialog-item 'om-static-text (om-make-point 10 2)
                                          (om-make-point 200 ;(+ (om-string-size name *om-default-font2b*) 4)
                                                         18)
                                          name
                                          :bg-color *editor-bar-color*
                                          :fg-color *om-dark-gray-color*
                                          :font *om-default-font1b*
                                          ))
   (apply 'om-add-subviews
         (cons titlebar ;self
               (loop for icon in '("first" "prev" "next" "last")
                     for fun in '(start-patch back-patch fw-patch last-patch)
                     for xx = 220 then (+ xx 21)
                     collect
                       (let ((f fun))
                         (om-make-view 'om-icon-button :position (om-make-point xx 2) :size (om-make-point 22 22)
                                       :icon1 icon :icon2 (string+ icon "-pushed")
                                       :action #'(lambda (item) (funcall f (panel self)))))
                       ))
         )))

#|
;; OLD
(defmethod set-editor-patch ((Self preeditor) num)
  (let (object)
    (setf (editorframe (object self)) nil)
    (setf (current self) num)
    (setf object (object self))
    (setf (editorframe (object self)) self)
    (om-set-window-title (om-view-window self) "Patch Presenter")
    (loop for item in (om-subviews (panel self)) do (om-remove-subviews (panel self) item ))
    (mapc #'(lambda (elem)
              (let ((newframe (make-frame-from-callobj elem)))
                (om-add-subviews  (panel self) newframe)
                (add-subview-extra newframe))) (get-elements object))
    (mapc #'(lambda (elem)
              (update-graphic-connections elem (get-elements object))) (get-subframes (panel self)))
  (change-text (title-bar self) (name object))
    )
  (om-invalidate-view self))

(defmethod init-titlebar ((self preeditor))
  (call-next-method)
  (apply 'om-add-subviews
         (cons (title-bar self)
               (loop for icon in '("first" "prev" "next" "last")
                     for fun in '(start-patch back-patch fw-patch last-patch)
                     for xx = 180 then (+ xx 21)
                     collect
                     (let ((f fun))
                       (om-make-view 'om-icon-button :position (om-make-point xx 2) :size (om-make-point 22 22)
                                     :icon1 icon :icon2 (string+ icon "-pushed")
                                     :action #'(lambda (item) (funcall f (panel self)))))
                 ))
         ))
|#

(defmethod start-patch ((Self prePanel))
  (set-editor-patch (editor self) 0))

(defmethod back-patch ((Self prePanel))
  (set-editor-patch (editor self) (max 0 (- (current (editor self)) 1))))

(defmethod fw-patch ((Self prePanel))
  (set-editor-patch (editor self) (min (- (hwmanypatches (editor self)) 1) (+ (current (editor self)) 1))))

(defmethod last-patch ((Self prePanel))
  (set-editor-patch (editor self) (- (hwmanypatches (editor self)) 1)))

;(defmethod handle-key-event ((self prePanel) key)
;  (case key
;    (:om-key-tab (fw-patch self))
;    (otherwise (call-next-method))))

; phraposo (2024)
; option + left = back
; option + right = forward
; option + down = start
; option + up = last

(defmethod handle-key-event ((self prePanel) key)
 (case key
  (:om-key-left
	  (if (om-option-key-p)
	      (back-patch self)
	      (call-next-method)))

  (:om-key-right
	  (if (om-option-key-p)
          (fw-patch self)
		  (call-next-method)))

  (:om-key-up
	  (if (om-option-key-p)
	      (last-patch self)
	      (call-next-method)))

  (:om-key-down
	  (if (om-option-key-p)
          (start-patch self)
		  (call-next-method)))

  (otherwise (call-next-method))))


