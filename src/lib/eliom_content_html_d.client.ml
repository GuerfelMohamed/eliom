module D = struct
  module Raw = Eliom_content_html_raw.D

  include Raw

  type ('a, 'b, 'c) lazy_star =
      ?a: (('a attrib) list) -> ('b elt) list Eliom_lazy.request -> 'c elt

  let lazy_form ?(a = []) elts =
    tot (Eliom_content_xml.Xml.lazy_node ~a:(to_xmlattribs a) "form"
           (Eliom_lazy.from_fun
              (fun () -> toeltl (Eliom_lazy.force elts))))
end

include D

module Arg = struct
  include D
  module Svg = Eliom_content_svg_d
  let uri_of_fun = Eliom_content_xml.Xml.uri_of_fun
  let attrib_of_service s info =
    Eliom_content_xml.
      (D.to_attrib
         (Xml.internal_event_handler_attrib
            s (Xml.internal_event_handler_of_service info)))
  let to_elt = toelt
end
include Eliom_form.Make_links(Arg)
module Form = Eliom_form.Make(Arg)