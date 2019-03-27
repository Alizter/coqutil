From Coq Require Import Strings.String Lists.List ZArith.BinInt.
From bedrock2 Require Import BasicC64Semantics ProgramLogic.

Require Import bedrock2.Examples.ARPResponder.

Import Datatypes List ListNotations.
Local Open Scope string_scope. Local Open Scope list_scope. Local Open Scope Z_scope.
Require Import bedrock2.NotationsInConstr.
From coqutil.Word Require Import Interface.

From bedrock2 Require Import Array Scalars Separation.
From coqutil.Tactics Require Import letexists rdelta.
Local Notation bytes := (array scalar8 (word.of_Z 1)).

Lemma word__if_zero (t:bool) (H : word.unsigned (if t then word.of_Z 1 else word.of_Z 0) = 0) : t = false. Admitted.
Lemma word__if_nonzero (t:bool) (H : word.unsigned (if t then word.of_Z 1 else word.of_Z 0) <> 0) : t = true. Admitted.

Set Printing Width 90.
Ltac seplog_use_array_load1 H i :=
  let iNat := eval cbv in (Z.to_nat i) in
  unshelve SeparationLogic.seprewrite_in @array_index_nat_inbounds H;
    [exact iNat|exact (word.of_Z 0)|Lia.lia|];
  change ((word.unsigned (word.of_Z 1) * Z.of_nat iNat)%Z) with i in *.

Local Instance spec_of_arp : spec_of "arp" := fun functions =>
  forall t m packet ethbuf len R,
    (sep (array scalar8 (word.of_Z 1) ethbuf packet) R) m ->
    word.unsigned len = Z.of_nat (length packet) ->
  WeakestPrecondition.call functions "arp" t m [ethbuf; len] (fun T M rets => True).
Goal program_logic_goal_for_function! arp.
  repeat straightline.
  letexists; split; [solve[repeat straightline]|]; split; [|solve[repeat straightline]]; repeat straightline.
  eapply word__if_nonzero in H1.
  rewrite word.unsigned_ltu, word.unsigned_of_Z, Z.mod_small in H1 by admit.
  eapply Z.ltb_lt in H1.
  repeat (letexists || straightline).
  split.
  1: repeat (split || letexists || straightline).
  Ltac tload := 
  lazymatch goal with |- Memory.load Syntax.access_size.one ?m (word.add ?base (word.of_Z ?i)) = Some ?v =>
  lazymatch goal with H: _ m |- _ =>
    let iNat := eval cbv in (Z.to_nat i) in
    SeparationLogic.seprewrite_in @array_index_nat_inbounds H;
    [instantiate (1 := iNat); Lia.lia|instantiate (1 := word.of_Z 0) in H];
    eapply load_one_of_sep;
    change (word.of_Z (word.unsigned (word.of_Z 1) * Z.of_nat iNat)) with (word.of_Z i) in *;
    SeparationLogic.ecancel_assumption
  end end.

  all:try tload.
  1: subst v0; exact eq_refl.
  split; [|solve[repeat straightline]]; repeat straightline.

  letexists; split; [|split; [|solve[repeat straightline]]].
  1: solve [repeat (split || letexists || straightline || tload)].

  repeat straightline.

  lazymatch goal with |- WeakestPrecondition.store Syntax.access_size.one ?m ?a ?v ?post =>
  lazymatch goal with H: _ m |- _ =>
    let av := rdelta a in
    let i := lazymatch av with word.add ?base (word.of_Z ?i) => i end in
    let iNat := eval cbv in (Z.to_nat i) in
    pose i;
    SeparationLogic.seprewrite_in @array_index_nat_inbounds H;
    [instantiate (1 := iNat); Lia.lia|instantiate (1 := word.of_Z 0) in H];
    eapply store_one_of_sep;
    change (word.of_Z (word.unsigned (word.of_Z 1) * Z.of_nat iNat)) with (word.of_Z i) in *;
    [SeparationLogic.ecancel_assumption|]
  end end.

  straightline.
  straightline.
  straightline.
  straightline.
  straightline.
  straightline.

  assert (length_firstn_inbounds : forall {T} n (xs : list T), le n (length xs) -> length (firstn n xs) = n). {
    intros.
    rewrite firstn_length, PeanoNat.Nat.min_comm.
    destruct (Min.min_spec (length xs) n); Lia.lia.
  }

  unshelve erewrite (_:a = word.add ethbuf (word.of_Z (Z.of_nat (length (firstn 21 packet))))) in H4. {
    rewrite length_firstn_inbounds by Lia.lia.
    trivial. }

  Check array.
  assert (array_snoc : forall {T} rep size a vsa b (vb:T)
                              (H:b = word.add a (word.of_Z (word.unsigned size * Z.of_nat (length vsa)) )),
             Lift1Prop.iff1 (sep (array rep size a vsa) (rep b vb)) (array rep size a (vsa ++ cons vb nil))). {
    clear. intros. subst b.
    etransitivity; [|symmetry; eapply Array.array_append].
    cbn [array]; SeparationLogic.cancel. }
  SeparationLogic.seprewrite_in @array_snoc H4.
  { change (word.unsigned (word.of_Z 1)) with 1; rewrite Z.mul_1_l; trivial. }

  assert (array_append_merge : forall {T} rep size start (xs ys : list T) start' (H: start' = (word.add start (word.of_Z (word.unsigned size * Z.of_nat (length xs))))),
            Lift1Prop.iff1 (sep (array rep size start xs) (array rep size start' ys)) (array rep size start (xs ++ ys))). {
    clear; intros; subst start'; symmetry; eapply array_append. }
  SeparationLogic.seprewrite_in @array_append_merge H4. {
    change (word.unsigned (word.of_Z 1)) with 1; rewrite Z.mul_1_l.
    rewrite app_length; cbn [length].
    rewrite length_firstn_inbounds by Lia.lia.
    change (Z.of_nat (21 + 1)) with 22.
    admit. (* wring *) }
 
Abort.
  