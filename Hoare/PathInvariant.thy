theory PathInvariant
imports PathRel
begin

lemma mono_list :
  "push_popL (map snd lst) \<Longrightarrow>
   pathR (mono_rules iv) lst \<Longrightarrow>
   length lst > 0 \<Longrightarrow>
   monoI iv (hd lst) \<Longrightarrow>
   monoI iv (last lst)"
apply (induction "mono_rules iv" lst rule:pathR.induct)
apply (auto simp add:pathR.simps mono_works pathR2 pathR3 push_popL_def)
done

(* top rules *)
(* actually, the mono rules will hold *)
(* but sometime mono push and pop will only hold because
   they are part of call sequences
 *)

(*
mono_pop : because it is a call, and calls have the invariant

this rule has to be proven for each possible call into a contract
for the invariant to hold ...
*)
definition call_rule :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_rule iv lst = (
  call (map snd lst) \<longrightarrow> iv (fst (hd lst)) \<longrightarrow>
  iv (fst (last lst))
)"

definition call_out :: "'a list list \<Rightarrow> bool" where
"call_out lst = (
  push_popL lst \<and>
  length lst > 1 \<and>
  (last lst, hd lst) \<in> tlR \<and>
  (\<forall>x \<in> set lst. length x \<ge> length (hd lst))
)"

(*
for pushing, we need to ... well in theory the external call
 could break the invariant and then fix it
*)
definition call_out_rule :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_out_rule iv lst = (
  call_out (map snd lst) \<longrightarrow> iv (fst (hd lst)) \<longrightarrow>
  iv (fst (last lst))
)"

lemma mono_same_length :
   "(a,b) \<in> mono_same iv \<Longrightarrow>
    length (snd a) = length (snd b)"
  by (smt fst_conv mem_Collect_eq mono_same_def snd_conv)


lemma mono_pop_length :
   "(a,b) \<in> mono_pop iv \<Longrightarrow>
    length (snd a) = length (snd b) + 1"
  by (smt Suc_eq_plus1 fst_conv length_Cons mem_Collect_eq mono_pop_def snd_conv)

lemma mono_push_length :
   "(a,b) \<in> mono_push iv \<Longrightarrow>
    length (snd a) + 1 = length (snd b)"
  by (smt Int_iff One_nat_def add.right_neutral add_Suc_right fst_conv length_Cons mem_Collect_eq mono_push_def prod.sel(2))

lemma mono_is_push :
  "(a,b) \<in> mono_rules iv \<Longrightarrow>
   length (snd a) + 1 = length (snd b) \<Longrightarrow>
   (a, b) \<in> mono_push iv"
by (metis UnE less_add_same_cancel1 mono_pop_length mono_rules_def mono_same_length not_add_less1 zero_less_one)

lemma mono_is_pop :
  "(a,b) \<in> mono_rules iv \<Longrightarrow>
   length (snd a) = length (snd b) + 1 \<Longrightarrow>
   (a, b) \<in> mono_pop iv"
  by (metis UnE less_add_same_cancel1 mono_push_length mono_rules_def mono_same_length not_add_less1 zero_less_one)

lemma mono_is_same :
  "(a,b) \<in> mono_rules iv \<Longrightarrow>
   length (snd a) = length (snd b) \<Longrightarrow>
   (a, b) \<in> mono_same iv"
  by (metis UnE less_add_same_cancel1 mono_pop_length mono_push_length mono_rules_def not_add_less1 zero_less_one)

(* first the invariant is pushed into stack (second element). *)
lemma call_invariant_push :
  "call (map snd lst) \<Longrightarrow>
   monoI iv (hd lst) \<Longrightarrow>
   pathR (mono_rules iv) lst \<Longrightarrow>
   iv (fst (hd lst)) \<Longrightarrow>
   iv (hd (snd (lst!1)))"
apply (auto simp add:path_defs path_def
  call_def tlR_def)
