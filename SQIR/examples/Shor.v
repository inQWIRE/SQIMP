Require Import Reals Psatz ZArith Znumtheory.
Require Export VectorStates QPE QPEGeneral.

Local Close Scope R_scope.

Local Coercion INR : nat >-> R.
Local Coercion Z.of_nat : nat >-> BinNums.Z.

(* r is the order of a modulo p *)
Definition Order (a r N : nat) :=
  0 < r /\
  a^r mod N = 1 /\
  (forall r' : nat, (0 < r' /\ a^r' mod N = 1) -> r' >= r).

Lemma Order_N_lb :
  forall a r N,
    Order a r N ->
    1 < N.
Proof.
  intros. 
  destruct (0 <? N)%nat eqn:E.
  - destruct (1 <? N)%nat eqn:S.
    + apply Nat.ltb_lt in S; easy.
    + apply Nat.ltb_ge in S. destruct H as [_ [? _]].
      apply Nat.ltb_lt in E. replace N with 1%nat in H by omega. simpl in H. discriminate H.
  - apply Nat.ltb_ge in E. assert (N=0) by omega. destruct H as [_ [? _]]. rewrite H0 in H. simpl in H. omega.
Qed.

Lemma Order_a_nonzero :
  forall a r N,
    Order a r N ->
    0 < a.
Proof.
  intros. assert (HN := H). apply Order_N_lb in HN.
  destruct (0 <? a)%nat eqn:E.
  - apply Nat.ltb_lt in E; easy.
  - apply Nat.ltb_ge in E. assert (a=0) by omega. destruct H as [? [? _]]. rewrite H0 in H1. rewrite Nat.pow_0_l in H1. rewrite Nat.mod_0_l in H1 by omega. omega. omega.
Qed.

Lemma Order_a_inv_ex :
  forall a r N,
    Order a r N ->
    exists a_inv,
      (a * a_inv) mod N = 1.
Proof.
  intros. exists (a^(pred r))%nat. destruct H as [? [? _]].
  assert (a * a ^ Init.Nat.pred r = a^1 * a^(Init.Nat.pred r))%nat. rewrite Nat.pow_1_r; easy. rewrite H1.
  rewrite <- Nat.pow_add_r. rewrite Nat.succ_pred; omega.
Qed.

Lemma inv_pow :
  forall a r N a_inv x,
    Order a r N ->
    (a * a_inv) mod N = 1 ->
    (a^x * a_inv^x) mod N = 1.
Proof.
  intros. assert (HN := H). apply Order_N_lb in HN. induction x.
  - simpl. apply Nat.mod_1_l. easy.
  - simpl. rewrite Nat.mul_assoc. rewrite (Nat.mul_shuffle0 a (a^x)%nat a_inv).
    rewrite mult_assoc_reverse with (n:=(a * a_inv)%nat). rewrite <- Nat.mul_mod_idemp_l with (a:=(a * a_inv)%nat); try omega. rewrite H0. rewrite Nat.mul_1_l. apply IHx.
Qed.

Lemma Pow_minus_aux :
  forall a r N a_inv x d,
    Order a r N ->
    (a * a_inv) mod N = 1 ->
    a^d mod N = (a^(x + d) * a_inv^x) mod N.
Proof.
  intros. replace (x + d)%nat with (d + x)%nat by omega. rewrite Nat.pow_add_r.
  assert (HN := H). apply Order_N_lb in HN.
  rewrite <- Nat.mul_assoc. rewrite <- Nat.mul_mod_idemp_r; try omega. rewrite inv_pow with (r:=r); auto. rewrite Nat.mul_1_r. easy.
Qed.

Lemma Pow_minus :
  forall a r N a_inv x1 x2,
    Order a r N ->
    x1 <= x2 ->
    (a * a_inv) mod N = 1 ->
    a^(x2-x1) mod N = (a^x2 * a_inv^x1) mod N.
Proof.
  intros. rewrite Pow_minus_aux with (r:=r) (a:=a) (x:=x1) (a_inv:=a_inv); try easy. replace (x1 + (x2 - x1))%nat with (x2 - x1 + x1)%nat by omega. rewrite Nat.sub_add; easy.
Qed.

Lemma Pow_diff :
  forall a r N x1 x2,
    Order a r N ->
    0 <= x1 < r ->
    0 <= x2 < r ->
    x1 < x2 ->
    a^x1 mod N <> a^x2 mod N.
Proof.
  intros. intro.
  assert (Ha_inv := H). apply Order_a_inv_ex in Ha_inv. destruct Ha_inv as [a_inv Ha_inv].
  assert (HN := H). apply Order_N_lb in HN.
  assert (a^(x2-x1) mod N = 1).
  rewrite Pow_minus with (r:=r) (a_inv:=a_inv); try omega; try easy.
  rewrite <- Nat.mul_mod_idemp_l; try omega.
  rewrite <- H3. rewrite Nat.mul_mod_idemp_l; try omega.
  rewrite <- Pow_minus with (r:=r); try omega; try easy.
  rewrite Nat.sub_diag. simpl. apply Nat.mod_1_l; easy.
  destruct H as [_ [_ Hminimal]].
  pose (Hminimal (x2 - x1)%nat) as Hcounter.
  assert (0 < x2 - x1 /\ a ^ (x2 - x1) mod N = 1)%nat by omega.
  apply Hcounter in H. omega.
Qed.

Lemma Pow_diff_neq :
  forall a r N x1 x2,
    Order a r N ->
    0 <= x1 < r ->
    0 <= x2 < r ->
    x1 <> x2 ->
    a^x1 mod N <> a^x2 mod N.
Proof.
  intros. apply not_eq in H2. destruct H2.
  - apply Pow_diff with (r:=r); easy.
  - apply not_eq_sym. apply Pow_diff with (r:=r); easy.
Qed.


Lemma Pow_pos :
    forall (a r N i : nat),
      Order a r N ->
        a^i mod N > 0.
Proof.
  intros. unfold gt. destruct (Nat.lt_ge_cases 0 (a ^ i mod N)). easy.
  inversion H0.  exfalso. cut (a^r mod N = 0).
  intros. destruct H as (Ha & Hb & Hc). omega.
  assert (N <> 0).
  { assert (1 < N). { apply (Order_N_lb a r _). easy. } omega. }
  destruct (Nat.lt_ge_cases i r).
  - assert (r = (i + (r - i))%nat) by omega.
    rewrite H4. rewrite -> Nat.pow_add_r. rewrite Nat.mul_mod. rewrite H2. simpl.
    apply Nat.mod_0_l.
    easy. easy.
  - assert (r = (i - (i - r))%nat) by omega.
    rewrite H4. pose (Order_a_inv_ex a r N H). destruct e.
    rewrite (Pow_minus _ r _ x _ _); try easy; try omega.
    rewrite Nat.mul_mod. rewrite H2. simpl.
    apply Nat.mod_0_l. easy. easy.
Qed.

