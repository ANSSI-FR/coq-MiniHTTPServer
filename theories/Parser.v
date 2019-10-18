From Coq Require Export String Ascii Program.Wf List.
From Prelude Require Export Control.
From Prelude Require Import State Classes Sum Equality Option.

Import ListNotations.
#[local] Open Scope string_scope.
#[local] Open Scope prelude_scope.

Generalizable All Variables.

#[global] Open Scope monad_scope.

Notation "x '>>' y" := (x >>= fun _ => y) (at level 74, right associativity).
Notation "x '<*' y" := (x >>= fun r => (y >> pure r)) (at level 74, right associativity).
Notation "x '*>' y" := (x >> y) (at level 74, right associativity).

Definition error_stack := list string.

Definition parser (a : Type) := state_t string (sum error_stack) a.

Definition parse {a} (parser : parser a) (input : string) : error_stack + a :=
  fst <$> (parser input).

Class Parser {a} (p : parser a) : Prop :=
  { is_parser (input : string) :
      match p input with
      | inl _ => True
      | inr (_, output) => String.length output <= String.length input
      end
  }.

Class StrictParser {a} (p : parser a) : Prop :=
  { is_strict (input : string) :
      match p input with
      | inl _ => True
      | inr (_, output) => String.length output < String.length input
      end
  }.

Lemma le_trans : forall n m p, n <= m -> m <= p -> n <= p.

Proof.
  induction 2.
  + auto.
  + now constructor.
Defined.

Lemma lt_trans : forall n m p, n < m -> m < p -> n < p.

Proof.
  induction 2.
  + constructor.
    apply H.
  + constructor.
    apply IHle.
Defined.

Lemma lt_le_incl (n m : nat)
  : n < m -> n <= m.
  revert n.
  induction m; intros n.
  + intros H.
    inversion H.
  + intros H.
    inversion H; subst.
    ++ induction m; auto.
    ++ apply IHm in H1.
       now constructor.
Defined.

Lemma lt_le_trans n m p : n < m -> m <= p -> n < p.

Proof.
  intros H1.
  revert p.
  induction H1; subst.
  intros p H1.
  + inversion H1.
    ++ constructor.
    ++ rewrite H0.
       apply H1.
  + intros p H2.
    apply IHle.
    apply le_trans with (m := S m).
    ++ repeat constructor.
    ++ exact H2.
Defined.

Lemma le_lt_trans n m p : n <= m -> m < p -> n < p.

Proof.
  intros H1.
  revert p.
  induction H1; subst.
  intros p H1.
  + exact H1.
  + intros p H2.
    apply IHle.
    apply lt_trans with (m := S m).
    constructor.
    exact H2.
Defined.