apply (subgoal_tac "hd lst = lst!0")
apply auto
defer
  apply (metis hd_conv_nth list.size(3) not_numeral_less_zero)
apply (subgoal_tac "(lst!0, lst!1) \<in> mono_push iv")
apply (auto simp add:mono_push_def)[1]
apply (subgoal_tac "(lst!0, lst!1) \<in> mono_rules iv")
defer
  apply simp
apply (subgoal_tac "length (snd (lst!0)) + 1 = length (snd (lst!1))")
using mono_is_push [of "lst!0" "lst!1" iv]
  apply blast
  by (metis One_nat_def less_imp_Suc_add list.size(4) nth_map zero_less_Suc)

(* pushed element cannot change *)
lemma call_invariant_before_after :
  "call lst \<Longrightarrow>
   lst!1 = lst!(length lst-2)"
apply (subgoal_tac "length (lst!1) = length (lst!(length lst-2))")
using call_inside_big_idx [of lst "length lst-2"]
  apply (metis One_nat_def PathRel.take_all Suc_1 Suc_leI Suc_lessD call_def diff_less_mono2 lessI zero_less_diff)
using call_ncall [of lst]
  by (smt One_nat_def Suc_leI Suc_lessD call_def diff_less last_clip le_less length_map ncall_last nth_map numeral_2_eq_2 zero_less_diff zero_less_numeral)

lemma get_mono_inv :
  "monoI iv a \<Longrightarrow>
   length (snd a) > 0 \<Longrightarrow>
   iv (hd (snd a)) \<Longrightarrow>
   iv (fst a)"
  using hd_conv_nth monoI_def by fastforce

lemma ncall_first_step : 
  "ncall lst \<Longrightarrow>
   lst!1 = lst!0 + 1"
by (simp add:ncall_def sucR_def)

lemma ncall_next : 
  "ncall lst \<Longrightarrow>
   lst ! (length lst - 2) = lst!1"
  by (smt One_nat_def Suc_diff_Suc Suc_lessI diff_le_self last_clip less_eq_Suc_le ncall_def ncall_last numeral_2_eq_2 zero_less_diff)

lemma ncall_last_length : 
  "ncall lst \<Longrightarrow>
   last lst + 1 = lst ! (length lst - 2)"
using ncall_stack_length ncall_next ncall_first_step
  by (metis gr_implies_not_zero hd_conv_nth list.size(3) ncall_def)

lemma call_last_length : 
  "call lst \<Longrightarrow>
   length (last lst) + 1 =
   length (lst ! (length lst - 2))"
using ncall_stack_length call_ncall
  by (smt One_nat_def call_def diff_less last_index length_map ncall_last_length nth_map numeral_2_eq_2 order.strict_trans zero_less_Suc)


(* because the pushed element didn't change, current must have the
   invariant, and we can use the mono push rule *)
lemma call_mono_invariant :
  "call (map snd lst) \<Longrightarrow>
   monoI iv (hd lst) \<Longrightarrow>
   pathR (mono_rules iv) lst \<Longrightarrow>
   iv (fst (hd lst)) \<Longrightarrow>
   iv (fst (last lst))"
apply (subgoal_tac "monoI iv (lst ! (length lst-2))")
apply (subgoal_tac "iv (hd (snd (lst ! (length lst-2))))")
apply (subgoal_tac "(lst ! (length lst-2), last lst) \<in> mono_pop iv")
apply (subgoal_tac "iv (fst (lst ! (length lst-2)))")
  apply (smt fst_conv list.sel(1) mem_Collect_eq mono_pop_def snd_conv)
  apply (metis (no_types, hide_lams) Suc_eq_plus1 hd_conv_nth length_Cons list.sel(1) list.size(3) monoI_def mono_pop_length nat.simps(3) zero_less_Suc)