(* from https://gist.github.com/jorpic/bf37de156f48ea438076 *)
Lemma nex_to_forall : forall k n x : nat, forall f,
 (~exists k, k < n /\ f k = x) -> k < n -> f k <> x.
Proof.
  intros k n x f H_nex H_P H_Q. 
  apply H_nex; exists k; auto.
Qed.

(* from https://gist.github.com/jorpic/bf37de156f48ea438076 *)
Lemma exists_or_not :
  forall n x : nat, forall f : nat -> nat,
    (exists k, k < n /\ f k = x) \/ (~exists k, k < n /\ f k = x).
Proof.
  intros n x f.
  induction n.
  - right. intro H_ex.
    destruct H_ex as [k [Hk Hf]]. easy.
  - destruct IHn as [H_ex | H_nex].
    + destruct H_ex as [k [H_kn H_fk]].
      left; exists k; auto.
    + destruct (eq_nat_dec (f n) x) as [H_fn_eqx | H_fn_neq_x].
      * left; exists n; auto.
      * right. intro H_nex'.
        destruct H_nex' as [k [H_kn H_fk]].
        apply H_fn_neq_x.
        apply lt_n_Sm_le in H_kn.
        apply le_lt_or_eq in H_kn.
        destruct H_kn as [H_lt | H_eq]. 
        - contradict H_fk.
          apply (nex_to_forall k n x f H_nex H_lt).
        - rewrite <- H_eq; assumption.
Qed.

(* from https://gist.github.com/jorpic/bf37de156f48ea438076 *)
Theorem pigeonhole
    :  forall n : nat, forall f : nat -> nat, (forall i, i <= n -> f i < n)
    -> exists i j, i <= n /\ j < i /\ f i = f j.
Proof.
  induction n.
  - intros f Hf.
    specialize (Hf 0 (le_refl 0)). easy.
  - intros f Hf.
    destruct (exists_or_not (n+1) (f (n+1)%nat) f) as [H_ex_k | H_nex_k].
    + destruct H_ex_k as [k [Hk_le_Sn Hfk]].
      exists (n+1)%nat, k.
      split; [omega | split; [assumption | rewrite Hfk; reflexivity]].
    + set (g := fun x => if eq_nat_dec (f x) n then f (n+1)%nat else f x).
      assert (forall i : nat, i <= n -> g i < n).
      { intros. unfold g.
        destruct (eq_nat_dec (f i) n).
        - apply nex_to_forall with (k := i) in H_nex_k. 
          + specialize (Hf (n+1)%nat); omega.
          + omega.
        - specialize (Hf i); omega.
      }
      destruct (IHn g H) as [x H0].
      destruct H0 as [y [H1 [H2 H3]]].
      exists x, y. split; [omega | split ; [assumption | idtac]].
      (* lemma g x = g y -> f x = f y *)
      unfold g in H3.
      destruct eq_nat_dec in H3.
      { destruct eq_nat_dec in H3.
        - rewrite e; rewrite e0. reflexivity.
        - contradict H3.
          apply not_eq_sym.
          apply nex_to_forall with (n := (n+1)%nat).
          apply H_nex_k. omega.
      }
      { destruct eq_nat_dec in H3.
        - contradict H3.
          apply nex_to_forall with (n := (n+1)%nat).
          apply H_nex_k. omega.
        - assumption.
      }
Qed.

Lemma Order_r_lt_N :
  forall a r N,
    Order a r N ->
    r < N.
Proof.
  intros.
  destruct (Nat.lt_ge_cases r N). easy.
  remember (fun i => pred (a^i mod N))%nat as f.
  cut (exists i j, i <= pred r /\ j < i /\ f i = f j).
  - intros. destruct H1 as (i & j & H1 & H2 & H3).
    cut (f i <> f j). easy.
    rewrite Heqf.
    assert (forall (a b : nat), a > 0 -> b > 0 -> a <> b -> pred a <> pred b).
    { intros. omega. }
    apply H4.
    + apply (Pow_pos _ r _ _). easy.
    + apply (Pow_pos _ r _ _). easy.
    + assert (forall T (x y : T), x <> y -> y <> x) by auto.
      apply H5. apply (Pow_diff _ r _ j i); try omega. easy.
  - apply pigeonhole. intros. subst. 
    assert (forall (a b : nat), a > 0 -> b > 0 -> a < b -> pred a < pred b) by (intros; omega).
    apply H2. apply (Pow_pos _ r _ _); easy. destruct H. auto.
    cut (a^i mod N < N). omega.
    apply Nat.mod_upper_bound. 
    assert (1 < N). { apply (Order_N_lb a r _). easy. } omega.
Qed.

(* Parameter assumptions of the Shor's algorithm *)
Definition BasicSetting (a r N m n : nat) :=
  0 < a < N /\
  Order a r N /\
  N^2 < 2^m <= 2 * N^2 /\
  N <= 2^n < 2 * N.

Definition basisPowerA (a r N n : nat) := basis_vector (2^n) (a^r mod N).

Local Open Scope R_scope.

Definition ω_neg (r : nat) := Cexp (-2 * PI / r).

(* The ψ states are the eigenstates of the target circuit. Described in https://cs.uwaterloo.ca/~watrous/LectureNotes/CPSC519.Winter2006/10.pdf. *)
Definition ψ (a r N j n : nat) :=
  (1 / √r) .* vsum r (fun x => (ω_neg r)^(j * x) .* (basisPowerA a x N n)).

Lemma ω_neg_sum_zero : forall r, Csum (fun i =>  (ω_neg r ^ (i * 0))%C) r = r.
Proof.
  intros.
  apply Csum_1.
  intros.
  unfold ω_neg.
  rewrite Cexp_pow.
  rewrite Nat.mul_0_r.
  autorewrite with R_db.
  apply Cexp_0.
Qed. 

(* Proved in a slightly different form in Csum_Cexp_nonzero in QPE.v. We should 
   update the two files to use consistent notation. *)
Lemma ω_neg_sum_nonzero :
  forall (r k : nat),
    0 < r ->
    0 < k < r -> 
    Csum (fun i => (ω_neg r ^ (i * k))%C) r = 0.
Proof.
  intros.
  assert (((fun (x : nat) => (ω_neg r)^(x * k)) = (fun (x : nat) => ((ω_neg r) ^ k) ^ x))%C).
  { apply functional_extensionality. intros. unfold ω_neg. do 3 rewrite Cexp_pow.
    rewrite mult_INR. replace (-2 * PI / r * (x * k)) with (-2 * PI / r * k * x) by lra. easy.
  }
  rewrite H1. rewrite Csum_geometric_series. unfold ω_neg. do 2 rewrite Cexp_pow.
  replace (-2 * PI / r * k * r) with (-(2 * PI * k)) by (field; lra). rewrite Cexp_neg.
  rewrite <- Cexp_pow. rewrite Cexp_2PI.
  replace (1 ^ k)%C with C1 by (rewrite RtoC_pow; rewrite pow1; auto).
  replace (1 - / 1)%C with C0 by lca. lca.
  unfold ω_neg. rewrite Cexp_pow. unfold Cexp. intro. inversion H2. rewrite H4 in H5. rewrite Rplus_0_l in H5.
  assert (0 < / r * k < 1).
  { destruct H0. split. 
    - apply Rinv_0_lt_compat in H. apply Rmult_lt_0_compat; assumption.
    - pose (Rinv_lt_contravar k r (Rmult_lt_0_compat k r H0 H) H3) as H6.
      pose (Rmult_lt_compat_r k (/ r) (/ k) H0 H6) as H7.
      rewrite <- Rinv_l_sym in H7; lra.
  }
  rewrite <- sin_neg in H5. replace (- (-2 * PI / r * k)) with (2 * PI / r * k) in H5 by lra.
  assert (0 < 2 * PI).
  { apply Rmult_lt_0_compat; try lra. apply PI_RGT_0.
  }
  assert (0 < 2 * PI / r * k < 2 * PI).
  { destruct H3. replace (2 * PI / r * k) with ((2 * PI) * (/ r * k)) by lra. split.
    - apply Rmult_lt_0_compat; lra. 
    - pose (Rmult_lt_compat_l (2 * PI) (/ r * k) 1 H6 H7) as H8.
      autorewrite with R_db in H8. assumption.
  }
  destruct H7.
  apply sin_eq_O_2PI_0 in H5; try (apply Rlt_le; assumption).
  destruct H5 as [? |[? | ?]]; try lra.
  replace ((-2 * PI / r * k)) with (- (2 * PI / r * k)) in H4 by lra. rewrite H5 in H4.
  rewrite cos_neg in H4. rewrite cos_PI in H4. lra.
Qed.

Lemma Vec_Mmult_vsum_distr_r :
  forall {d} n (f : nat -> Vector d) (v : Vector d),
    (vsum n f) † × v = vsum n (fun i => (f i) † × v).
Proof.
  intros.
  induction n; simpl. 
  Msimpl. reflexivity.
  rewrite Mplus_adjoint. rewrite Mmult_plus_distr_r, IHn. reflexivity.
Qed.

Lemma Double_Vec_Cancel :
  forall n (f : nat -> nat -> Vector 1),
    (forall i j, (i < n)%nat -> (j < n)%nat -> (i <> j)%nat -> f i j = Zero) ->
    vsum n (fun i => vsum n (fun j => f i j)) = vsum n (fun i => f i i).
Proof.
  intros. apply vsum_eq. intros.
  apply vsum_unique. exists i. split. easy.
  split. easy. intros. apply H; omega.
Qed.

Lemma vsum_multiple :
  forall {d} n (v : Vector d),
    vsum n (fun i => v) = n .* v.
Proof.
  intros. induction n.
  - simpl. Msimpl. easy.
  - rewrite <- vsum_extend_r. rewrite IHn. replace (S n) with (n + 1)%nat by omega. rewrite plus_INR. simpl. rewrite RtoC_plus. rewrite Mscale_plus_distr_l. Msimpl. easy.
Qed.

Lemma Cconj_mod_eq :
  forall c : C,
    Cmod (c^*) = Cmod c.
Proof.
  intro. unfold Cmod. unfold Cconj. simpl.
  replace (- snd c * (- snd c * 1)) with (snd c * (snd c * 1)) by lra. easy.
Qed.

Lemma Cconj_real_pos :
  forall x : C,
    snd x = 0 ->
    fst x >= 0 ->
    x = Cmod x.
Proof.
  intros. unfold Cmod. rewrite H. replace (fst x ^ 2 + 0 ^ 2) with (fst x ^ 2) by lra. rewrite sqrt_pow2 by lra. lca.
Qed.
  
Lemma Cconj_inner :
  forall c : C,
    (c^* * c = Cmod c ^2)%C.
Proof.
  intro.
  rewrite RtoC_pow.
  replace (Cmod c ^ 2) with ((Cmod (c^* )) * (Cmod c)).
  2:{ rewrite Cconj_mod_eq. lra.
  }
  rewrite <- Cmod_mult. apply Cconj_real_pos.
  destruct c. simpl. lra.
  destruct c. simpl. nra.
Qed.

Lemma Cmod_Cexp :
  forall θ,
    Cmod (Cexp θ) = 1.
Proof.
  intro. unfold Cexp. unfold Cmod. simpl. replace ((cos θ * (cos θ * 1) + sin θ * (sin θ * 1))) with (cos θ * cos θ + sin θ * sin θ) by lra. pose (sin2_cos2 θ) as H. unfold Rsqr in H. rewrite Rplus_comm in H. rewrite H. apply sqrt_1.
Qed.

Lemma ψ_pure_state :
  forall a r N m n j : nat,
    BasicSetting a r N m n ->
    Pure_State_Vector (ψ a r N j n).
Proof.
  intros. split.
  - unfold ψ. apply WF_scale. apply vsum_WF. intros. apply WF_scale. unfold basisPowerA. apply basis_vector_WF.
    assert (0 <= a^i mod N < N)%nat.
    { apply Nat.mod_bound_pos. omega.
      destruct H as [_ [HOrder _]]. apply Order_N_lb in HOrder. omega.
    }
    destruct H as [_ [_ [_ [Hn _]]]]. omega.
  - unfold ψ. rewrite Mscale_adj. rewrite Mscale_mult_dist_l. rewrite Mscale_mult_dist_r.
    rewrite Mmult_vsum_distr_l.
    replace (fun i : nat => (vsum r (fun x : nat => ω_neg r ^ (j * x) .* basisPowerA a x N n)) † × (ω_neg r ^ (j * i) .* basisPowerA a i N n)) with (fun i : nat => (vsum r (fun x : nat => (ω_neg r ^ (j * x) .* basisPowerA a x N n) † × (ω_neg r ^ (j * i) .* basisPowerA a i N n)))).
    2:{ apply functional_extensionality. intro. symmetry. apply Vec_Mmult_vsum_distr_r. }
    replace (fun i : nat => vsum r (fun x : nat => (ω_neg r ^ (j * x) .* basisPowerA a x N n) † × (ω_neg r ^ (j * i) .* basisPowerA a i N n))) with (fun i : nat => vsum r (fun x : nat => ((ω_neg r ^ (j * x))^* * ω_neg r ^ (j * i)) .* ((basisPowerA a x N n) † × basisPowerA a i N n))).
    2:{ apply functional_extensionality. intro. apply vsum_eq. intros.
        rewrite Mscale_adj. rewrite Mscale_mult_dist_r.
        rewrite Mscale_mult_dist_l. rewrite Mscale_assoc.
        replace ((ω_neg r ^ (j * i)) ^* * ω_neg r ^ (j * x))%C with (ω_neg r ^ (j * x) * (ω_neg r ^ (j * i)) ^* )%C by lca.
        easy.
    }
    assert (Hpmub: (forall y, a ^ y mod N < 2^n)%nat).
    { destruct H as [HN [_ [_ [Hn _]]]]. intros.
      assert (N <> 0)%nat by omega. pose (Nat.mod_upper_bound (a^y)%nat N H).
      omega.
    }
    rewrite Double_Vec_Cancel.
    2:{ rename j into x. intros. unfold basisPowerA.
        rewrite basis_vector_product_neq. Msimpl. easy.
        apply Hpmub. apply Hpmub.
        apply Pow_diff_neq with (r:=r); try omega.
        destruct H as [_ [HOrder _]]. easy.
    }
    unfold basisPowerA.
    replace (fun i : nat => (ω_neg r ^ (j * i)) ^* * ω_neg r ^ (j * i) .* ((basis_vector (2 ^ n) (a ^ i mod N)) † × basis_vector (2 ^ n) (a ^ i mod N))) with (fun i : nat => I 1).
    2:{ apply functional_extensionality. intro.
        rewrite Cconj_inner. unfold ω_neg. rewrite Cexp_pow. rewrite Cmod_Cexp. 
        rewrite basis_vector_product_eq by (apply Hpmub).
        simpl. do 2 rewrite Cmult_1_r. Msimpl. easy.
    }
    rewrite vsum_multiple.
    do 2 rewrite Mscale_assoc.
    assert (√ r <> 0).
    { destruct H as [_ [[Hr _] _]]. apply sqrt_neq_0_compat. apply lt_INR in Hr. simpl in Hr. easy.
    }
    rewrite <- RtoC_div by easy.
    rewrite Cconj_R. do 2 rewrite <- RtoC_mult.
    assert (forall x, x * r = x * (√r * √r)).
    { intro. apply Rmult_eq_compat_l. destruct H as [_ [[Hr _] _]]. apply lt_INR in Hr. simpl in Hr. apply Rlt_le in Hr. pose (Rsqr_sqrt r Hr) as Hr2. unfold Rsqr in Hr2. lra.
    } 
    replace (1 / √ r * (1 / √ r) * r) with ((/ √ r * √ r) * ((/ √ r) * √ r)) by (rewrite H1; lra).
    rewrite Rinv_l by easy. rewrite Rmult_1_r. Msimpl. easy.
Qed.

Lemma sum_of_ψ_is_one :
  forall a r N m n : nat,
    BasicSetting a r N m n ->
    (1 / √r) .* vsum r (fun j => ψ a r N j n) = basis_vector (2^n) 1.
Proof.
  intros.
  destruct H as [? [[? _] _]]. (* we only need a few parts of H *)
  unfold ψ.
  rewrite <- Mscale_vsum_distr_r.
  rewrite Mscale_assoc.
  rewrite vsum_swap_order.
  erewrite vsum_eq.
  2: { intros. rewrite Mscale_vsum_distr_l. reflexivity. }
  erewrite vsum_unique.
  2: { exists O.
       split. assumption.
       split.
       rewrite ω_neg_sum_zero. reflexivity.
       intros.
       rewrite ω_neg_sum_nonzero.
       lma.
       apply lt_0_INR; assumption. split. apply not_eq_sym in H2. apply neq_0_lt in H2. apply lt_0_INR; assumption. apply lt_INR; assumption.
  }
  unfold basisPowerA.
  rewrite Nat.pow_0_r.
  rewrite Nat.mod_1_l by lia.
  rewrite Mscale_assoc.
  replace (1 / √ r * (1 / √ r) * r)%C with C1.
  lma.
  field_simplify_eq.
  rewrite <- RtoC_mult.
  rewrite sqrt_def. 
  reflexivity.
  apply pos_INR.
  apply RtoC_neq.
  apply sqrt_neq_0_compat.
  apply lt_0_INR. 
  assumption.
Qed.

(*
Lemma mod_pow :
  forall a b N,
    (0 < N)%nat ->
    a^b mod N = (a mod N)^b mod N.
Proof.
  intros. induction b.
  - simpl; auto.
  - simpl. rewrite Nat.mul_mod; try omega. rewrite IHb. apply Nat.mul_mod_idemp_r. omega.
Qed.

Lemma MultiGroup_modulo_N :
  forall a r N x,
    Order a r N ->
    a^x mod N = a^(x mod r) mod N.
Proof.
  intros. assert (HN := H). apply Order_N_lb in HN.
  destruct H as [? [? ?]]. replace (a ^ x mod N)%nat with ((a^(r * (x / r) + x mod r)) mod N)%nat.
  2: { rewrite <- Nat.div_mod; omega. }
  rewrite Nat.pow_add_r. rewrite Nat.mul_mod; try omega.
  rewrite Nat.pow_mul_r. rewrite mod_pow; try omega.
  rewrite H0. rewrite Nat.pow_1_l. rewrite <- Nat.mul_mod; try omega. rewrite Nat.mul_1_l. easy.
Qed.
*)

(* The description of the circuit implementing "multiply a modulo N". *)
Definition MultiplyCircuitProperty (a N n : nat) (c : base_ucom n) :=
  forall x : nat,
    ((0 <= x < N)%nat ->
     (uc_eval c) × (basis_vector (2^n) x) = basis_vector (2^n) (a * x mod N)).

Lemma MC_eigenvalue :
  forall (a r N j m n : nat) (c : base_ucom n),
    BasicSetting a r N m n ->
    MultiplyCircuitProperty a N n c ->
    (uc_eval c) × (ψ a r N j n) = Cexp (2 * PI * j / r) .* (ψ a r N j n).
Proof.
  intros. unfold ψ. 
  unfold BasicSetting in H. destruct H as [Ha [HOrder [HN1 HN2]]]. 
  rewrite Mscale_mult_dist_r. rewrite Mscale_assoc. rewrite Cmult_comm.
  rewrite <- Mscale_assoc. rewrite Mscale_vsum_distr_r. rewrite Mmult_vsum_distr_l.
  unfold MultiplyCircuitProperty in H0. remember (uc_eval c) as U.
  replace (vsum r (fun i : nat => U × (ω_neg r ^ (j * i) .* basisPowerA a i N n))) 
    with (vsum r (fun i : nat => (ω_neg r ^ (j * i) .* basisPowerA a (i+1) N n))).
  2:{
    apply vsum_eq. intros. rewrite Mscale_mult_dist_r.
    unfold basisPowerA. rewrite H0. rewrite Nat.add_1_r. simpl. rewrite Nat.mul_mod_idemp_r. easy.
    (* N <> 0 *)
    destruct Ha. unfold not. intros. rewrite H3 in H2. easy.
    (* 0 <= a^i mod N < N *)
    apply Nat.mod_bound_pos. apply Nat.le_0_l. apply Nat.lt_trans with a. easy. easy. 
  }
  replace (vsum r (fun i : nat => ω_neg r ^ (j * i) .* basisPowerA a (i + 1) N n))
    with (vsum r (fun i : nat => Cexp (2 * PI * j / r) .* (ω_neg r ^ (j * i) .* basisPowerA a i N n))).
  easy.
  destruct r. easy. 
  rewrite <- vsum_extend_l. rewrite <- vsum_extend_r. rewrite Mplus_comm.
  unfold shift.
  assert (forall t (A B C D : Vector t), A = B -> C = D -> A .+ C = B .+ D).
  { intros. rewrite H. rewrite H1. easy. }
  apply H.   
  - apply vsum_eq. intros. rewrite Mscale_assoc. unfold ω_neg. rewrite Cexp_pow. rewrite Cexp_pow.
    rewrite <- Cexp_add. 
    replace (2 * PI * j / S r + -2 * PI / S r * (j * (i + 1))%nat) with (-2 * PI / S r * (j * i)%nat).
    easy. repeat rewrite mult_INR. rewrite plus_INR. simpl. lra.
  - unfold basisPowerA. remember (S r) as r'. unfold ω_neg. simpl. destruct HOrder as [Hr [HO1 HO2]].
    rewrite Nat.add_1_r. rewrite <- Heqr'. rewrite HO1. rewrite Nat.mod_small.
    rewrite Mscale_assoc. repeat rewrite Cexp_pow. rewrite <- Cexp_add.
    rewrite <- (Cmult_1_l (Cexp (-2 * PI / r' * (j * r)%nat))). replace 1 with (1^j). rewrite <- RtoC_pow. 
    rewrite <- Cexp_2PI. rewrite Cexp_pow. rewrite <- Cexp_add. repeat rewrite mult_INR.  simpl.
    replace (2 * PI * j / r' + -2 * PI / r' * (j * 0)) with (2 * PI * j + -2 * PI / r' * (j * r)).
    easy. simpl. rewrite Heqr'. rewrite <- Nat.add_1_r. repeat rewrite plus_INR. repeat rewrite Rdiv_unfold. simpl.
    repeat rewrite Rmult_0_r. rewrite Rplus_0_r. replace (-2 * PI) with (2 * PI * -1) by lra. 
    repeat rewrite Rmult_assoc.
    repeat rewrite <- Rmult_plus_distr_l.
    replace (j + -1 * (/ (r + 1) * (j * r))) with (j * / (r + 1)). easy.
    rewrite <- (Rmult_1_r j) at 2. rewrite <- (Rinv_r (r+1)) at 2.
    rewrite Rmult_comm. lra. 
    + replace (r+1) with (r+1%nat). rewrite <- plus_INR. rewrite Nat.add_1_r. rewrite <- Heqr'.
      apply lt_0_INR in Hr. apply Rlt_dichotomy_converse. right. easy. easy.
    + apply pow1.
    + destruct N. easy. destruct N. easy. lia. 
Qed.

Definition round (x : R) := up (x - /2).

(* The target basis we focus on, when the sampling result locates near k/r *)
Definition s_closest (m k r : nat) :=
  Z.to_nat (round (k / r * 2^m)%R).

Lemma round_inequality :
  forall x,
    x - /2 < IZR (round x) <= x + /2.
Proof.
  intros. unfold round.
  pose (archimed (x - /2)) as H. destruct H as [H0 H1].
  lra.
Qed.

Lemma round_pos :
  forall x,
    0 <= x ->
    (0 <= round x)%Z.
Proof.
  intros. pose (round_inequality x) as G. destruct G as [G0 G1].
  assert (-1 < IZR (round x)) by lra. apply lt_IZR in H0. lia.
Qed.

Lemma round_lt_Z :
  forall (x : R) (z : BinNums.Z),
    x <= IZR z ->
    (round x <= z)%Z.
Proof.
  intros. pose (round_inequality x) as G. destruct G as [G0 G1].
  assert (IZR (round x) < IZR z + 1) by lra. replace (IZR z + 1) with (IZR (z + 1)) in H0 by (rewrite plus_IZR; easy). apply lt_IZR in H0. lia.
Qed.

Lemma IZR_IZN_INR :
  forall z,
    (0 <= z)%Z ->
    IZR z = Z.to_nat z.
Proof.
  intros. destruct z; try lia. easy.
  simpl. rewrite INR_IPR. easy.
Qed.

Lemma pow_2_m_pos :
  forall m, 0 < 2 ^ m.
Proof.
  intros. apply pow_lt; lra.
Qed.

(*
Lemma Inv__pow_2_m_and_N_square:
  forall a r N m n,
    BasicSetting a r N m n ->
    /2 * /2^m < / (2 * N^2).
Proof.
  intros. destruct H as [Ha [HOrder [[Hm1 Hm2] HN2]]]. unfold s_closest. assert (HN := HOrder). apply Order_N_lb in HN. apply lt_INR in HN. simpl in HN.
  pose (pow_2_m_pos m).
  assert (0 < N^2) by nra.
  rewrite Rinv_mult_distr by lra.  
  apply Rmult_lt_compat_l. nra. 
  apply Rinv_lt_contravar. nra. 
  apply lt_INR in Hm1. do 2 rewrite pow_INR in Hm1. apply Hm1.
Qed.
*)

Lemma round_k_r_2_m_nonneg :
  forall a r N m n k,
    BasicSetting a r N m n ->
    (0 <= k < r)%nat ->
    (0 <= round (k / r * 2 ^ m))%Z.
Proof.
  intros. apply round_pos. destruct H0 as [Hk Hr]. assert (0 < r)%nat by lia. apply le_INR in Hk. simpl in Hk. apply lt_INR in Hr. apply lt_INR in H0. simpl in H0. assert (0 <= k / r). unfold Rdiv. apply Rle_mult_inv_pos; easy. pose (pow_2_m_pos m). nra. 
Qed.

Lemma s_closest_is_closest :
  forall a r N m n k,
    BasicSetting a r N m n ->
    (0 <= k < r)%nat ->
    -1 / (2 * 2^m) < (s_closest m k r) / (2^m) - k / r <= 1 / (2 * 2^m).
Proof.
  intros. assert (HBS := H). destruct H as [Ha [HOrder [[Hm1 Hm2] HN2]]]. unfold s_closest. assert (HN := HOrder). apply Order_N_lb in HN. apply lt_INR in HN. simpl in HN.
  pose (pow_2_m_pos m) as PowM.
  pose (round_k_r_2_m_nonneg _ _ _ _ _ _ HBS H0) as H.
  unfold Rdiv.
  replace (/ (2 * 2 ^ m)) with (/2 * /2^m) by (symmetry; apply Rinv_mult_distr; lra).  
  rewrite <- IZR_IZN_INR by easy.
  pose (round_inequality (k / r * 2 ^ m)) as G. destruct G as [G0 G1].
  split.
  - apply Rmult_lt_compat_l with (r:=/2^m) in G0.
    2:{ apply Rinv_0_lt_compat. easy.
    }
    rewrite Rmult_minus_distr_l in G0.
    replace (/ 2 ^ m * (k / r * 2 ^ m)) with (/ 2^m * 2^m * (k / r)) in G0 by lra. rewrite Rinv_l in G0; lra.
  - apply Rmult_le_compat_r with (r:=/2^m) in G1.
    2:{ apply Rinv_0_lt_compat in PowM. lra.
    }
    rewrite Rmult_plus_distr_r in G1.
    replace (k / r * 2 ^ m * / 2 ^ m) with (k / r * (2 ^ m * / 2 ^ m)) in G1 by lra. rewrite Rinv_r in G1; lra. 
Qed.

Lemma basis_vector_zero :
  forall x, basis_vector (2^x) 0 = x ⨂ ket 0.
Proof.
  intro. induction x.
  - simpl. unfold basis_vector. unfold I. apply functional_extensionality. intros. apply functional_extensionality. intros. destruct x; destruct x0; try easy. simpl. unfold Nat.ltb. simpl. rewrite andb_false_r. easy.
  - rewrite basis_f_to_vec_alt by (apply pow_positive; omega). simpl.
    rewrite nat_to_funbool_0. rewrite <- nat_to_funbool_0 with (n:=x).
    rewrite <- basis_f_to_vec_alt by (apply pow_positive; omega).
    rewrite IHx. simpl. easy.
Qed.

Lemma QPE_MC_partial_correct :
  forall (a r N k m n : nat) (c : base_ucom n),
    BasicSetting a r N m n ->
    uc_well_typed c ->
    MultiplyCircuitProperty a N n c ->
    (0 <= k < r)%nat ->
    probability_of_outcome ((uc_eval (QPE m n c)) × ((basis_vector (2^m) 0) ⊗ (ψ a r N k n))) ((basis_vector (2^m) (s_closest m k r)) ⊗ (ψ a r N k n)) >= 4 / (PI ^ 2).
Proof.
  intros a r N k m n c H Hc H0 H1.
  rewrite basis_vector_zero.
  assert (s_closest m k r < 2 ^ m)%nat.
  { apply INR_lt. rewrite pow_INR. pose (s_closest_is_closest _ _ _ _ _ _ H H1) as G. destruct G as [_ G1].
      assert (k / r <= 1 - / r).
      { assert (0 < r). assert (0 < r)%nat by omega. apply lt_0_INR; easy.
        apply Rmult_le_reg_r with (r:=r). easy.
        rewrite Raux.Rmult_minus_distr_r. replace (k / r * r) with ((/r) * r * k) by lra. rewrite Rinv_l by lra.
        assert (k + 1 <= r)%nat by omega. apply le_INR in H3. rewrite plus_INR in H3. simpl in H3. lra.
      }
      assert (/N < /r).
      { apply Rinv_lt_contravar. destruct H as [HN [[Hr _] _]]. assert (0 < r * N)%nat by (apply Nat.mul_pos_pos; omega). apply lt_INR in H. rewrite mult_INR in H. easy.
        apply lt_INR. apply Order_r_lt_N with (a:=a). destruct H as [_ [H _]]. easy.
      }
      assert (/ (2 * 2^m) < /N).
      { apply Rinv_lt_contravar.
        destruct H as [HN [Horder _]]. apply Order_N_lb in Horder. assert (0 < N)%nat by omega. apply lt_INR in H. simpl in H.
        pose (pow_2_m_pos m).
        nra.
        destruct H as [_ [_ [[Hm _] _]]]. apply lt_INR in Hm. simpl in Hm. do 2 rewrite mult_INR in Hm. rewrite pow_INR in Hm. replace (INR 2%nat) with 2 in Hm by reflexivity. simpl in Hm.
        assert (N <= N * N)%nat by nia. apply le_INR in H. rewrite mult_INR in H.
        nra.
      }
      assert (s_closest m k r / 2^m < 1) by lra.
      replace (INR 2%nat) with 2 by reflexivity.
      pose (pow_2_m_pos m).
      apply Rmult_lt_reg_r with (r:=/2^m). apply Rinv_0_lt_compat. easy.
      rewrite Rinv_r by lra. lra.
  }
  rewrite basis_f_to_vec_alt by easy.
  apply QPE_semantics_full with (δ:=k / r - s_closest m k r / 2^m).
  destruct H as [_ [Horder [_ [Hn _]]]]. apply Order_N_lb in Horder. destruct n. simpl in Hn. omega. omega.
  destruct H as [_ [Horder [[Hm _] _]]]. apply Order_N_lb in Horder. simpl in Hm. assert (4 <= 2^m)%nat by nia. destruct m. simpl in H. omega. destruct m. simpl in H. omega. omega.
  assumption.
  apply ψ_pure_state with (m:=m). assumption.
  pose (s_closest_is_closest _ _ _ _ _ _ H H1). replace (2 ^ (m + 1)) with (2 * 2 ^ m). lra.
  rewrite pow_add. lra.
  rewrite nat_to_funbool_inverse by easy.
  replace (2 * PI * (s_closest m k r / 2 ^ m + (k / r - s_closest m k r / 2 ^ m))) with (2 * PI * k / r) by lra.
  apply MC_eigenvalue with (m:=m); easy.
Qed.

Definition Rsum (n : nat) (f : nat -> R) : R :=
  match n with
  | O => 0
  | S n => sum_f_R0 f n
  end.

Lemma Rsum_eq :
  forall n f1 f2,
    (forall i, f1 i = f2 i) -> Rsum n f1 = Rsum n f2.
Proof.
  intros. induction n.
  - easy.
  - simpl. destruct n.
    + simpl. apply H.
    + simpl. simpl in IHn. rewrite IHn. rewrite H. easy.
Qed.

Definition prob_partial_meas {n} {m} (ϕ : Vector (2^m)) (ψ : Vector (2^(m + n))) :=
  Rsum (2^n) (fun y => probability_of_outcome ψ (ϕ ⊗ basis_vector (2^n) y)).

Lemma Cplx_Cauchy :
  forall n (a : nat -> C) (b : nat -> C),
    (Rsum n (fun i => Cmod (a i) ^ 2)) * (Rsum n (fun i => Cmod (b i) ^ 2)) >= Cmod (Csum (fun i => ((a i)^* * (b i))%C) n) ^ 2.
Admitted.

Lemma full_meas_swap :
  forall {d} (ψ : Vector d) (ϕ : Vector d),
    probability_of_outcome ψ ϕ = probability_of_outcome ϕ ψ.
Proof.
  intros d ψ ϕ. unfold probability_of_outcome.
  replace ((ϕ) † × ψ) with ((ϕ) † × ((ψ) †) †) by (rewrite adjoint_involutive; easy).
  rewrite <- Mmult_adjoint.
  replace (((ψ) † × ϕ) † 0%nat 0%nat) with ((((ψ) † × ϕ) 0%nat 0%nat)^* ) by easy.
  rewrite Cconj_mod_eq. easy.
Qed.

Lemma vsum_by_cell :
  forall {d n} (f : nat -> Vector d) x y,
    vsum n f x y = Csum (fun i => f i x y) n.
Proof.
  intros d n f x y. induction n.
  - easy.
  - simpl. unfold Mplus. rewrite IHn. easy.
Qed.

Lemma basis_vector_decomp :
  forall {d} (ψ : Vector d),
    WF_Matrix ψ ->
    ψ = vsum d (fun i => (ψ i 0%nat) .* basis_vector d i).
Proof.
  intros d ψ WF. do 2 (apply functional_extensionality; intros). rewrite vsum_by_cell.
  destruct (x <? d) eqn:Hx.
  - apply Nat.ltb_lt in Hx. 
    unfold scale. destruct x0.
    + rewrite Csum_unique with (k:=ψ x 0%nat). easy.
      exists x. split. easy.
      split. unfold basis_vector. rewrite Nat.eqb_refl. simpl. lca.
      intros. unfold basis_vector. apply eqb_neq in H. rewrite H. simpl. lca.
    + unfold WF_Matrix in WF. rewrite WF by omega.
      rewrite Csum_0. easy. intro.
      unfold basis_vector. assert (S x0 <> 0)%nat by omega. apply eqb_neq in H.
      rewrite H. rewrite andb_false_r. lca.
  - apply Nat.ltb_ge in Hx.
    unfold WF_Matrix in WF. rewrite WF by omega.
    rewrite Csum_0_bounded. easy. intros. unfold scale.
    unfold basis_vector. assert (x <> x1) by omega. apply eqb_neq in H0.
    rewrite H0. simpl. lca.
Qed.

Lemma full_meas_decomp :
  forall {n m} (ψ : Vector (2^(m+n))) (ϕ1 : Vector (2^m)) (ϕ2 : Vector (2^n)),
    Pure_State_Vector ϕ2 ->
    probability_of_outcome ψ (ϕ1 ⊗ ϕ2) = Cmod (Csum (fun i => ((ϕ2 i 0%nat) .* @Mmult _ _ (1 * 1) (ψ †) (ϕ1 ⊗ (basis_vector (2^n) i))) 0%nat 0%nat) (2^n)) ^ 2.
Proof.
  intros n m ψ ϕ1 ϕ2 [HWF Hnorm]. rewrite full_meas_swap. unfold probability_of_outcome.
  assert (T: forall x y, x = y -> Cmod x ^ 2 = Cmod y ^ 2).
  { intros. rewrite H. easy. }
  apply T. clear T.
  replace (ϕ1 ⊗ ϕ2) with (ϕ1 ⊗ vsum (2^n) (fun i => (ϕ2 i 0%nat) .* basis_vector (2^n) i)) by (rewrite <- basis_vector_decomp; easy).
  rewrite kron_vsum_distr_l.
  rewrite <- Nat.pow_add_r. rewrite Mmult_vsum_distr_l.
  rewrite vsum_by_cell. apply Csum_eq. apply functional_extensionality. intros.
  rewrite Mscale_kron_dist_r. rewrite <- Mscale_mult_dist_r. easy.
Qed.

Lemma RtoC_Rsum_Csum :
  forall n (f : nat -> R),
    fst (Csum (fun i => f i) n) = Rsum n f.
Proof.
  intros. induction n.
  - easy.
  - simpl. rewrite IHn. destruct n.
    + simpl. lra.
    + rewrite tech5. simpl. easy.
Qed.

Lemma full_meas_equiv :
  forall {d} (ψ : Vector d),
    fst (((ψ) † × ψ) 0%nat 0%nat) = Rsum d (fun i => Cmod (ψ i 0%nat) ^ 2).
Proof.
  intros d ψ. unfold Mmult.
  replace (fun y : nat => ((ψ) † 0%nat y * ψ y 0%nat)%C) with (fun y : nat => RtoC (Cmod (ψ y 0%nat) ^ 2)).
  apply RtoC_Rsum_Csum.
  apply functional_extensionality. intros.
  unfold adjoint. rewrite Cconj_inner. symmetry. apply RtoC_pow.
Qed.

Lemma Cconj_adj :
  forall {n m} (A : Matrix n m),
    (A 0%nat 0%nat) ^* = (A †) 0%nat 0%nat.
Proof.
  intros. easy.
Qed.

Lemma partial_meas_prob_ge_full_meas :
  forall {n m} (ψ : Vector (2^(m+n))) (ϕ1 : Vector (2^m)) (ϕ2 : Vector (2^n)),
    Pure_State_Vector ϕ2 ->
    prob_partial_meas ϕ1 ψ >= probability_of_outcome ψ (ϕ1 ⊗ ϕ2).
Proof.
  intros n m ψ ϕ1 ϕ2 H. rewrite full_meas_decomp by easy. unfold prob_partial_meas.
  assert (T: forall q w e, q = w -> w >= e -> q >= e) by (intros; lra).
  eapply T.
  2:{ unfold scale.
      erewrite Csum_eq.
      2:{ apply functional_extensionality. intros. rewrite <- (Cconj_involutive (ϕ2 x 0%nat)). reflexivity.
      }
      apply Cplx_Cauchy.
  }
  simpl.
  replace (fun i : nat => Cmod ((ϕ2 i 0%nat) ^* ) * (Cmod ((ϕ2 i 0%nat) ^* ) * 1)) with (fun i : nat => Cmod (ϕ2 i 0%nat) ^ 2).
  2:{ apply functional_extensionality; intros. simpl.
      rewrite Cconj_mod_eq. easy.
  } 
  rewrite <- full_meas_equiv.
  destruct H as [WF H]. rewrite H. simpl. rewrite Rmult_1_l.
  apply Rsum_eq. intros.
  unfold probability_of_outcome.
  rewrite <- Cconj_mod_eq. rewrite Cconj_adj. rewrite Mmult_adjoint. rewrite adjoint_involutive.
  easy.
Qed.  

Lemma QPE_MC_correct :
  forall (a r N k m n : nat) (c : base_ucom n),
    BasicSetting a r N m n ->
    MultiplyCircuitProperty a N n c ->
    uc_well_typed c ->
    0 <= k < r ->
    prob_partial_meas (basis_vector (2^m) (s_closest m k r)) ((uc_eval (QPE m n c)) × ((basis_vector (2^m) 0) ⊗ (basis_vector (2^n) 1))) >= 4 / (PI ^ 2 * r).
Proof.
Admitted.

(* <del>Finds p/q such that |s/2^m-p/q|<=1/2^(m+1) and q<N. Must make sure 2^m>N^2 to secure the uniqueness.<\del> *)
(* Calc p_n and q_n now, which is the continued fraction expansion of a / b for n terms. *)
Fixpoint CF_ite (n a b p1 q1 p2 q2 : nat) : nat * nat :=
  match n with
  | O => (p1, q1)
  | S n => let c := (b / a)%nat in
          CF_ite n (b mod a)%nat a (c*p1+p2)%nat (c*q1+q2)%nat p1 q1
  end.

Compute (CF_ite 8 73 100 0 1 1 0).

Definition ContinuedFraction (step s m : nat) : nat * nat := CF_ite step s (2^m) 0 1 1 0.

Definition Shor_post (step s m : nat) := snd (ContinuedFraction step s m).

Lemma Rabs_center :
  forall x y z d1 d2,
    Rabs (x - y) < d1 ->
    Rabs (x - z) < d2 ->
    Rabs (y - z) < d1 + d2.
Proof.
  intros. 
  rewrite Rabs_minus_sym in H0.
  apply Rabs_def2 in H. apply Rabs_def2 in H0.
  apply Rabs_def1; lra.
Qed.

Lemma Rabs_Z_lt_1 :
  forall z,
    Rabs (IZR z) < 1 ->
    (z = 0)%Z.
Proof.
  intros. rewrite <- abs_IZR in H. apply lt_IZR in H. lia.
Qed.


Lemma ClosestFracUnique :
  forall (α : R) (p1 q1 p2 q2 N : nat),
    (0 < N)%nat ->
    (0 < q1 <= N)%nat ->
    (0 < q2 <= N)%nat ->
    Rabs (α - p1 / q1) < / (2 * N^2) ->
    Rabs (α - p2 / q2) < / (2 * N^2) ->
    p1 / q1 = p2 / q2.
Proof.
  intros. destruct H0 as [H00 H01]. destruct H1 as [H10 H11].
  apply lt_INR in H. simpl in H. apply lt_INR in H00. simpl in H00. apply lt_INR in H10. simpl in H10.
  apply le_INR in H01. apply le_INR in H11.
  assert (Rabs (p1 / q1 - p2 / q2) < / N^2).
  { replace (/ N^2) with (/ (2 * N^2) + / (2 * N^2)) by (field; lra).
    apply Rabs_center with (x := α); easy.
  }
  replace (p1 / q1 - p2 / q2) with (IZR (p1 * q2 - p2 * q1)%Z / (q1 * q2)) in H0.
  2:{ rewrite minus_IZR. do 2 rewrite mult_IZR. repeat rewrite <- INR_IZR_INZ. field. lra.
  }
  assert (forall a b, b <> 0 -> Rabs (a / b) = Rabs a / Rabs b).
  { intros. replace (a / b) with (a * /b) by lra. rewrite Rabs_mult. rewrite Rabs_Rinv; easy.
  }
  assert (0 < q1 * q2) by (apply Rmult_lt_0_compat; lra).
  rewrite H1 in H0 by lra.
  assert (Rabs (q1 * q2) = q1 * q2).
  { apply Rabs_pos_eq. apply Rmult_le_pos; lra.
  }
  rewrite H5 in H0. unfold Rdiv in H0. apply Rmult_lt_compat_r with (r:=q1*q2) in H0; try assumption.
  rewrite Rmult_assoc in H0. rewrite Rinv_l in H0 by lra. rewrite Rmult_1_r in H0.
  assert (/ N ^ 2 * (q1 * q2) <= 1).
  { apply Rmult_le_reg_l with (r:=N^2). simpl. rewrite Rmult_1_r. apply Rmult_lt_0_compat; easy.
    rewrite <- Rmult_assoc. rewrite Rinv_r. rewrite Rmult_1_r. rewrite Rmult_1_l. simpl. rewrite Rmult_1_r. apply Rmult_le_compat; lra.
    simpl. rewrite Rmult_1_r. apply Rmult_integral_contrapositive_currified; lra.
  }
  pose (Rlt_le_trans _ _ _ H0 H6) as H7.
  apply Rabs_Z_lt_1 in H7.
  assert (p1 * q2 = p2 * q1).
  { repeat rewrite INR_IZR_INZ. repeat rewrite <- mult_IZR. replace (p1 * q2)%Z with (p2 * q1)%Z by lia. easy.
  }
  apply Rmult_eq_reg_r with (r:=q1 * q2); try lra.
  replace (p1 / q1 * (q1 * q2)) with (p1 * q2 * (/ q1 * q1)) by lra. rewrite Rinv_l by lra.
  replace (p2 / q2 * (q1 * q2)) with (p2 * q1 * (/ q2 * q2)) by lra. rewrite Rinv_l by lra.
  rewrite H8. easy.
Qed.

(* "Partial correct" of ContinuedFraction function. "Partial" because it is exactly correct only when k and r are coprime. Otherwise it will output (p, q) such that p/q=k/r. *)
Lemma ContinuedFraction_partial_correct :
  forall (a r N k m n : nat),
    BasicSetting a r N m n ->
    rel_prime k r ->
    exists step,
      (step <= m)%nat /\
      Shor_post step (s_closest m k r) m = r.
Admitted.

Fixpoint Bsum n (f : nat -> bool) :=
  match n with
  | O => f O
  | S n' => f n' || Bsum n' f
  end.

Definition r_recoverable x m r := if Bsum m (fun step => Shor_post step x m =? r) then 1 else 0.

(* The final success probability of Shor's order finding algorithm. It counts the k's coprime to r and their probability of being collaped to. *)
Definition probability_of_success (a r N m n : nat) (c : base_ucom n) :=
  Rsum (2^m) (fun x => r_recoverable x m r * prob_partial_meas (basis_vector (2^m) x) ((uc_eval (QPE m n c)) × ((basis_vector (2^m) 0) ⊗ (basis_vector (2^n) 1)))).

(* Euler's totient function *)
Definition ϕ (n : nat) := Rsum n (fun x => if rel_prime_dec x n then 1 else 0).

(* This might need to be treated as an axiom. [1979 Hardy & Wright, Thm 328] *)
Lemma ϕ_n_over_n_lowerbound :
  exists β, 
    β>0 /\
    forall (n : nat),
      2 < n ->
      (ϕ n) / n >= β / (Nat.log2 (Nat.log2 n)).
Admitted.

(* sum_f_R0 facts *)
Lemma rsum_swap_order :
  forall (m n : nat) (f : nat -> nat -> R),
    sum_f_R0 (fun j => sum_f_R0 (fun i => f j i) m) n = sum_f_R0 (fun i => sum_f_R0 (fun j => f j i) n) m.
Proof.
  intros. induction n; try easy.
  simpl. rewrite IHn. rewrite <- sum_plus. reflexivity.
Qed.

Lemma find_decidable :
    forall (m t : nat) (g : nat -> nat),
    (exists i, i <= m /\ g i = t)%nat \/ (forall i, i <= m -> g i <> t)%nat.
Proof.
  induction m; intros.
  - destruct (dec_eq_nat (g 0%nat) t).
    + left. exists 0%nat. split; easy.
    + right. intros. replace i with 0%nat by omega. easy.
  - destruct (IHm t g).
    + left. destruct H. exists x. destruct H. split; omega.
    + destruct (dec_eq_nat (g (S m)) t).
      -- left. exists (S m). omega.
      -- right. intros. inversion H1. omega. apply H. omega.
Qed.

Lemma rsum_unique :
    forall (n : nat) (f : nat -> R) (r : R),
    (exists (i : nat), i <= n /\ f i = r /\ (forall (j : nat), j <= n -> j <> i -> f j = 0)) ->
    sum_f_R0 f n = r.
Proof.
  intros.
  destruct H as (? & ? & ? & ?).
  induction n. simpl. apply INR_le in H. inversion H. subst. easy.
  simpl. bdestruct (S n =? x).
  - subst. replace (sum_f_R0 f n) with 0. lra.
    symmetry. apply sum_eq_R0. intros. apply H1. apply le_INR. constructor. easy. omega.
  - apply INR_le in H. inversion H. omega. subst. replace (f (S n)) with 0.
    rewrite IHn. lra. apply le_INR. easy. intros. apply H1; auto. apply Rle_trans with n; auto.
    apply le_INR. lia. symmetry. apply H1; auto. apply Rle_refl.
Qed.

Theorem rsum_subset :
  forall (m n : nat) (f : nat -> R)  (g : nat -> nat),
    m < n -> (forall (i : nat), 0 <= f i) -> (forall i, i <= m -> g i <= n)%nat ->
    (forall i j, i <= m -> j <= m -> g i = g j -> i = j)%nat ->
    sum_f_R0 (fun i => f (g i)) m <= sum_f_R0 f n.
Proof.
  intros.
  set (h := (fun (i : nat) => sum_f_R0 (fun (j : nat) => if i =? g j then f (g j) else 0) m)).
  assert (forall (i : nat), i <= n -> h i <= f i).
  { intros. unfold h. simpl.
    destruct (find_decidable m i g).
    - destruct H4 as (i0 & H4 & H5).
      replace (sum_f_R0 (fun j : nat => if i =? g j then f (g j) else 0) m) with (f i). lra.
      symmetry. apply rsum_unique. exists i0. split.
      + apply le_INR. easy.
      + split. subst.  rewrite Nat.eqb_refl. easy.
        intros. assert (i <> g j). unfold not. intros. subst. apply H2 in H8. apply H7. easy.
        easy. apply INR_le. easy.
      + replace (i  =? g j) with false. easy. symmetry. apply eqb_neq. easy.
    - replace (sum_f_R0 (fun j : nat => if i =? g j then f (g j) else 0) m) with 0. easy.
      symmetry. apply sum_eq_R0. intros. apply H4 in H5. rewrite eqb_neq. easy. omega.
  }
  assert (sum_f_R0 h n <= sum_f_R0 f n).
  { apply sum_Rle. intros. apply H3. apply le_INR. easy. }
  apply Rle_trans with (sum_f_R0 h n); auto.
  unfold h. rewrite rsum_swap_order.
  replace (sum_f_R0 (fun i : nat => f (g i)) m) with 
  (sum_f_R0 (fun i : nat => sum_f_R0 (fun j : nat => if j =? g i then f (g i) else 0) n) m).
  apply Rle_refl. apply sum_eq. intros.
  apply rsum_unique. exists (g i). split.
  - apply le_INR. auto. split.
  - rewrite Nat.eqb_refl. easy.
  - intros. rewrite eqb_neq; easy.
Qed.

(* The correctness specification. It succeed with prob proportional to 1/(log log N), which is asymptotically small, but big enough in practice.
   With better technique (calculate the LCM of multiple outputs), the number of rounds may be reduced to constant. But I don't know how to specify that, and the analysis in Shor's original paper refers the correctness to "personal communication" with Knill. *)
Lemma Shor_correct :
  exists β, 
    β>0 /\
    forall (a r N m n : nat) (c : base_ucom n),
      BasicSetting a r N m n ->
      MultiplyCircuitProperty a N n c ->
      probability_of_success a r N m n c >= β / (Nat.log2 (Nat.log2 N)).
Admitted.
