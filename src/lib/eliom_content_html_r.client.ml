
module Raw = Eliom_content_html_raw.R
include Raw

let node s = tot @@ Eliom_content_xml.Xml.make_react (React.S.map toelt s)

let filter_attrib attrib on =
  let attrib = Eliom_content_html_raw.Unsafe.to_xmlattrib attrib in
  let open Eliom_content_xml in
  let name = Xml.aname attrib in
  let a = Xml.racontent attrib in
  let v = match a with
    | Xml.RA a -> Xml.RAReact (React.S.map (function
        | true -> Some a
        | false -> None) on)
    | Xml.RAReact s -> Xml.RAReact (React.S.l2 (fun v b -> if b then v else None) s on)
    | Xml.RALazyStr s -> Xml.RAReact (React.S.map (function
        | true -> Some (Xml.AStr (Eliom_lazy.force s))
        | false -> None) on)
    | Xml.RALazyStrL (sep,l) -> Xml.RAReact (React.S.map (function
        | true -> Some (Xml.AStrL (sep,List.map Eliom_lazy.force l))
        | false -> None) on)
    | Xml.RACamlEventHandler _ ->
      failwith "R.filter_attrib not implemented for event handler"
    | Xml.RAClient _ -> assert false
  in
  to_attrib @@ Xml.attrib name v
