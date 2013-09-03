; Junto.  26 Sep 13.
;
; TODO build junto.arc from the ground up, largely parroting news.arc
; TODO document extensively

(declare 'atstrings t) ; Relates to immutable strings.  See ac.scm:68.

(require "unit-test.arc")

(= this-site*    "Junto"
   site-url*     "http://www.junto.io/"
   parent-url*   "http://www.junto.io"
   favicon-url*  ""
   site-desc*    "Build communities."
   site-color*   (color 180 180 180) ; what color is this?
   site-color*   (color 180 180 180) ; ditto
   prefer-url*   t) ; used news.arc:1437 TODO remove once section is refactored

; Data Structures

(deftem group
  id      nil
  name    nil
  created (seconds)
  owner   nil
  members nil)

; TODO make other templates inherit from this one
(deftem data
  id nil
  name nil
  created (seconds))

(deftem profile
  id       nil
  name     nil
  created  (seconds)
  auth     0 ; 0 is fale, 1 is true
  member   nil ; TODO delete, not used
  submitted nil
  votes     nil ; for now just recent, elts each (time id by sitename dir)
  karma     1 ; TODO are we keeping karma?
  avg nil ; used for leaderspace TODO is this necessary?
  weight nil ; used to identify potential sockpuppets and for ranking 
  ignore nil ; TODO delete this. ignore is an ok bandaid for public forum, 
             ;                   a disease for private junto 
  email nil
  about nil
  showdead nil ; TODO delete. dead junto users are deleted, permanently.
; TODO are we keep noprocrast? could be useful
  noprocrast nil 
  firstview nil ; for noprocrast
  lastview nil ; for noprocrast
  maxvisit  20 ; for noprocrast
  minaway 180  ; for noprocrast
  topcolor nil ; TODO delete/move, should groups be able to set their own color scheme?
  keys nil ; used to indicate restrictions/categories for users
  delay 0) ; TODO delete. used in cansee, by default anyone should be able to see

(deftem item
  id nil
  type nil
  by nil
  ip nil
  time (seconds)
  url nil
  title nil
  text nil
  votes nil ; each elt (time ip user type score)
  score 0
  sockvotes 0 ; TODO are we keeping sockvotes?
  flags nil ; TODO make this more manual? what's our plan for moderation?
  dead nil ; TODO delete. Just delete the idea of dead stuff.
  deleted nil ; TODO delete. Just delete it.
  parts nil ; TODO rename. has to do with polls
  parent nil
  kids nil
  keys nil) ; used to indicate restrictions/categories for items

; TODO convert votes into a template

; Load and Save

; TODO rethink how this should be organized.
; separate folder for each junto?
(= sitedir*  "junto/"
   groupdir* "junto/group/"
   storydir* "junto/group/story/" ; TODO rename?
   profdir*  "junto/group/profile/"  ; 
   votedir*  "junto/group/vote/")

(register-test
  '("ensure dirs"
     (map ensure-dir (list arcdir* sitedir* groupdir* storydir* profdir* votedir*))
     t))

(= votes* (table) profs* (table))

(= initload-users* nil) ; TODO can i remove this? only used in nsv below

(def nsv ((o port 8080))
  (map ensure-dir (list arcdir* sitedir* groupdir* storydir* userdir* votedir*))
  (unless stories* (load-items))
  (if (and initload-users* (empty profs*)) (load-users))
  (asv port))

(register-test
  '("test-nsv"
     (even 3) ; run, verify it's accessible
     t)) 

(def load-users ()
  (pr "load users: ")
  (noisy-each 100 id (dir profdir*) ; TODO understand why it's important to use noisy-each
    (load-user id)))

(def load-user (u)
  (= (votes* u) (load-table (+ votedir* u))
     (profs* u) (temload 'profile (+ profdir* u)))
  u)

(def profile (u)
  (or (profs* u)
      (aand (goodname u)
            (file-exists (+ profdir* u))
            (= (profs* u) (temload 'profile it)))))
; TODO there's a lot of redundancy for loading users, is it necessary?

(def votes (u)
  (or (votes* u)
      (aand (file-exists (+ votedir* u))
            (= (votes* u) (load-table it)))))

(def init-user (u)
  (= (votes* u) (table)
     (profs* u) (inst 'profile 'id u))
  (save-votes u)
  (save-prof u)
  u)


; Need this because can create users on the server (for other apps)
; without setting up places to store their state as news users.
; See the admin op in app.arc.  So all calls to login-page from the
; news app need to call this in the after-login fn.

(def ensure-news-user (u)
  (if (profile u) u (init-user u))) ; TODO is this really necessary?

(def save-votes (u) (save-table (votes* u) (+ votedir* u)))

(def save-prof (u) (temstore 'profile (profs* u) (+ profdir* u)))

(mac uvar (u k) `((profile ,u) ',k))