apply (subgoal_tac "(lst ! (length lst - 2), last lst) \<in> mono_rules iv")
apply (subgoal_tac "length (snd (last lst)) + 1 = length (snd (lst ! (length lst - 2)))")
  apply (smt UnE add_right_imp_eq mono_push_length mono_rules_def mono_same_length numeral_eq_iff numeral_plus_numeral numerals(1) semiring_norm(2) semiring_norm(6) semiring_norm(85) semiring_norm(87) semiring_normalization_rules(24) semiring_normalization_rules(25))
using call_last_length [of "map snd lst"]
apply simp
apply (subgoal_tac "lst \<noteq> []")
apply (simp add:last_map)
  using call_def apply force
apply (subgoal_tac "lst \<noteq> []")
apply (simp add:path_defs path_def last_conv_nth)
  apply (smt Nil_is_map_conv Nitpick.size_list_simp(2) One_nat_def Suc_diff_Suc call_def diff_less length_greater_0_conv length_tl less_trans_Suc map_tl not_less_less_Suc_eq numeral_2_eq_2 zero_less_numeral)
  using call_def apply force
apply (subgoal_tac "snd (lst ! 1) = snd (lst ! (length (map snd lst) - 2))")
using call_invariant_push [of lst iv]
apply simp
using call_invariant_before_after [of "map snd lst"]
apply simp
  apply (smt Nil_is_map_conv One_nat_def call_def diff_less length_greater_0_conv length_tl less_trans_Suc map_tl nth_map order.strict_trans zero_less_diff zero_less_numeral)
