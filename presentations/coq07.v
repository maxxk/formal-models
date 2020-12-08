Variable (int double : Type).
Variable (Array : Type -> nat -> Type)
    (set : forall {T : Type} {n : nat}, Array T n -> forall (i : nat), i < n -> T -> unit)
    (get : forall {T : Type} {n : nat}, Array T n -> forall (i : nat), i < n -> T).
Variable (toInt : nat -> int) (toDouble : nat -> double).
Variable 
  (add sub div mul : double -> double -> double)
  (neg : double -> double)
  (inc dec : int -> int)
  (loop : int -> int -> (int -> unit) -> unit).

Require Import Coq.Program.Tactics.
Program Definition tridiagonal (n : nat) (d : Array double (S n)) (c e a b : Array double n) (x : Array int (S n)) := (
  set a 1 _ (div (neg (get e 0 _)) (get d 0 _))

).
Obligation 1. Admitted.
Obligation 2. Admitted.
Obligation 3. unfold lt. Search (le). apply le_n_S. apply le_0_n. Qed.


Search (le). auto with *. Search le. induction n. induction n. auto. auto. apply le_0_n. auto with *.
  set b 1 (div (get b (toInt 0)) (get d (toInt 0))),

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