(* Ocsigen
 * http://www.ocsigen.org
 * Module eliomservices.mli
 * Copyright (C) 2007 Vincent Balat
 * Laboratoire PPS - CNRS Université Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception; 
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)


(** This module allows to define services. *)


open Extensions
open Eliomsessions
open Eliomparameters



(** This function may be used for services that cannot be interrupted
  (no cooperation point for threads). It is defined by
  [let sync f sp g p = Lwt.return (f sp g p)]
 *)
val sync : ('a -> 'b -> 'c -> 'd) -> 'a -> 'b -> 'c -> 'd Lwt.t



(** {2 Types of services} *)

type suff = [ `WithSuffix | `WithoutSuffix ]

type servcoserv = [ `Service | `Coservice ]

type getpost = [ `Get | `Post ]
      (* `Post means that there is at least one post param
         (possibly only the state post param).
         `Get is for all the other cases.
       *)

type attached_service_kind = 
    [ `Internal of servcoserv * getpost
    | `External]

type get_attached_service_kind = 
    [ `Internal of servcoserv * [ `Get ]
    | `External ]

type post_attached_service_kind = 
    [ `Internal of servcoserv * [ `Post ]
    | `External ]

type internal = 
    [ `Internal of servcoserv * getpost ]

type registrable = [ `Registrable | `Unregistrable ]
(** You can call register function only on registrable services *)
(* Registrable means not pre-applied *)

type +'a a_s
      
type +'a na_s

type service_kind =
    [ `Attached of attached_service_kind a_s
  | `Nonattached of getpost na_s ]

type get_service_kind =
    [ `Attached of get_attached_service_kind a_s
  | `Nonattached of [ `Get ] na_s ]