Ltac auto_parser :=
  match goal with
  | H : forall x, StrictParser (?f x) |- context[?f ?x ?input] =>
    case_eq (f x input); [ cbn; auto
                         | let y := fresh "y" in
                           let output := fresh "output" in
                           let equ := fresh "equ" in
                           intros [y output] equ;
                           cbn;
                           specialize H with x;
                           try auto_parser
                         ]
  | H : forall x, Parser (?f x) |- context[?f ?x ?input] =>
    case_eq (f x input); [ cbn; auto
                         | let y := fresh "y" in
                           let output := fresh "output" in
                           let equ := fresh "equ" in
                           intros [y output] equ;
                           cbn;
                           specialize H with x;
                           try auto_parser
                         ]
  | H : StrictParser ?p |- context[?p ?input] =>
    case_eq (p input); [ cbn; auto
                       | let x := fresh "x" in
                         let output := fresh "output" in
                         let equ := fresh "equ" in
                         intros [x output] equ;
                         cbn;
                         try auto_parser
                       ]
  | H : StrictParser ?p, equ : ?inr _ = ?p ?input |- _ =>
    symmetry in H;
    try auto_parser
  | H : StrictParser ?p, equ : ?p ?input = inr (_, ?output) |- String.length ?output <= String.length ?input =>
    assert (String.length output < String.length input) by auto_parser; now apply lt_le_incl
  | H : StrictParser ?p, equ : ?p ?input = inr (_, ?output) |- String.length ?output < String.length ?input =>
    let is_strict := fresh "is_strict" in
    destruct H as [is_strict];
    specialize is_strict with input;
    now rewrite equ in is_strict
  | Hp : StrictParser ?p, Hq : StrictParser ?q, equp : ?p ?input = inr (_, ?trans), equq : ?q ?trans = inr (_, ?output) |- String.length ?output <= String.length ?input  =>
    apply le_trans with (m := String.length trans); try auto_parser
  | Hp : Parser ?p, Hq : StrictParser ?q, equp : ?p ?input = inr (_, ?trans), equq : ?q ?trans = inr (_, ?output) |- String.length ?output < String.length ?input  =>
    apply (lt_le_trans _ (String.length trans) _); [ try auto_parser | try auto_parser ]
  | Hp : StrictParser ?p, Hq : Parser ?q, equp : ?p ?input = inr (_, ?trans), equq : ?q ?trans = inr (_, ?output) |- String.length ?output < String.length ?input  =>
    apply (le_lt_trans _ (String.length trans) _); [ try auto_parser | try auto_parser ]
  | H : forall x, Parser (?f x) |- context[?f ?x ?input] =>
    case_eq (f x input); [ cbn; auto
                         | let y := fresh "y" in
                           let output := fresh "output" in
                           let equ := fresh "equ" in
                           intros [y output] equ;
                           cbn;
                           specialize H with x;
                           try auto_parser
                         ]
  | H : Parser ?p |- context[?p ?input] =>
    case_eq (p input); [ cbn; auto
                       | let x := fresh "x" in
                         let output := fresh "output" in
                         let equ := fresh "equ" in
                         intros [x output] equ;
                         cbn;
                         try auto_parser
                       ]
  | H : Parser ?p, equ : ?inr _ = ?p ?input |- _ =>
    symmetry in H;
    try auto_parser
  | H : Parser ?p, equ : ?p ?input = inr (_, ?output) |- String.length ?output <= String.length ?input =>
    let is_parser := fresh "is_parser" in
    destruct H as [is_parser];
    specialize is_parser with input;
    now rewrite equ in is_parser
  | Hp : Parser ?p, Hq : Parser ?q, equp : ?p ?input = inr (_, ?trans), equq : ?q ?trans = inr (_, ?output) |- String.length ?output <= String.length ?input  =>
    apply le_trans with (m:=String.length trans); try auto_parser
  end.

#[program]
Instance strict_parser {a} (p : parser a) `{StrictParser a p} : Parser p.

Next Obligation.
  auto_parser.
Qed.

#[program]
Instance bind_parser `(Parser a p, (forall x, @Parser b (f x)))
  : Parser (p >>= f).

Next Obligation.
  auto_parser.
Qed.

(** Note: wrt. [bind] and [StrictParser], we provide two different instances
    whose goal is basically to find at least one strict parser in one of the two
    operands.

    We manually assign a priority so that (1) Coq prefers other instances first,
    and to be sure Coq first searches for a strict parser in the left operand of
    [bind] first.  This way, the parser is explored from the beginning of the
    parser up to the end, and not the other way around. *)

#[program]
Instance bind_strict_1 `(StrictParser a p, (forall x, @Parser b (f x)))
  : StrictParser (p >>= f)|10.

Next Obligation.
  auto_parser.
Qed.

#[program]
Instance bind_strict_2 `(Parser a p, (forall x, @StrictParser b (f x)))
  : StrictParser (p >>= f)|15.

Next Obligation.
  auto_parser.
Qed.

Definition with_context {a} (msg : string) (p : parser a) : parser a :=
  fun input =>
    match p input with
    | inl x => inl (msg :: x)
    | inr y => inr y
    end.

#[program]
Instance with_context_parser `(Parser a p) (msg : string)
  : Parser (with_context msg p).

Next Obligation.
  unfold with_context.
  auto_parser.
Qed.

#[program]
Instance with_context_strict `(StrictParser a p) (msg : string)
  : StrictParser (with_context msg p).

Next Obligation.
  unfold with_context.
  auto_parser.
Qed.

Definition alt {a} (p q : parser a) : parser a :=
  fun input =>
    match p input with
    | inr x => inr x
    | inl _ => q input
    end.

Notation "p '<|>' q" := (alt p q) (at level 50, left associativity).

