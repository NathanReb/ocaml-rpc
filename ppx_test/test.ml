(* All the ppx tests *)
open OUnit

let check_marshal_unmarshal : 'a * Rpc.t * ('a -> Rpc.t) * (Rpc.t -> ('a,_) Result.result) -> unit = fun (x, r, marshal, unmarshal) ->
  let r' = marshal x in
  let x' = unmarshal r in
  (match x' with
  | Result.Error e -> Printf.printf "Found Error when expecting OK: %s\n%!" (Rpc.Monad.string_of_err e)
  | Result.Ok y -> Printf.printf "OK: (%s)\n%!" (marshal y |> Rpc.to_string));
  assert_equal (Result.Ok x) x';
  if r <> r' then begin
    Printf.printf "marshalled stuff is different: r=%s r'=%s" (Rpc.to_string r) (Rpc.to_string r')
  end;
  assert_equal r r'

let check_unmarshal_error : (Rpc.t -> 'a Rpc.Monad.error_or) -> Rpc.t -> unit = fun unmarshal t ->
  match unmarshal t with
  | Result.Ok _ -> assert_equal false true
  | Result.Error e -> Printf.printf "%s\n" (Rpc.Monad.string_of_err e)

let check_unmarshal_ok : 'a -> (Rpc.t -> 'a Rpc.Monad.error_or) -> Rpc.t -> unit = fun x unmarshal r ->
  match unmarshal r with
  | Result.Ok x' -> assert_equal x x'
  | Result.Error _ -> assert_equal false true

type test_int = int [@@deriving rpc]
let test_int () =
  check_marshal_unmarshal (1, Rpc.Int 1L, rpc_of_test_int, test_int_of_rpc)
let test_int_from_string () =
  check_unmarshal_ok 1 test_int_of_rpc (Rpc.String "1")
let test_bad_int () =
  check_unmarshal_error test_int_of_rpc Rpc.Null
let test_bad_int_string () =
  check_unmarshal_error test_int_of_rpc (Rpc.String "tree")

type test_int32 = int32 [@@deriving rpc]
let test_int32 () =
  check_marshal_unmarshal (1l, Rpc.Int 1L, rpc_of_test_int32, test_int32_of_rpc)
let test_int32_from_string () =
  check_unmarshal_ok 1l test_int32_of_rpc (Rpc.String "1")
let test_bad_int32 () =
  check_unmarshal_error test_int32_of_rpc (Rpc.Float 1.0)
let test_bad_int32_string () =
  check_unmarshal_error test_int32_of_rpc (Rpc.String "moo")

type test_int64 = int64 [@@deriving rpc]
let test_int64 () =
  check_marshal_unmarshal (1L, Rpc.Int 1L, rpc_of_test_int64, test_int64_of_rpc)
let test_int64_from_string () =
  check_unmarshal_ok 1L test_int64_of_rpc (Rpc.String "1")
let test_bad_int64 () =
  check_unmarshal_error test_int64_of_rpc (Rpc.Float 1.0)
let test_bad_int64_string () =
  check_unmarshal_error test_int64_of_rpc (Rpc.String "hello")

type test_unit = unit [@@deriving rpc]
let test_unit () =
  check_marshal_unmarshal ((), Rpc.Null,  rpc_of_test_unit, test_unit_of_rpc)
let test_bad_unit () =
  check_unmarshal_error test_unit_of_rpc (Rpc.Int 1L)

type test_string = string [@@deriving rpc]
let test_string () =
  check_marshal_unmarshal ("test string", Rpc.String "test string", rpc_of_test_string, test_string_of_rpc)
let test_bad_string () =
  check_unmarshal_error test_string_of_rpc (Rpc.Int 1L)

type test_float = float [@@deriving rpc]
let test_float () =
  check_marshal_unmarshal (2.0, Rpc.Float 2.0, rpc_of_test_float, test_float_of_rpc)
let test_float_from_string () =
  check_unmarshal_ok 1.0 test_float_of_rpc (Rpc.String "1.0")
let test_bad_float () =
  check_unmarshal_error test_float_of_rpc (Rpc.Enum [])
let test_bad_float_string () =
  check_unmarshal_error test_float_of_rpc (Rpc.String "xxy")

type test_bool = bool [@@deriving rpc]
let test_bool () =
  check_marshal_unmarshal (true, Rpc.Bool true, rpc_of_test_bool, test_bool_of_rpc)
let test_bad_bool () =
  check_unmarshal_error test_bool_of_rpc (Rpc.String "true")

type test_char = char [@@deriving rpc]
let test_char () =
  check_marshal_unmarshal ('x', Rpc.Int (Char.code 'x' |> Int64.of_int), rpc_of_test_char, test_char_of_rpc)
let test_bad_char () =
  check_unmarshal_error test_char_of_rpc (Rpc.String "x")

type test_int_list = int list [@@deriving rpc]
let test_int_list () =
  check_marshal_unmarshal ([1;2;3;4], Rpc.Enum [Rpc.Int 1L; Rpc.Int 2L; Rpc.Int 3L; Rpc.Int 4L;], rpc_of_test_int_list, test_int_list_of_rpc)

type test_int_array = int array [@@deriving rpc]
let test_int_array () =
  check_marshal_unmarshal ([|1;2;3;4|], Rpc.Enum [Rpc.Int 1L; Rpc.Int 2L; Rpc.Int 3L; Rpc.Int 4L;], rpc_of_test_int_array, test_int_array_of_rpc)

type test_tuple2 = (int * string) [@@deriving rpc]
let test_tuple2 () =
  check_marshal_unmarshal ((3, "hello"), Rpc.Enum [Rpc.Int 3L; Rpc.String "hello"], rpc_of_test_tuple2, test_tuple2_of_rpc)

type test_tuple3 = (int * string * char) [@@deriving rpc]
let test_tuple3 () =
  check_marshal_unmarshal ((3, "hi", 'c'), Rpc.Enum [Rpc.Int 3L; Rpc.String "hi"; Rpc.Int (Char.code 'c' |> Int64.of_int)], rpc_of_test_tuple3, test_tuple3_of_rpc)

type test_option = int option [@@deriving rpc]
let test_option () =
  check_marshal_unmarshal (Some 1, Rpc.Enum [Rpc.Int 1L], rpc_of_test_option, test_option_of_rpc)
let test_option_none () =
  check_marshal_unmarshal (None, Rpc.Enum [], rpc_of_test_option, test_option_of_rpc)
let test_bad_option () =
  check_unmarshal_error test_option_of_rpc (Rpc.Int 5L)

type test_constr = test_int [@@deriving rpc]
let test_constr () =
  check_marshal_unmarshal (1, Rpc.Int 1L, rpc_of_test_constr, test_constr_of_rpc)

type test_variant = VNone | VOne of int | VTwo of (int * int) [@@deriving rpc]
let test_variant () =
  check_marshal_unmarshal (VNone, Rpc.String "VNone", rpc_of_test_variant, test_variant_of_rpc)
let test_variant1 () =
  check_marshal_unmarshal (VOne 1, Rpc.Enum [Rpc.String "VOne"; Rpc.Int 1L], rpc_of_test_variant, test_variant_of_rpc)
let test_variant2 () =
  check_marshal_unmarshal (VTwo (1,2), Rpc.Enum [Rpc.String "VTwo"; Rpc.Enum [Rpc.Int 1L; Rpc.Int 2L]], rpc_of_test_variant, test_variant_of_rpc)
let test_variant_case () =
  check_unmarshal_ok VNone test_variant_of_rpc (Rpc.String "vnone")
let test_bad_variant_case () =
  check_unmarshal_error test_variant_of_rpc (Rpc.Enum [Rpc.String "vtwo"; Rpc.Int 5L]) 

type test_variant_name = VThree of int [@name "bob"] | VFour [@name "lofty"] [@@deriving rpc]
let test_variant_name () = 
  check_marshal_unmarshal (VThree 5, Rpc.Enum [Rpc.String "bob"; Rpc.Int 5L], rpc_of_test_variant_name, test_variant_name_of_rpc)
let test_variant_name2 () = 
  check_marshal_unmarshal (VFour, Rpc.String "lofty", rpc_of_test_variant_name, test_variant_name_of_rpc)

type test_record = {
  fiEld1 : int;
  fiEld2 : string;
} [@@deriving rpc]
let test_record () =
  check_marshal_unmarshal ({fiEld1=7; fiEld2="banana"}, Rpc.Dict ["fiEld1",Rpc.Int 7L; "fiEld2",Rpc.String "banana"], rpc_of_test_record, test_record_of_rpc)
let test_record_case () =
  check_unmarshal_ok {fiEld1=7; fiEld2="banana"} test_record_of_rpc (Rpc.Dict ["field1",Rpc.Int 7L; "FIELD2",Rpc.String "banana"])
let test_bad_record () =
  check_unmarshal_error test_record_of_rpc (Rpc.Dict ["field1",Rpc.Int 7L;])

type test_record_opt = {
  field3 : int option;
  field4 : string option;
} [@@deriving rpc]
let test_record_opt1 () =
  check_marshal_unmarshal ({field3=Some 7; field4=Some "banana"}, Rpc.Dict ["field3",Rpc.Int 7L; "field4",Rpc.String "banana"], rpc_of_test_record_opt, test_record_opt_of_rpc)
let test_record_opt2 () =
  check_marshal_unmarshal ({field3=Some 7; field4=None}, Rpc.Dict ["field3",Rpc.Int 7L;], rpc_of_test_record_opt, test_record_opt_of_rpc)
let test_record_opt3 () =
  check_marshal_unmarshal ({field3=None; field4=Some "hamster"}, Rpc.Dict ["field4",Rpc.String "hamster"], rpc_of_test_record_opt, test_record_opt_of_rpc)
let test_record_opt4 () =
  check_marshal_unmarshal ({field3=None; field4=None}, Rpc.Dict [], rpc_of_test_record_opt, test_record_opt_of_rpc)

type test_record_attrs = {
  field5 : int [@key "foo"]
} [@@deriving rpc]
let test_record_attrs () =
  check_marshal_unmarshal ({field5=6}, Rpc.Dict ["foo", Rpc.Int 6L], rpc_of_test_record_attrs, test_record_attrs_of_rpc)

type 'a test_poly = 'a list [@@deriving rpc]
let test_poly () =
  let (x : int test_poly) = [1;2;3] in
  check_marshal_unmarshal (x, Rpc.Enum [Rpc.Int 1L; Rpc.Int 2L; Rpc.Int 3L], (rpc_of_test_poly Rpc.rpc_of_int), (test_poly_of_rpc Rpc.int_of_rpc))

type test_polyvar = [ `one | `two of int | `thRee of int * int ] [@@deriving rpc]
let test_polyvar () =
  check_marshal_unmarshal (`one, Rpc.String "one", rpc_of_test_polyvar, test_polyvar_of_rpc)
let test_polyvar2 () =
  check_marshal_unmarshal (`two 2, Rpc.Enum [Rpc.String "two"; Rpc.Int 2L], rpc_of_test_polyvar, test_polyvar_of_rpc)
let test_polyvar3 () =
  check_marshal_unmarshal (`thRee (4,5), Rpc.Enum [Rpc.String "thRee"; Rpc.Enum [ Rpc.Int 4L; Rpc.Int 5L]], rpc_of_test_polyvar, test_polyvar_of_rpc)
let test_polyvar_case () =
  check_unmarshal_ok (`thRee (4,5)) test_polyvar_of_rpc (Rpc.Enum [Rpc.String "THREE"; Rpc.Enum [ Rpc.Int 4L; Rpc.Int 5L]]) 

type test_pvar_inherit = [ `four of string | test_polyvar ] [@@deriving rpc]
let test_pvar_inherit () =
  check_marshal_unmarshal (`one, Rpc.String "one", rpc_of_test_pvar_inherit, test_pvar_inherit_of_rpc)
let test_pvar_inherit2 () =
  check_marshal_unmarshal (`four "apple", Rpc.Enum [Rpc.String "four"; Rpc.String "apple"], rpc_of_test_pvar_inherit, test_pvar_inherit_of_rpc)


let suite =
  "basic_tests" >:::
  [
    "int" >:: test_int;
    "int_from_string" >:: test_int_from_string;
    "bad_int" >:: test_bad_int;
    "bad_int_string" >:: test_bad_int_string;
    "int32" >:: test_int32;
    "int32_from_string" >:: test_int32_from_string;
    "bad_int32" >:: test_bad_int32;
    "bad_int32_string" >:: test_bad_int32_string;
    "int64" >:: test_int64;
    "int64_from_string" >:: test_int64_from_string;
    "bad_int64" >:: test_bad_int64;
    "bad_int64_string" >:: test_bad_int64_string;
    "unit" >:: test_unit;
    "bad_unit" >:: test_bad_unit;
    "string" >:: test_string;
    "bad_string" >:: test_bad_string;
    "float" >:: test_float;
    "float_from_string" >:: test_float_from_string;
    "bad_float" >:: test_bad_float;
    "bad_float_string" >:: test_bad_float_string;
    "bool" >:: test_bool;
    "bad_bool" >:: test_bad_bool;
    "char" >:: test_char;
    "bad_char" >:: test_bad_char;
    "int list" >:: test_int_list;
    "int array" >:: test_int_array;
    "tuple2" >:: test_tuple2;
    "tuple3" >:: test_tuple3;
    "option" >:: test_option;
    "option (none)" >:: test_option_none;
    "bad_option" >:: test_bad_option;
    "constr" >:: test_constr;
    "variant" >:: test_variant;
    "variant1" >:: test_variant1;
    "variant2" >:: test_variant2;
    "variant_case" >:: test_variant_case;
    "variant_name" >:: test_variant_name;
    "variant_name2" >:: test_variant_name2;
    "bad_variant_case" >:: test_bad_variant_case;
    "record" >:: test_record;
    "record_case" >:: test_record_case;
    "bad_record" >:: test_bad_record;
    "record_opt1" >:: test_record_opt1;
    "record_opt2" >:: test_record_opt2;
    "record_opt3" >:: test_record_opt3;
    "record_opt4" >:: test_record_opt4;
    "record_attrs" >:: test_record_attrs;
    "poly" >:: test_poly;
    "polyvar" >:: test_polyvar;
    "polyvar2" >:: test_polyvar2;
    "polyvar3" >:: test_polyvar3;
    "polyvar_case" >:: test_polyvar_case;
    "pvar_inherit" >:: test_pvar_inherit;
    "pvar_inherit2" >:: test_pvar_inherit2;

  ]

let _ =
  run_test_tt_main suite


