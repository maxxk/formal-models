Variable (int double : Type).
Variable (Array : Type -> Type)
    (set : forall {T : Type}, Array T -> int -> T -> unit)
    (get : forall {T : Type}, Array T -> int -> T).
Variable (toInt : nat -> int) (toDouble : nat -> double).
Variable 
  (add sub div mul : double -> double -> double)
  (neg : double -> double)
  (inc dec : int -> int)
  (loop : int -> int -> (int -> unit) -> unit).

Definition tridiagonal (n : int) (d c e a b : Array double) (x : Array int) := (
  set a (toInt 1) (div (neg (get e (toInt 0))) (get d (toInt 0))),
  set b (toInt 1) (div (get b (toInt 0)) (get d (toInt 0))),

  loop (toInt 1) n (fun i => let 
    denominator := (add (get d i) (mul (get c i) (get a i))) in
    let body := (
      set a (inc i) (div (get e i) denominator),
      set b (inc i) (div (mul (sub (toDouble 1) (get c i)) (get b i)) denominator)
    )
    in tt),

  set x n (mul (mul (sub (toDouble 1) (get c n)) (get b n)) (add (get d n) (mul (get c n) (get a n)))),
  loop (dec n) (toInt 0) (fun j =>  let
    body := set x j (add (get b (inc j)) (mul (get a j) (get x (inc j))))
  in tt)
).