using mono_list [of "take (length lst - 1) lst" iv]
apply (auto simp add:call_def push_popL_def)
apply (subgoal_tac "lst \<noteq> []")
apply auto
apply (subgoal_tac
   "map snd (take (length lst - 1) lst) =
    take (length lst - 1) (map snd lst)")
defer
apply (simp add: take_map)
apply (auto simp add:pathR_take)
  by (metis One_nat_def Suc_1 Suc_diff_Suc Suc_lessD diff_Suc_less hd_take last_take)

lemma call_first_prev :
"call_end lst (last lst) \<Longrightarrow>
 last (take (length lst - Suc 0) lst) = lst!0"
  by (smt Nitpick.size_list_simp(2) One_nat_def Suc_diff_Suc call_end_def diff_Suc_Suc diff_less first_one_smaller_prev last_take length_tl less_numeral_extra(2) zero_less_Suc)

lemma decompose_call_end :
  "call_end lst (last lst) \<Longrightarrow>
   x \<in> set (indexSplit (findIndices (take (length lst-1) lst) (lst!0))
             (take (length lst-1) lst)) \<Longrightarrow>
   call_end x (lst!0) \<or> const_seq x (lst!0)"
using correct_pieces [of "take (length lst-1) lst" x]
apply simp
apply (subgoal_tac "inc_decL (take (length lst - 1) lst)")
defer
apply (simp add:pathR_take call_end_def inc_decL_def)
apply simp
apply (subgoal_tac "lst \<noteq> [] \<and> 1 < length lst")
defer
apply (simp add:call_end_def)
  using less_nat_zero_code apply auto[1]
apply clarsimp
apply (subgoal_tac "hd (take (length lst - Suc 0) lst) = lst!0")
defer
  apply (simp add: hd_conv_nth)
apply simp
apply (subgoal_tac "last (take (length lst - Suc 0) lst) = lst!0")
defer
using call_first_prev apply fastforce
apply (simp add:split_def)
  by (metis One_nat_def call_end_def first_smaller1 first_smaller_before)

lemma decompose_call_end_index :
  "call_end lst (last lst) \<Longrightarrow>
   \<exists>ilst. (\<forall>x \<in> set (indexSplit ilst (take (length lst-1) lst)).
   call_end x (lst!0) \<or> const_seq x (lst!0))"
apply (rule exI[where x =
   "findIndices (take (length lst-1) lst) (lst!0)"])
using decompose_call_end apply fastforce
done

lemma call_e_end :
"call_e lst (last lst) \<Longrightarrow>
 call_end (map length lst) (last (map length lst))"
  using call_end1 call_end_last by fastforce

lemma call_e_pathR:
"call_e lst (last lst) \<Longrightarrow> pathR push_pop lst"
by (simp add:call_e_def push_popL_def)

(*
lemma call_end_inside_big_idx :
"call_end lst (last lst) \<Longrightarrow>
 j < length lst - 1 \<Longrightarrow>
 lst ! 0 \<le> lst ! j"
*)

lemma call_end_inside_big :
"call_end lst (last lst) \<Longrightarrow>
 x \<in> set (take (length lst - 1) lst) \<Longrightarrow>
 lst ! 0 \<le> x"
using first_smaller1 [of "lst" "length lst - 1"]
using first_smaller_before [of "length lst -1" "lst" x]
by (auto simp add:call_end_def sucR_def)

lemma call_e_inside_big_idx :
"call_e lst (last lst) \<Longrightarrow>
 j < length lst - 1 \<Longrightarrow>
 takeLast (length (lst!0)) (lst!j) = lst ! 0"
using stack_unchanged [of "take (Suc j) lst"
   "length (lst!0)"]
apply simp
apply (cases "push_popL (take (Suc j) lst)")
defer
apply (simp add:call_e_def push_popL_def pathR_take)
apply (cases "take (Suc j) lst = []")
apply (simp add:clip_def call_e_def)

apply (simp add:last_take hd_take)
apply (subgoal_tac "\<forall>sti\<in>set (take (Suc j)lst).
        length (lst ! 0) \<le> length sti")
apply auto
  apply (simp add: hd_conv_nth)

subgoal for sti
using call_end_inside_big [of "map length lst" "length sti"]
apply (simp add:call_e_end)
apply (cases "length sti
     \<in> set (take (length (map length lst) - 1) (map length lst))")
apply auto
  apply (simp add: clip_def drop_map take_map)
  by (meson Suc_leI image_eqI set_take_subset_set_take subset_code(1))
done

lemma call_e_inside_big :
 "call_e lst (last lst) \<Longrightarrow>
  a \<in> set (take (length lst - 1) lst) \<Longrightarrow>
  takeLast (length (lst ! 0)) a = lst ! 0"
using ex_idx [of a "take (length lst - 1) lst"]
by (auto simp add: call_e_inside_big_idx)

(* decompose call_e into smaller pieces ... should follow from
   above similarly to call decomposition *)
lemma decompose_call_e_index :
  "call_e lst (last lst) \<Longrightarrow>
   \<exists>ilst. (\<forall>x \<in> set (indexSplit ilst (take (length lst-1) lst)).
   call_e x (lst!0) \<or> const_seq x (lst!0))"
using decompose_call_end_index [of "map length lst"]
      call_e_end [of lst]
apply auto
subgoal for ilst
apply (rule exI[where x=ilst])
apply clarsimp
(* because internally the stack is high,
   it should not change *)
apply (case_tac "const_seq (map length x) (map length lst ! 0) \<or>
    call_end (map length x) (map length lst ! 0)")
defer
subgoal for x
using index_split_map [of x ilst "take (length lst - 1) lst" length]
apply (simp add:take_map drop_map)
apply force
done
subgoal for x
using pathR_split [of "push_pop"
   "take (length lst - 1) lst" x ilst]
  pathR_take [of "push_pop" lst "length lst-1"]
  call_e_pathR [of lst]
apply simp

apply auto
subgoal (* constant *)
using const_seq_convert [of x "map length lst ! 0"]
apply (auto simp add:push_popL_def)
apply (cases x)
using const_seq_empty apply force
subgoal for xa a list
apply (simp add:map_nth)
using const_seq_eq [of a list xa]
apply simp
apply (subgoal_tac "a \<in> set (take (length lst - 1) lst)")
defer
using in_index_split apply fastforce
apply (subgoal_tac "lst ! 0 = a")
apply auto

using call_e_inside_big [of lst a]
  by (metis One_nat_def PathRel.take_all const_seq_eq length_greater_0_conv length_pos_if_in_set nth_map take_eq_Nil)
done
apply (rule call_end2)
  apply (clarsimp simp add: call_e_def)
  apply (metis Suc_lessD nth_map)

  using push_popL_def apply blast
using call_end_last [of "map length x" "length (lst ! 0)"]
using call_e_inside_big [of lst "last x"]
apply simp
apply (subgoal_tac "map length lst ! 0 = length (lst!0)")
defer
apply (simp add:call_e_def)
  using Suc_lessD nth_map apply blast
apply simp
apply (subgoal_tac "last x \<in> set (take (length lst - 1) lst)")
defer
apply (rule in_index_split [of x ilst "take (length lst-1) lst"
  "last x"])
apply auto
apply (simp add:call_end_def)
  apply (metis One_nat_def Suc_lessD diff_Suc_less gr_implies_not_zero in_set_conv_nth last_conv_nth length_0_conv)
apply (subgoal_tac "length (last x) = length (lst!0)")
  apply (metis PathRel.take_all)
apply (simp add:call_end_def)
  by (metis Suc_lessD last_map length_greater_0_conv)
done done

lemma decompose_call_e :
  "call_e lst (last lst) \<Longrightarrow>
  ilst = findIndices
             (take (length lst - Suc 0)
               (map length lst))
             (map length lst ! 0) \<Longrightarrow>
   x \<in> set (indexSplit ilst (take (length lst-1) lst)) \<Longrightarrow>
   call_e x (lst!0) \<or> const_seq x (lst!0)"
using decompose_call_end [of "map length lst" "map length x"]
      call_e_end [of lst]
apply auto
apply (case_tac "const_seq (map length x) (map length lst ! 0) \<or>
    call_end (map length x) (map length lst ! 0)")
defer
using index_split_map [of x ilst "take (length lst - 1) lst" length]
apply (simp add:take_map drop_map)
using pathR_split [of "push_pop"
   "take (length lst - 1) lst" x ilst]
  pathR_take [of "push_pop" lst "length lst-1"]
  call_e_pathR [of lst]
apply simp

apply auto
subgoal (* constant *)
using const_seq_convert [of x "map length lst ! 0"]
apply (auto simp add:push_popL_def)
apply (cases x)
using const_seq_empty apply force
subgoal for xa a list
apply (simp add:map_nth)
using const_seq_eq [of a list xa]
apply simp
apply (subgoal_tac "a \<in> set (take (length lst - 1) lst)")
defer
using in_index_split apply fastforce
apply (subgoal_tac "lst ! 0 = a")
apply auto

using call_e_inside_big [of lst a]
  by (metis One_nat_def PathRel.take_all const_seq_eq length_greater_0_conv length_pos_if_in_set nth_map take_eq_Nil)
done
apply (rule call_end2)
  apply (clarsimp simp add: call_e_def)
  apply (metis Suc_lessD nth_map)

  using push_popL_def apply blast
using call_end_last [of "map length x" "length (lst ! 0)"]
using call_e_inside_big [of lst "last x"]
apply simp
apply (subgoal_tac "map length lst ! 0 = length (lst!0)")
defer
apply (simp add:call_e_def)
  using Suc_lessD nth_map apply blast
apply simp
apply (subgoal_tac "last x \<in> set (take (length lst - 1) lst)")
defer
apply (rule in_index_split [of x ilst "take (length lst-1) lst"
  "last x"])
apply auto
apply (simp add:call_end_def)
  apply (metis One_nat_def Suc_lessD diff_Suc_less gr_implies_not_zero in_set_conv_nth last_conv_nth length_0_conv)
apply (subgoal_tac "length (last x) = length (lst!0)")
  apply (metis PathRel.take_all)
apply (simp add:call_end_def)
by (metis Suc_lessD last_map length_greater_0_conv)


definition psublists :: "'a list \<Rightarrow> 'a list set" where
"psublists lst = {take l (drop i lst) | l i. l < length lst}"

definition callout_rel :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> ('a * 'a list) rel" where
"callout_rel iv level =
    {(a,b) | a b. length (snd a) = level \<and> length (snd b) = level + 1 \<and> (iv a \<longrightarrow> iv b) }
  \<union> {(a,b) | a b. length (snd a) \<noteq> level \<or> length (snd b) \<noteq> level + 1}"

definition split_no_empty :: "nat list \<Rightarrow> 'a list \<Rightarrow> 'a list list" where
"split_no_empty ilst lst = filter (%lst. lst \<noteq> []) (indexSplit ilst lst)"

lemma concat_filter : "concat (filter (%lst. lst \<noteq> []) lst) = concat lst"
by (induction lst; auto)

definition pieces :: "'a list list \<Rightarrow> 'a list list list" where
"pieces lst =
  split_no_empty
     (findIndices (take (length lst - 1) (map length lst))
             (map length lst ! 0)) (take (length lst-1) lst)"

lemma call_e_from_pieces :
  "call_e lst x \<Longrightarrow>
   concat (pieces lst) = take (length lst-1) lst"
apply (simp add:call_e_def pieces_def split_no_empty_def
  concat_filter)
using split_and_combine2 [of "findIndices
         (take (length lst - Suc 0)
           (map length lst))
         (map length lst ! 0)" "take (length lst-1) lst"]
  by simp

lemma call_e_has_pieces :
  "call_e lst x \<Longrightarrow> length (pieces lst) > 0"
apply (cases "length (concat (pieces lst)) = 0")
using call_e_from_pieces [of lst x]
apply (auto simp add:call_e_def)
  by (metis diff_is_0_eq not_less take_eq_Nil)

lemma decompose_call_e_no_empty :
  "call_e lst (last lst) \<Longrightarrow>
   x \<in> set (pieces lst) \<Longrightarrow>
   call_e x (lst!0) \<or> const_seq x (lst!0)"
using decompose_call_e [of lst
   "(findIndices (take (length lst - 1) (map length lst)) (map length lst ! 0))" x]
by (auto simp:split_no_empty_def pieces_def)

lemma call_e_final : "call_e lst x \<Longrightarrow> last lst = x"
apply (auto simp add : call_e_def first_return_def first_def tlR_def)
  by (metis One_nat_def Suc_lessD last_conv_nth length_greater_0_conv)

lemma no_empty_pieces : "[] \<notin> set (pieces lst)"
by (simp add: pieces_def split_no_empty_def)

lemma piece_last :
   "call_e lst (last lst) \<Longrightarrow>
    b \<in> set (pieces lst) \<Longrightarrow>
    last b = lst!0"
using decompose_call_e_no_empty [of lst b]
apply auto
using call_e_final apply force
apply (cases "b = []")
using no_empty_pieces apply fastforce
apply (simp add:const_seq_def)
  using last_in_set by blast

lemma drop_concat_aux :
 "b \<noteq> [] \<Longrightarrow>
  lst = concat (a#b#rest) @ [x] \<Longrightarrow>
  last b # concat rest @ [x] =
    drop (length a + length b - 1) lst"
apply (subgoal_tac "drop (length a + length b - Suc 0) a = []")
apply (auto)
  apply (smt Suc_leI append_butlast_last_id append_eq_append_conv append_take_drop_id diff_diff_cancel length_Cons length_drop length_greater_0_conv list.size(3))
  by (metis Suc_leI length_greater_0_conv ordered_cancel_comm_monoid_diff_class.le_add_diff semiring_normalization_rules(24))

lemma drop_concat_aux2 :
  "a # b # rest = pieces lst \<Longrightarrow>
   call_e lst (last lst) \<Longrightarrow>
   last b # concat rest @ [last lst] = drop (length a + length b - 1) lst"
apply (rule drop_concat_aux)
  apply (metis list.set_intros(1) list.set_intros(2) no_empty_pieces)
using call_e_from_pieces [of lst "last lst"]
  by (metis (no_types, lifting) Nil_is_append_conv append_butlast_last_id butlast_conv_take concat.simps(2) list.set_intros(1) no_empty_pieces take_eq_Nil)

lemma first_return_drop :
  "first_return (length lst - 1) lst \<Longrightarrow>
   length lst > 0 \<Longrightarrow>
   length (drop x lst) > 0 \<Longrightarrow>
   hd lst = hd (drop x lst) \<Longrightarrow>
   first_return (length (drop x lst) - 1) (drop x lst)"
by (simp add:first_return_def first_def)

(* take away a piece, have new call_e *)
lemma take_piece :
  "call_e lst (last lst) \<Longrightarrow>
   a # b # rest = pieces lst \<Longrightarrow>
   call_e ([last b]@concat rest@[last lst]) (last lst)"
apply (auto simp add: call_e_def)
using piece_last [of lst b]
  apply (metis One_nat_def Suc_lessD call_e_def hd_conv_nth length_greater_0_conv list.set_intros(1) list.set_intros(2))
apply (subgoal_tac
   "last b # concat rest @ [last lst] = drop (length a + length b - 1) lst")
apply (simp add:push_popL_def pathR_drop)
using drop_concat_aux2 [of a b rest lst]
  apply (simp add: call_e_def)

apply (subgoal_tac
   "last b # concat rest @ [last lst] = drop (length a + length b - 1) lst")
using first_return_drop [of lst "length a + length b - 1"]
apply simp
apply (subgoal_tac "lst \<noteq> []")
apply (subgoal_tac "length a + length b - 1 < length lst")
apply (subgoal_tac "hd (drop (length a + length b - Suc 0)
          lst) = last b")
apply (subgoal_tac "Suc (length (concat rest)) = length lst -
       Suc (length a + length b - Suc 0)")
apply simp
apply (subgoal_tac "call_e lst (last lst)")
using piece_last [of lst b]
  apply (metis hd_conv_nth list.set_intros(1) list.set_intros(2))
  apply (simp add: call_e_def)
  apply (metis One_nat_def Suc_diff_Suc length_Cons length_append_singleton length_drop nat.inject)
  apply (metis list.sel(1))
  apply (metis One_nat_def length_drop length_greater_0_conv list.distinct(1) zero_less_diff)
  apply (metis One_nat_def less_numeral_extra(2) list.size(3))
using drop_concat_aux2 [of a b rest lst]
  apply (simp add: call_e_def)
done

definition call_inv2 :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_inv2 iv l =
   (call_e (map snd l) (snd (last l)) \<longrightarrow> iv (hd l) \<longrightarrow> iv (last l))"

definition call_inv :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_inv iv l = (call (map snd l) \<longrightarrow> iv (hd l) \<longrightarrow> iv (last l))"

definition stay_rel :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) rel" where
"stay_rel iv = {(a,b) | a b. length (snd a) = length (snd b) \<and> (iv a \<longrightarrow> iv b) }
             \<union> {(a,b) | a b. length (snd a) \<noteq> length (snd b)}"

lemma call_invariant :
  "\<forall>l \<in> psublists lst. call_inv2 iv l \<Longrightarrow> 
   pathR (stay_rel iv) lst \<Longrightarrow>
   (* exit must be good *)
   (iv (lst!(length lst-2)) \<Longrightarrow> iv (last lst)) \<Longrightarrow>
   (* call outs should be good *)
   pathR (callout_rel iv (length (snd (hd lst)))) lst \<Longrightarrow>
   call_inv2 iv lst"

(* can be solved using a case analysis using call pieces *)

apply (induction "length (pieces (map snd lst))")
apply (auto simp:call_inv2_def)
using call_e_has_pieces apply force

oops

end
