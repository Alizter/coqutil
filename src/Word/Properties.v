Require Import Coq.ZArith.BinInt.
Require Import coqutil.Z.div_mod_to_equations.
Require Import coqutil.Z.Lia Btauto.
Require Coq.setoid_ring.Ring_theory.
Require Import coqutil.Z.bitblast.
Require Import coqutil.Word.Interface. Import word.

Local Set Universe Polymorphism.
Local Open Scope Z_scope.

Local Ltac mia := Z.div_mod_to_equations; Lia.nia.

Module word.
  (* Create HintDb word_laws discriminated. *) (* DON'T do this, COQBUG(5381) *)
  Hint Rewrite
       @unsigned_of_Z @signed_of_Z @of_Z_unsigned @unsigned_add @unsigned_sub @unsigned_opp @unsigned_or @unsigned_and @unsigned_xor @unsigned_not @unsigned_ndn @unsigned_mul @signed_mulhss @signed_mulhsu @unsigned_mulhuu @unsigned_divu @signed_divs @unsigned_modu @signed_mods @unsigned_slu @unsigned_sru @signed_srs @unsigned_eqb @unsigned_ltu @signed_lts
       using trivial
  : word_laws.
  Section WithWord.
    Context {width} {word : word width} {word_ok : word.ok word}.

    Lemma wrap_unsigned x : (unsigned x) mod (2^width) = unsigned x.
    Proof.
      pose proof unsigned_of_Z (unsigned x) as H.
      rewrite of_Z_unsigned in H. congruence.
    Qed.

    Lemma unsigned_inj x y (H : unsigned x = unsigned y) : x = y.
    Proof. rewrite <-(of_Z_unsigned x), <-(of_Z_unsigned y). apply f_equal, H. Qed.

    Lemma signed_eq_swrap_unsigned x : signed x = swrap (unsigned x).
    Proof. cbv [wrap]; rewrite <-signed_of_Z, of_Z_unsigned; trivial. Qed.

    Lemma width_nonneg : 0 <= width. pose proof width_pos. blia. Qed.
    Let width_nonneg_context : 0 <= width. apply width_nonneg. Qed.
    Let m_small : 0 < 2^width. apply Z.pow_pos_nonneg; firstorder idtac. Qed.

    Lemma unsigned_range x : 0 <= unsigned x < 2^width.
    Proof. rewrite <-wrap_unsigned. mia. Qed.

    Lemma ring_theory : Ring_theory.ring_theory (of_Z 0) (of_Z 1) add mul sub opp Logic.eq.
    Proof.
     split; intros; apply unsigned_inj; repeat rewrite ?wrap_unsigned,
         ?unsigned_add, ?unsigned_sub, ?unsigned_opp, ?unsigned_mul, ?unsigned_of_Z,
         ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r, ?Z.mul_mod_idemp_l, ?Z.mul_mod_idemp_r,
         ?Z.add_0_l, ?(Z.mod_small 1), ?Z.mul_1_l;
       f_equal; auto with zarith.
    Qed.

    Lemma ring_morph :
      Ring_theory.ring_morph (of_Z 0) (of_Z 1) add mul sub opp Logic.eq 0  1 Z.add Z.mul Z.sub Z.opp Z.eqb of_Z.
    Proof.
     split; intros; apply unsigned_inj; repeat rewrite  ?wrap_unsigned,
         ?unsigned_add, ?unsigned_sub, ?unsigned_opp, ?unsigned_mul, ?unsigned_of_Z,
         ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r, ?Z.mul_mod_idemp_l, ?Z.mul_mod_idemp_r,
         ?Zdiv.Zminus_mod_idemp_l, ?Zdiv.Zminus_mod_idemp_r,
         ?Z.sub_0_l, ?Z.add_0_l, ?(Z.mod_small 1), ?Z.mul_1_l by auto with zarith;
       try solve [f_equal; auto with zarith].
     { rewrite <-Z.sub_0_l; symmetry; rewrite <-Z.sub_0_l, Zdiv.Zminus_mod_idemp_r. auto. } (* COQBUG? *)
     { f_equal. eapply Z.eqb_eq. auto. } (* Z.eqb -> @eq z *)
    Qed.

    Ltac generalize_wrap_unsigned :=
      repeat match goal with
             | x : @word.rep ?a ?b |- _ =>
               rewrite <-(wrap_unsigned x);
               let x' := fresh in
               set (unsigned x) as x' in *; clearbody x'; clear x; rename x' into x
             end.

    Lemma unsigned_mulhuu_nowrap x y : unsigned (mulhuu x y) = Z.mul (unsigned x) (unsigned y) / 2^width.
    Proof. autorewrite with word_laws; generalize_wrap_unsigned; rewrite Z.mod_small; mia. Qed.
    Lemma unsigned_divu_nowrap x y (H:unsigned y <> 0) : unsigned (divu x y) = Z.div (unsigned x) (unsigned y).
    Proof. autorewrite with word_laws; generalize_wrap_unsigned; rewrite Z.mod_small; mia. Qed.
    Lemma unsigned_modu_nowrap x y (H:unsigned y <> 0) : unsigned (modu x y) = Z.modulo (unsigned x) (unsigned y).
    Proof. autorewrite with word_laws; generalize_wrap_unsigned; rewrite Z.mod_small; mia. Qed.

    Ltac bitwise :=
      autorewrite with word_laws;
      generalize_wrap_unsigned;
      Z.bitblast.

    Lemma unsigned_or_nowrap x y : unsigned (or x y) = Z.lor (unsigned x) (unsigned y).
    Proof. bitwise. Qed.
    Lemma unsigned_and_nowrap x y : unsigned (and x y) = Z.land (unsigned x) (unsigned y).
    Proof. bitwise. Qed.
    Lemma unsigned_xor_nowrap x y : unsigned (xor x y) = Z.lxor (unsigned x) (unsigned y).
    Proof. bitwise. Qed.
    Lemma unsigned_ndn_nowrap x y : unsigned (ndn x y) = Z.ldiff (unsigned x) (unsigned y).
    Proof. bitwise. Qed.
    Lemma unsigned_sru_nowrap x y (H:unsigned y < width) : unsigned (sru x y) = Z.shiftr (unsigned x) (unsigned y).
    Proof.
      pose proof unsigned_range y.
      rewrite unsigned_sru by blia.
      rewrite <-(wrap_unsigned x).
      Z.bitblast.
    Qed.

    Lemma testbit_wrap z i : Z.testbit (wrap z) i = ((i <? width) && Z.testbit z i)%bool.
    Proof. cbv [wrap]. Z.rewrite_bitwise; trivial. Qed.

    Lemma eqb_true: forall (a b: word), word.eqb a b = true -> a = b.
    Proof.
      intros.
      rewrite word.unsigned_eqb in H. rewrite Z.eqb_eq in H. apply unsigned_inj in H.
      assumption.
    Qed.

    Lemma eqb_eq: forall (a b: word), a = b -> word.eqb a b = true.
    Proof.
      intros. subst. rewrite unsigned_eqb. apply Z.eqb_refl.
    Qed.

    Lemma eqb_false: forall (a b: word), word.eqb a b = false -> a <> b.
    Proof.
      intros. intro. rewrite eqb_eq in H; congruence.
    Qed.

    Lemma eqb_ne: forall (a b: word), a <> b -> word.eqb a b = false.
    Proof.
      intros. destruct (word.eqb a b) eqn: E; try congruence.
      exfalso. apply H. apply eqb_true in E. assumption.
    Qed.

    Lemma eqb_spec(a b: word): BoolSpec (a = b) (a <> b) (word.eqb a b).
    Proof.
      destruct (eqb a b) eqn: E; constructor.
      - eauto using eqb_true.
      - eauto using eqb_false.
    Qed.

    Lemma eq_or_neq (k1 k2 : word) : k1 = k2 \/ k1 <> k2.
    Proof. destruct (word.eqb k1 k2) eqn:H; [eapply eqb_true in H | eapply eqb_false in H]; auto. Qed.
  End WithWord.

  Section WithNontrivialWord.
    Context {width} {word : word width} {word_ok : word.ok word}.
    Let width_nonzero : 0 < width. apply width_pos. Qed.
    Let halfm_small : 0 < 2^(width-1). apply Z.pow_pos_nonneg; auto with zarith. Qed.
    Let twice_halfm : 2^(width-1) * 2 = 2^width.
    Proof. rewrite Z.mul_comm, <-Z.pow_succ_r by blia; f_equal; blia. Qed.

    Lemma signed_range x : -2^(width-1) <= signed x < 2^(width-1).
    Proof.
      rewrite signed_eq_swrap_unsigned. cbv [swrap].
      rewrite <-twice_halfm. mia.
    Qed.

    Lemma swrap_inrange z (H : -2^(width-1) <= z < 2^(width-1)) : swrap z = z.
    Proof. cbv [swrap]; rewrite Z.mod_small; blia. Qed.

    Lemma swrap_as_div_mod z : swrap z = z mod 2^(width-1) - 2^(width-1) * (z / (2^(width - 1)) mod 2).
    Proof.
      symmetry; cbv [swrap wrap].
      replace (2^width) with ((2 ^ (width - 1) * 2))
        by (rewrite Z.mul_comm, <-Z.pow_succ_r by blia; f_equal; blia).
      replace (z + 2^(width-1)) with (z + 1*2^(width-1)) by blia.
      rewrite Z.rem_mul_r, ?Z.div_add, ?Z.mod_add, (Z.add_mod _ 1 2), Zdiv.Zmod_odd by blia.
      destruct (Z.odd _); cbn; blia.
    Qed.

    Lemma signed_add x y : signed (add x y) = swrap (Z.add (signed x) (signed y)).
    Proof.
      rewrite !signed_eq_swrap_unsigned; autorewrite with word_laws.
      cbv [wrap swrap]. rewrite <-(wrap_unsigned x), <-(wrap_unsigned y).
      replace (2 ^ width) with (2*2 ^ (width - 1)) by
        (rewrite <-Z.pow_succ_r, Z.sub_1_r, Z.succ_pred; blia).
      set (M := 2 ^ (width - 1)) in*; clearbody M.
      assert (0<2*M) by Lia.nia.
      rewrite <-!Z.add_opp_r.
      repeat rewrite ?Z.add_assoc, ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r, ?(Z.add_shuffle0 _ (_ mod _)) by blia.
      rewrite 4(Z.add_comm (_ mod _)).
      repeat rewrite ?Z.add_assoc, ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r, ?(Z.add_shuffle0 _ (_ mod _)) by blia.
      f_equal; f_equal; blia.
    Qed.

    Lemma signed_sub x y : signed (sub x y) = swrap (Z.sub (signed x) (signed y)).
    Proof.
      (* Z.push_modulo; Z.pull_modulo; f_equal; blia. *)
      rewrite !signed_eq_swrap_unsigned; autorewrite with word_laws.
      cbv [wrap swrap]; rewrite <-(wrap_unsigned x), <-(wrap_unsigned y).
      replace (2 ^ width) with (2*2 ^ (width - 1)) by
        (rewrite <-Z.pow_succ_r, Z.sub_1_r, Z.succ_pred; blia).
      set (M := 2 ^ (width - 1)) in*; clearbody M.
      assert (0<2*M) by Lia.nia.
      rewrite <-!Z.add_opp_r.
      repeat rewrite ?Z.add_assoc, ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r, ?(Z.add_shuffle0 _ (_ mod _)) by blia.
      rewrite !(Z.add_comm (_ mod _)).
      repeat rewrite ?Z.add_assoc, ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r, ?(Z.add_shuffle0 _ (_ mod _)) by blia.
      replace (-(unsigned y mod (2 * M))+M+unsigned x) with (M+unsigned x-(unsigned y mod(2*M))) by blia.
      replace (-M+-(-M+(unsigned y+M) mod (2*M))+M+unsigned x+M) with (-M+M+unsigned x+M+M-(unsigned y+M)mod(2*M)) by blia.
      rewrite 2Zdiv.Zminus_mod_idemp_r; f_equal; f_equal; blia.
    Qed.

    Lemma signed_opp x : signed (opp x) = swrap (Z.opp (signed x)).
    Proof.
      (* Z.push_modulo; Z.pull_modulo; f_equal; blia. *)
      rewrite !signed_eq_swrap_unsigned; autorewrite with word_laws.
      cbv [wrap swrap]; rewrite <-(wrap_unsigned x).
      replace (2 ^ width) with (2*2 ^ (width - 1)) by
        (rewrite <-Z.pow_succ_r, Z.sub_1_r, Z.succ_pred; blia).
      set (M := 2 ^ (width - 1)) in*; clearbody M.
      rewrite <-!Z.add_opp_r.
      repeat rewrite ?Z.add_assoc, ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r, ?(Z.add_shuffle0 _ (_ mod _)) by blia.
      replace (- (unsigned x mod (2 * M)) + M) with (M - unsigned x mod (2 * M)) by blia.
      replace (- ((unsigned x + M) mod (2 * M) + - M) + M) with (M+M-(unsigned x+M) mod (2*M)) by blia.
      rewrite ?Zdiv.Zminus_mod_idemp_r; f_equal; f_equal; blia.
    Qed.

    Lemma signed_mul x y : signed (mul x y) = swrap (Z.mul (signed x) (signed y)).
    Proof.
      (* Z.push_modulo; Z.pull_modulo; f_equal; blia. *)
      rewrite !signed_eq_swrap_unsigned; autorewrite with word_laws.
      cbv [wrap swrap]. rewrite <-(wrap_unsigned x), <-(wrap_unsigned y).
      replace (2 ^ width) with (2*2 ^ (width - 1)) by
        (rewrite <-Z.pow_succ_r, Z.sub_1_r, Z.succ_pred; blia).
      set (M := 2 ^ (width - 1)) in*; clearbody M.
      assert (0<2*M) by Lia.nia.
      f_equal.
      symmetry.
      rewrite <-Z.add_mod_idemp_l by blia.
      rewrite Z.mul_mod by blia.
      rewrite <-!Z.add_opp_r.
      rewrite ?Z.add_mod_idemp_l, ?Z.add_mod_idemp_r by blia.
      rewrite !Z.add_opp_r.
      rewrite !Z.add_simpl_r.
      rewrite !Z.mod_mod by blia.
      trivial.
    Qed.

    Lemma testbit_swrap z i : Z.testbit (swrap z) i
                              = if i <? width
                                then Z.testbit (wrap z) i
                                else Z.testbit (wrap z) (width -1).
    Proof.
      destruct (ZArith_dec.Z_lt_le_dec i 0).
      { destruct (Z.ltb_spec i width); rewrite ?Z.testbit_neg_r by blia; trivial. }
      rewrite swrap_as_div_mod. cbv [wrap].
      rewrite <-Z.testbit_spec' by blia.
      rewrite <-Z.add_opp_r.
      rewrite Z.add_nocarry_lxor; cycle 1.
      { destruct (Z.testbit z (width - 1)) eqn:Hw1; cbn [Z.b2z];
          rewrite ?Z.mul_1_r, ?Z.mul_0_r, ?Z.opp_0, ?Z.add_0_r, ?Z.land_0_r;
          [|solve[trivial]].
        Z.bitblast. }
      autorewrite with z_bitwise_no_hyps z_bitwise_with_hyps;
      destruct (Z.testbit z (width - 1)) eqn:Hw1; cbn [Z.b2z];
        rewrite ?Z.mul_1_r, ?Z.mul_0_r, ?Z.opp_0, ?Z.add_0_r, ?Z.land_0_r;
        autorewrite with z_bitwise_no_hyps z_bitwise_with_hyps; cbn [Z.pred];
        destruct (Z.ltb_spec i (width-1)), (Z.ltb_spec i width); cbn; blia || btauto || trivial.
      { assert (i = width-1) by blia; congruence. }
      { destruct (Z.ltb_spec (width-1) width); blia || btauto. }
      { assert (i = width-1) by blia; congruence. }
    Qed.

    Lemma testbit_signed x i : Z.testbit (signed x) i
                               = if i <? width
                                 then Z.testbit (unsigned x) i
                                 else Z.testbit (unsigned x) (width -1).
    Proof.
      rewrite <-wrap_unsigned, signed_eq_swrap_unsigned.
      eapply testbit_swrap; assumption.
    Qed.

    Hint Rewrite testbit_signed testbit_wrap testbit_swrap
         using solve [auto with zarith] : z_bitwise_signed.

    Ltac sbitwise :=
      eapply Z.bits_inj'; intros ?i ?Hi;
      autorewrite with word_laws z_bitwise_signed z_bitwise_no_hyps z_bitwise_with_hyps;
      repeat match goal with |- context [?a <? ?b] =>
        destruct (Z.ltb_spec a b); trivial; try blia
      end.

    Lemma swrap_signed x : swrap (signed x) = signed x.
    Proof. rewrite signed_eq_swrap_unsigned. sbitwise. Qed.

    Lemma signed_or x y (H : Z.lt (unsigned y) width) : signed (or x y) = swrap (Z.lor (signed x) (signed y)).
    Proof. sbitwise. Qed.
    Lemma signed_and x y : signed (and x y) = swrap (Z.land (signed x) (signed y)).
    Proof. sbitwise. Qed.
    Lemma signed_xor x y : signed (xor x y) = swrap (Z.lxor (signed x) (signed y)).
    Proof. sbitwise. Qed.
    Lemma signed_not x : signed (not x) = swrap (Z.lnot (signed x)).
    Proof. sbitwise. Qed.
    Lemma signed_ndn x y : signed (ndn x y) = swrap (Z.ldiff (signed x) (signed y)).
    Proof. sbitwise. Qed.

    Lemma signed_or_nowrap x y (H : Z.lt (unsigned y) width) : signed (or x y) = Z.lor (signed x) (signed y).
    Proof. sbitwise. Qed.
    Lemma signed_and_nowrap x y : signed (and x y) = Z.land (signed x) (signed y).
    Proof. sbitwise. Qed.
    Lemma signed_xor_nowrap x y : signed (xor x y) = Z.lxor (signed x) (signed y).
    Proof. sbitwise. Qed.
    Lemma signed_not_nowrap x : signed (not x) = Z.lnot (signed x).
    Proof. sbitwise. Qed.
    Lemma signed_ndn_nowrap x y : signed (ndn x y) = Z.ldiff (signed x) (signed y).
    Proof. sbitwise. Qed.

    Lemma signed_srs_nowrap x y (H:unsigned y < width) : signed (srs x y) = Z.shiftr (signed x) (unsigned y).
    Proof.
      pose proof @unsigned_range _ _ word_ok y; sbitwise.
      replace (unsigned y) with 0 by blia; rewrite Z.add_0_r; trivial.
    Qed.

    Lemma signed_mulhss_nowrap x y : signed (mulhss x y) = Z.mul (signed x) (signed y) / 2^width.
    Proof. rewrite signed_mulhss. apply swrap_inrange. pose (signed_range x); pose (signed_range y). mia. Qed.
    Lemma signed_mulhsu_nowrap x y : signed (mulhsu x y) = Z.mul (signed x) (unsigned y) / 2^width.
    Proof. rewrite signed_mulhsu. apply swrap_inrange. pose (signed_range x); pose (@unsigned_range _ _ word_ok y). mia. Qed.
    Lemma signed_divs_nowrap x y (H:signed y <> 0) (H0:signed x <> -2^(width-1) \/ signed y <> -1) : signed (divs x y) = Z.quot (signed x) (signed y).
    Proof.
      rewrite signed_divs by assumption. apply swrap_inrange.
      rewrite Z.quot_div by assumption. pose proof (signed_range x).
      destruct (Z.sgn_spec (signed x)) as [[? X]|[[? X]|[? X]]];
      destruct (Z.sgn_spec (signed y)) as [[? Y]|[[? Y]|[? Y]]].
      1: rewrite ?X, ?Y; rewrite ?Z.abs_eq, ?Z.abs_neq by blia; mia.
      1: rewrite ?X, ?Y; rewrite ?Z.abs_eq, ?Z.abs_neq by blia; mia.
      {
        rewrite ?X, ?Y.
        rewrite Z.abs_eq by blia.
        rewrite Z.abs_eq; cycle 1. {
          (* omega fails ~8x faster than lia *)
          Time do 100 (try Lia.lia). (* 0.462 secs *)
          Time do 100 (try Omega.omega). (* 0.055 secs *)
    Admitted.

    Lemma signed_mods_nowrap x y (H:signed y <> 0) : signed (mods x y) = Z.rem (signed x) (signed y).
    Proof.
      rewrite signed_mods by assumption. apply swrap_inrange.
      rewrite Z.rem_mod by assumption.
      pose (signed_range x); pose (signed_range y).
      destruct (Z.sgn_spec (signed x)) as [[? X]|[[? X]|[? X]]];
      destruct (Z.sgn_spec (signed y)) as [[? Y]|[[? Y]|[? Y]]];
      rewrite ?X, ?Y; repeat rewrite ?Z.abs_eq, ?Z.abs_neq by blia; mia.
    Qed.

    Lemma signed_inj x y (H : signed x = signed y) : x = y.
    Proof.
      eapply unsigned_inj, Z.bits_inj'; intros i Hi.
      eapply (f_equal (fun z => Z.testbit z i)) in H.
      rewrite 2testbit_signed in H. rewrite <-(wrap_unsigned x), <-(wrap_unsigned y).
      autorewrite with word_laws z_bitwise_signed z_bitwise_no_hyps z_bitwise_with_hyps.
      destruct (Z.ltb_spec i width); auto.
    Qed.

    Lemma signed_eqb x y : eqb x y = Z.eqb (signed x) (signed y).
    Proof.
      rewrite unsigned_eqb.
      destruct (Z.eqb_spec (unsigned x) (unsigned y)) as [?e|?];
        destruct (Z.eqb_spec (  signed x) (  signed y)) as [?e|?];
        try (apply unsigned_inj in e || apply signed_inj in e); congruence.
    Qed.
  End WithNontrivialWord.
End word.

Require Import coqutil.Decidable.

Instance word_eq_dec{width: Z}(word: word.word width){word_ok: word.ok word}: DecidableEq word.
intros. destruct (word.eqb x y) eqn: E.
- left. apply word.eqb_true. assumption.
- right. apply word.eqb_false. assumption.
Defined.