#[program]
Instance alt_strict `(StrictParser a p, StrictParser a q)
  : StrictParser (p <|> q).

Next Obligation.
  unfold alt.
  auto_parser.
  intros e equ.
  auto_parser.
Qed.

#[program]
Instance alt_parser `(Parser a p, Parser a q)
  : Parser (p <|> q).

Next Obligation.
  unfold alt.
  auto_parser.
  intros.
  auto_parser.
Qed.

Definition fail {a} (msg : string) : parser a :=
  fun s => inl (msg :: nil).

#[program]
Instance fail_strict {a} (msg : string) : StrictParser (@fail a msg).

Definition read_char : parser ascii :=
  do var input <- get in
     match input with
     | String a rst => put rst >> pure a
     | EmptyString => fail "expected character, found end of input"
     end
  end.

#[program]
Instance pure_Parser {a} (x : a) : Parser (pure x).

#[program]
Instance get_Parser : Parser get.

#[program]
Instance read_char_strict : StrictParser read_char.

Next Obligation.
  cbn.
  destruct input.
  + now cbn.
  + cbn.
    constructor.
Qed.

Definition char (a : ascii) : parser ascii :=
  do var c <- read_char in
     if eqb a c
     then pure a
     else fail "expected a character, found another" (* todo: easy string interpolation *)
  end.

#[program]
Instance if_parser `(Parser a p, Parser a q) (cond : bool)
  : Parser (if cond then p else q).

Next Obligation.
  destruct cond; auto_parser.
Qed.

#[program]
Instance if_strict `(StrictParser a p, StrictParser a q) (cond : bool)
  : StrictParser (if cond then p else q).

Next Obligation.
  destruct cond; auto_parser.
Qed.

Remark char_strict (c : ascii) : StrictParser (char c).
typeclasses eauto.
Qed.

Fixpoint str_aux (a : string) : parser unit :=
  match a with
  | String c rst => char c *> str_aux rst
  | EmptyString => pure tt
  end.

Instance str_aux_parser (s : string) : Parser (str_aux s).

Proof.
  induction s.
  ++ apply pure_Parser.
  ++ change (str_aux (String a s)) with (char a *> str_aux s).
     apply bind_parser.
     +++ typeclasses eauto.
     +++ intros c.
         apply IHs.
Qed.

Instance str_aux_strict (a : ascii) (s : string)
  : StrictParser (str_aux (String a s)).

Proof.
  change (str_aux (String a s)) with (char a *> str_aux s).
  apply bind_strict_1; typeclasses eauto.
Qed.

Definition str (target : string) : parser string :=
  with_context "trying to consume a string" (str_aux target) *> pure target.

Theorem well_founded_lt_compat {a} (f : a -> nat) (R : a -> a -> Prop)
    (H_compat : forall (x y: a), R x y -> f x < f y)
  : well_founded R.
Proof.
  assert (H : forall n (x : a), f x < n -> Acc R x).
  { induction n.
    - intros. inversion H.
    - intros x Hx. apply Acc_intro. intros y Hy.
      apply IHn. apply lt_le_trans with (f x).
      now apply H_compat in Hy.
      inversion Hx; subst; auto.
      apply le_trans with (m:=S (f x)).
      repeat constructor.
      exact H0.
  }
  intros x. apply (H (S (f x))). constructor.
Defined.

Definition many_aux {a} (p : parser a) (H : StrictParser p)
  : string -> list a -> list a * string.
  refine (@Fix _
               (fun i1 i2 => String.length i1 < String.length i2)
               _
               _
               _).
  + eapply Wf_nat.well_founded_lt_compat.
    intros x y rec.
    eapply rec.
  + intros input func acc.
    case_eq (p input).
    ++ intros e equ.
       exact (rev acc, input).
    ++ intros [x output] equ.
       exact (func output ltac:(auto_parser) (x :: acc)).
Defined.

(** Note: we favor this implementation of [many] over
    [fun (input : string) => inr (many_aux nil p input)] because with the
    latter, Coq typeclass inference algorithm struggles _a lot_ when it finds a
    [many] combinator. *)

Definition many {a} (p : parser a) `{StrictParser a p} : parser (list a) :=
  fun (input : string) =>
    match many_aux p _ input nil with
    | (x, output) => inr (x, output)
    end.

#[program]
Instance many_parser `(StrictParser a p) : Parser (many p).

Next Obligation.
Admitted.