type post_service_kind =
    [ `Attached of post_attached_service_kind a_s
  | `Nonattached of [ `Post ] na_s ]

type internal_service_kind =
    [ `Attached of internal a_s
  | `Nonattached of getpost na_s ]

type attached =
    [ `Attached of attached_service_kind a_s ]

type nonattached =
    [ `Nonattached of getpost na_s ]

type ('get,'post,+'kind,+'tipo,+'getnames,+'postnames,+'registr) service
(** Type of services.
    - [ 'get] is the type of GET parameters
    - [ 'post] is the type of POST parameters
    - [ 'kind] is a subtype of {!Eliomservices.service_kind} (attached or non-attached 
      service, internal or external, GET only or with POST parameters)
    - [ 'tipo] is a phantom type stating the kind of parameters it uses
        (suffix or not)
    - [ 'getnames] is the type of GET parameters names
    - [ 'postnames] is the type of POST parameters names
    - [ 'registrable] is a phantom type, subtype of {!Eliomservices.registrable},
      telling if it is possible to register a handler on this service.
 *)



(***** Static dir and actions do not depend on the type of pages ******)


(** {2 Definitions of services} *)

(** {3 Main services} *)

val new_service :
    ?sp: Eliommod.server_params ->
    path:url_path ->
        get_params:('get, [< suff ] as 'tipo,'gn) params_type ->
            unit ->
              ('get,unit,
               [> `Attached of 
                 [> `Internal of [> `Service ] * [>`Get] ] a_s ],
               'tipo,'gn, 
               unit, [> `Registrable ]) service
(** [new_service ~path:p ~get_params:pa ()] creates an {!Eliomservices.service} associated
   to the path [p], taking the GET parameters [pa]. 
   
   {e Warning: If you use this function after the initialisation phase,
   you must give the [~sp] parameter, otherwise it will raise the
   exception {!Eliommod.Eliom_function_forbidden_outside_site_loading}.}
*)
	      
val new_external_service :
    server: string ->
      path:url_path ->
        get_params:('get, [< suff ] as 'tipo, 'gn) params_type ->
          post_params:('post, [ `WithoutSuffix ], 'pn) params_type ->
            unit -> 
              ('get, 'post, [> `Attached of [> `External ] a_s ], 'tipo, 
               'gn, 'pn, [> `Unregistrable ]) service
(** Creates an service for an external web site.
   Allows to creates links or forms towards other Web sites using
   Eliom's syntax.
 *)

val new_post_service :
    ?sp: Eliommod.server_params ->
    fallback: ('get, unit, 
               [`Attached of [`Internal of 
                 ([ `Service | `Coservice ] as 'kind) * [`Get]] a_s ],
               [< suff] as 'tipo, 'gn, unit, 
               [< `Registrable ]) service ->
                 post_params: ('post,[`WithoutSuffix],'pn) params_type ->
                   unit ->
                     ('get, 'post, [> `Attached of 
                       [> `Internal of 'kind * [> `Post]] a_s ],
                      'tipo, 'gn, 'pn, [> `Registrable ]) service
(** Creates an service that takes POST parameters. 
   [fallback] is the a service without POST parameters.
   You can't create an service with POST parameters
   if the same service does not exist without POST parameters. 
   Thus, the user can't bookmark a page that does not exist.
 *)
(* fallback must be registrable! (= not preapplied) *)
	  
		
(** {3 Attached coservices} *)

val new_coservice :
    ?max_use:int ->
    ?timeout:float ->
    fallback: 
    (unit, unit, [ `Attached of [ `Internal of [ `Service ] * [`Get]] a_s ],
     [`WithoutSuffix] as 'tipo,
     unit, unit, [< registrable ]) service ->
       get_params: 
         ('get,[`WithoutSuffix],'gn) params_type ->
           unit ->
             ('get,unit,[> `Attached of 
               [> `Internal of [> `Coservice] * [> `Get]] a_s ],
              'tipo, 'gn, unit, 
              [> `Registrable ]) service
(** Creates a coservice. A coservice is another version of an
   already existing main service, where you can register another handler. 
   The two versions are automatically distinguished using an extra parameter
   added automatically by Eliom. 
   It allows to have several links towards the same page, 
   that will behave differently, or to create services dedicated to one user. 
   See the tutorial for more informations.
 *)

val new_post_coservice :
    ?max_use:int ->
    ?timeout:float ->
    fallback: ('get, unit, [ `Attached of 
      [`Internal of [<`Service | `Coservice] * [`Get]] a_s ],
               [< suff ] as 'tipo,
               'gn, unit, [< `Registrable ]) service ->
                 post_params: ('post,[`WithoutSuffix],'pn) params_type ->
                   unit ->
                     ('get, 'post, 
                      [> `Attached of 
                        [> `Internal of [> `Coservice] * [> `Post]] a_s ],
                      'tipo, 'gn, 'pn, [> `Registrable ]) service
(** Creates a coservice with POST parameters *)

(** {3 Non attached coservices} *)

val new_coservice' :
    ?max_use:int ->
    ?timeout:float ->
    get_params: 
    ('get,[`WithoutSuffix],'gn) params_type ->
      unit ->
        ('get, unit, [> `Nonattached of [> `Get] na_s ],
         [`WithoutSuffix], 'gn, unit, [> `Registrable ]) service
(** Creates a non-attached coservice, that is, services that do not
   correspond to a precise URL. 
   Links towards such services will not change the URL, 
   just add extra parameters. 
   See the tutorial for more informations.
 *)

val new_post_coservice' :
    ?max_use:int ->
    ?timeout:float ->
    post_params: ('post,[`WithoutSuffix],'pn) params_type ->
      unit ->
        (unit, 'post, 
         [> `Nonattached of [> `Post] na_s ],
         [ `WithoutSuffix ], unit, 'pn, [> `Registrable ]) service
(** Creates a non attached coservice with POST parameters. *)

(*
val new_get_post_coservice' :
    ?max_use:int ->
    ?timeout:float ->
   fallback: ('get, unit, [`Nonattached of [`Get] na_s ],
   [< suff ] as 'tipo,
   'gn, unit, [< `Registrable ]) service ->
   post_params: ('post,[`WithoutSuffix],'pn) params_type ->
   unit ->
   ('get, 'post, 
   [> `Nonattached of [> `Post] na_s ],
   'tipo,'gn,'pn, [> `Registrable ]) service
(* * Creates a non-attached coservice with GET and POST parameters. The fallback is a non-attached coservice with GET parameters. *)
*)


(** {2 Misc} *)

val static_dir :
    sp:Eliommod.server_params -> 
      (string list, unit, [> `Attached of 
        [> `Internal of [> `Service ] * [> `Get] ] a_s ],
       [ `WithSuffix ],
       [ `One of string list ] param_name, unit, [> `Unregistrable ])
        service
(** A predefined service
   that correponds to the directory where static pages are.
   This directory is chosen in the config file (ocsigen.conf).
   This service takes the name of the static file as a parameter
   (a string list, slash separated).
 *)

    
val preapply :
    service:('a, 'b, [> `Attached of 'd a_s ] as 'c,
     [< suff ], 'e, 'f, 'g)
    service ->
      'a -> 
        (unit, 'b, 'c, 
         [ `WithoutSuffix ], unit, 'f, [ `Unregistrable ]) service
(** creates a new service by preapplying a service to GET parameters. 
   It is not possible to register a handler on an preapplied service.
   Preapplied services may be used in links or as fallbacks for coservices
 *)
 

val make_string_uri :
    service:('get, unit, [< get_service_kind ],
     [< suff ], 'gn, unit, 
     [< registrable ]) service ->
       sp:Eliommod.server_params -> 'get -> string
(** Creates the string corresponding to the URL of a service applyed to
   its GET parameters.
 *)




(**/**)
val get_kind_ : ('a, 'b, 'c, 'd, 'e, 'f, 'g) service -> 'c
val get_pre_applied_parameters_ : ('a, 'b, 'c, 'd, 'e, 'f, 'g) service -> 
  (string * string) list
val get_get_params_type_ : ('a, 'b, 'c, 'd, 'e, 'f, 'g) service ->
  ('a, 'd, 'e) Eliomparameters.params_type
val get_post_params_type_ : ('a, 'b, 'c, 'd, 'e, 'f, 'g) service ->
  ('b, [ `WithoutSuffix ], 'f) Eliomparameters.params_type
val get_att_kind_ : 'a a_s -> 'a
val get_path_ : 'a a_s -> url_path
val get_server_ : 'a a_s -> string
val get_get_state_ : 'a a_s -> Eliommod.internal_state option
val get_post_state_ : 'a a_s -> Eliommod.internal_state option
val get_na_name_ : 'a na_s -> string option * string option
val get_max_use_ : ('a, 'b, 'c, 'd, 'e, 'f, 'g) service -> int option
val get_timeout_ : ('a, 'b, 'c, 'd, 'e, 'f, 'g) service -> float option
val reconstruct_absolute_url_path : url_path -> url_path -> url_path option -> string
val reconstruct_relative_url_path : url_path -> url_path -> url_path option -> string
