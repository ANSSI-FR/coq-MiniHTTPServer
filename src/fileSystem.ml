(* FreeSpec
 * Copyright (C) 2018–2019 ANSSI
 *
 * Contributors:
 * 2019 Thomas Letan <thomas.letan@ssi.gouv.fr>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *)

open Freespec_exec.Coqstr
open Freespec_exec.Coqbool
open Freespec_exec.Extends
open Freespec_exec.Coqunit
open Utils

let path = "praecia.filesystem"

let constr_of_fd fd =
  Constr.(of_kind (Int (Uint63.of_int (Obj.magic fd))))

let fd_of_constr c =
  match Constr.kind c with
  | Constr.Int i -> (Obj.magic (snd (Uint63.to_int2 i)) : Unix.file_descr)
  | _ -> assert false

let open_file = function
  | [path] ->
     Unix.openfile (string_of_coqstr path) [ O_RDONLY ] 0
     |> constr_of_fd
  | _ ->
     assert false

let is_file = function
  | [path] ->
     Sys.file_exists (string_of_coqstr path)
     |> bool_to_coqbool

let read_file = function
  | [fd] ->
     read_all_from (fd_of_constr fd) |>
     string_of_coqstr
  | _ ->
     assert false

let close_file = function
  | [fd] ->
     Unix.close (fd_of_constr fd);
     coqtt
  | _ ->
     assert false

let install_interface =
  register_interface path [
      ("Open",   open_file);
      ("IsFile", is_file);
      ("Read",   read_file);
      ("Close",  close_file)
    ]