Definition some {a} (p : parser a) `{StrictParser a p} : parser (list a) :=
  do var x <- p in
     var rst <- many p in
     pure (x :: rst)
  end.

Remark some_parser `(StrictParser a p) : StrictParser p.

Proof.
  typeclasses eauto.
Qed.

Definition whitespaces : parser (list ascii) :=
  many (char " ").

Remark whitespaces_parser : Parser whitespaces.

Proof.
  typeclasses eauto.
Qed.

Definition ensure {a} (p : parser a) (cond : a -> bool) : parser a :=
  do var res <- p in
     if cond res
     then pure res
     else fail "ensure: result of p is not valid according to cond"
  end.

Remark ensure_parser `{Parser a p} (cond : a -> bool) : Parser (ensure p cond).

Proof.
typeclasses eauto.
Qed.

Remark ensure_strict `{StrictParser a p} (cond : a -> bool) : StrictParser (ensure p cond).

Proof.
  typeclasses eauto.
Qed.

Definition many_until_aux {a b} (p : parser a) (H : StrictParser p) (q : parser b)
  : string -> list a -> error_stack + (list a * string).
  refine (@Fix _ (fun i1 i2 => String.length i1 < String.length i2) _ _ _).
  + eapply well_founded_lt_compat.
    intros x y rec.
    eapply rec.
  + intros input func acc.
    case_eq (q input).
    ++ intros _ _.
       case_eq (p input).
       +++ intros _ _.
           exact (inl ["p failed before q could succeed"]).
       +++ intros [x output] equ.
           exact (func output ltac:(auto_parser) (x :: acc)).
    ++ intros [_ output] _.
       exact (inr (rev acc, output)).
Defined.

Definition many_until {a b} (p : parser a) `{StrictParser a p} (q : parser b)
  : parser (list a) :=
  fun input => many_until_aux p _ q input [].

#[program]
Instance many_until_parser `(StrictParser a p, Parser b q) : Parser (many_until p q).

Next Obligation.
Admitted.

#[program]
Instance many_until_strict `(StrictParser a p, StrictParser b q) : StrictParser (many_until p q).

Next Obligation.
Admitted.

Definition some_until {a b} (p : parser a) `{StrictParser a p} (q : parser b)
  : parser (list a) :=
  cons <$> p <*> many_until p q.

#[program]
Instance map_parser {b} `(Parser a p) (f : a -> b) : Parser (f <$> p).

Next Obligation.
  unfold state_map.
  case_eq (p input).
  + now cbn.
  + intros [x output] equ.
    cbn.
    destruct H as [is_parser].
    specialize is_parser with input.
    now rewrite equ in is_parser.
Qed.

#[program]
Instance map_strict {a b} (f : a -> b) `(StrictParser a p)
  : StrictParser (f <$> p).

Next Obligation.
  unfold state_map.
  case_eq (p input).
  + now cbn.
  + intros [x output] equ.
    cbn.
    destruct H as [is_strict].
    specialize is_strict with input.
    now rewrite equ in is_strict.
Qed.

#[program]
Instance app_parser `(Parser (a -> b) f, Parser a p) : Parser (f <*> p).

Next Obligation.
  auto_parser.
Qed.

#[program]
Instance app_strict_1 `(StrictParser (a -> b) f, Parser a p) : StrictParser (f <*> p).

Next Obligation.
  auto_parser.
Qed.

#[program]
Instance app_strict_2 `(Parser (a -> b) f, StrictParser a p) : StrictParser (f <*> p).

Next Obligation.
  auto_parser.
Qed.

Instance some_until_strict `(StrictParser a p, Parser b q) : StrictParser (some_until p q).

Proof.
  typeclasses eauto.
Qed.

Definition eoi : parser unit :=
  ensure (String.length <$> get) (Nat.eqb 0) >> pure tt.

#[program]
Instance eoi_parser : Parser eoi.

Next Obligation.
  induction input; now cbn.
Qed.

Definition peek {a} (p : parser a) : parser a :=
  fun (input : string) =>
    match p input with
    | inl x => inl x
    | inr (x, _) => inr (x, input)
    end.

#[program]
Instance peek_parser {a} (p : parser a) : Parser (peek p).

Next Obligation.
  unfold peek.
  destruct (p input) as [ _ | [x output] ]; auto.
Qed.
