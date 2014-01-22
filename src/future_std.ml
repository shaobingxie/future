open Core.Std
open CFStream

module Deferred = struct
  type 'a t = 'a

  include Monad.Make(struct
    type 'a t = 'a
    let return x = x
    let bind m f = f m
    let map m ~f = f m
  end)

  module Result = struct
    type ('a, 'b) t = ('a, 'b) Result.t

    include Monad.Make2(struct
      type ('a, 'b) t = ('a, 'b) Result.t
      let return = Result.return
      let bind = Result.bind
      let map = Result.map
    end)
  end
end

let return = Deferred.return
let (>>=) = Deferred.bind
let (>>|) = Deferred.(>>|)
let (>>=?) = Deferred.Result.(>>=)
let (>>|?) = Deferred.Result.(>>|)
let fail = raise
let raise = `Use_fail_instead

module Pipe = struct
  module Reader = struct
    type 'a t = 'a Stream.t
  end

  let read r = match Stream.next r with
    | Some x -> `Ok x
    | None -> `Eof

  let fold = Stream.fold
end

module Reader = struct
  module Read_result = struct
    type 'a t = [ `Eof | `Ok of 'a ]
  end

  type t = in_channel

  let with_file ?buf_len file ~f =
    match buf_len with
    | None | Some _ -> In_channel.with_file file ~f

  let read_line ic =
    match In_channel.input_line ~fix_win_eol:true ic with
    | Some x -> `Ok x
    | None -> `Eof

  let read_all ic read_one =
    Stream.from (fun _ -> match read_one ic with
    | `Ok x -> Some x
    | `Eof -> In_channel.close ic; None
    )

  let lines ic = read_all ic read_line
end