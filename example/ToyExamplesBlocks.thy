theory "ToyExamplesBlocks"

imports "../Hoare/HoareBasicBlocks"
begin

lemmas evm_fun_simps = 
  stack_inst_code.simps inst_size_def inst_code.simps 

lemmas blocks_simps = build_blocks_def byteListInt_def find_block_def extract_indexes_def build_vertices_def
 aux_basic_block.simps add_address_def block_pt_def

lemmas word_rcat_simps = word_rcat_def bin_rcat_def

lemmas pure_emp_simps = pure_def pure_sep emp_def emp_sep zero_set_def

lemma word_rcat_eq: "word_rcat [x] = x"
   by (simp add: word_rcat_simps)

lemma pure_false_simps:
"(\<langle> False \<rangle> \<and>* R) = \<langle> False \<rangle>"
"(R \<and>* \<langle> False \<rangle>) = \<langle> False \<rangle>"
by (rule ext, simp add: pure_def sep_conj_def emp_def )+

method after_inst_simp=
rule impI,
(sep_simp simp: pure_sep emp_sep)+,
rule conjI,
(sep_cancel)+,
simp+

method after_seq_empty_not_final=
rule impI,
(sep_simp simp: stack_height_sep pure_sep emp_sep)+,
rule conjI,
 (sep_cancel)+,
(simp add: word_rcat_def)+
(*apply(rule impI)
 apply(sep_simp simp: stack_height_sep pure_sep emp_sep)+
 apply(rule conjI)
  apply(sep_cancel)+
 apply(simp add: word_rcat_def)+*)

method after_seq_empty_final uses simp=
rule impI,
((sep_simp simp: simp)+ | (sep_simp simp: simp)?),
(simp add: word_rcat_simps)?,
(sep_cancel? | (sep_cancel)+)


context
notes if_split[ split del ] sep_fun_simps[simp del]
gas_value_simps[simp add] pure_emp_simps[simp add]
evm_fun_simps[simp add]
begin

(* Example with a Jumpi and a No block *)

definition c where
"c = build_blocks [ Stack (PUSH_N [1]), Stack (PUSH_N [8]), Pc JUMPI, Stack (PUSH_N [1]), Misc STOP, Pc JUMPDEST, Stack (PUSH_N [2]), Misc STOP]"

schematic_goal c_val:
 " c = ?p"
 by(simp add: c_def  word_rcat_simps Let_def dropWhile.simps  blocks_simps next_i_def
  split:if_splits nat.splits option.splits )

(* For a jumpif that can be solved statically, it works *)
lemma
 "\<exists>rest. triple_blocks c
(continuing ** stack_height 0 ** program_counter 0 ** gas_pred 1000 ** memory_usage 0)
(0,the (blocks_list c 0))
(stack 0 (word_rcat [2::byte]) ** rest)"
 apply(unfold c_val)
 apply (simp)
 apply(rule exI)
 apply(rule blocks_jumpi[where rest=emp])
        apply(simp)
       prefer 4
       apply(simp)
       apply(rule seq_inst)
        apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest=emp])
        apply(after_inst_simp)
       apply(rule seq_inst)
        apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest="stack 0 (word_rcat [1])"
              and h="Suc 0"])
        apply(after_inst_simp)
       apply(rule seq_empty)
       apply(after_seq_empty_not_final)
      apply(simp add: word_rcat_simps)+
 apply(rule blocks_no)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_pc], rule inst_jumpdest[where rest=emp])
  apply(after_inst_simp)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest=emp])
  apply(after_inst_simp)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_misc], rule inst_stop[where rest="stack 0 (word_rcat [2])"])
  apply(after_inst_simp)
 apply(rule seq_empty)
 apply(after_seq_empty_final simp: stack_sep)
 apply(simp add: word_rcat_simps)
done


(* Same example but we put an unknown value and an if in the post condition *)
(* For a jumpif where we don't know at all which branch to follow, it works *)
definition c2 where
"c2 x = build_blocks [ Stack (PUSH_N [x]), Stack (PUSH_N [8]), Pc JUMPI, Stack (PUSH_N [1]), Misc STOP, Pc JUMPDEST, Stack (PUSH_N [2]), Misc STOP]"

schematic_goal c2_val:
 " c2 x = ?p"
 by(simp add: c2_def  word_rcat_simps Let_def dropWhile.simps blocks_simps next_i_def
  split:if_splits nat.splits option.splits )

lemma
 " \<exists>rest0 restn0. triple_blocks (c2 cond)
(continuing ** stack_height 0 ** program_counter 0 ** gas_pred 1000 ** memory_usage 0)
(0, the (blocks_list (c2 cond) 0))
(if word_rcat [cond] = (0::256 word) then stack 0 (word_rcat [1::byte]) ** restn0 else stack 0 (word_rcat [2::byte]) ** rest0)
"
apply(unfold c2_val)
apply (simp)
apply(rule exI)+
 apply(rule blocks_jumpi[where rest=emp])
        apply(simp)
       prefer 4
       apply(simp)
       apply(rule seq_inst)
        apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest=emp])
        apply(after_inst_simp)
       apply(rule seq_inst)
        apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest="stack 0 (word_rcat [cond])"
              and h="Suc 0"])
        apply(after_inst_simp)
       apply(rule seq_empty)
       apply(after_seq_empty_not_final)
      apply(simp add: word_rcat_simps)+
  prefer 2
  apply(simp add: word_rcat_simps)
 apply(rule blocks_no)
  apply(rule seq_inst)
   apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest=emp])
   apply(after_inst_simp)
  apply(rule seq_inst)
   apply(rule inst_strengthen_pre[OF inst_misc], rule inst_stop[where rest="stack 0 (word_rcat [1])"])
   apply(after_inst_simp)
  apply(rule seq_empty; rule impI)
  apply(simp add: word_rcat_simps)
  apply(sep_cancel)
 apply(rule blocks_no)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_pc], rule inst_jumpdest[where rest=emp])
  apply(after_inst_simp)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest=emp])
  apply(after_inst_simp)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_misc], rule inst_stop[where rest="stack 0 (word_rcat [2])"])
  apply(after_inst_simp)
 apply(rule seq_empty)
 apply(after_seq_empty_final)
done

(* Same example as the previous one but with the unknown value as a precondition *)

lemma
 "\<exists>rest. triple_blocks (c2 cond)
(continuing ** stack_height 0 ** program_counter 0 ** gas_pred 1000 ** memory_usage 0 **
 \<langle> (word_rcat [cond] \<noteq> (0::256 word)) \<rangle>)
(0,the (blocks_list (c2 cond) 0))
(stack 0 (word_rcat [2::byte]) ** rest )
"
apply(unfold c2_val)
apply (simp)
apply(rule exI)
apply(rule blocks_jumpi[where rest="\<langle>word_rcat [cond] \<noteq> (0::256 word)\<rangle>"])
        apply(simp)
       prefer 4
       apply(simp)
       apply(rule seq_inst)
        apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest="\<langle>word_rcat [cond] \<noteq> (0::256 word)\<rangle>"])
        apply(after_inst_simp)
       apply(rule seq_inst)
        apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest="stack 0 (word_rcat [cond]) \<and>* \<langle>word_rcat [cond] \<noteq> (0::256 word)\<rangle>"
              and h="Suc 0"])
        apply(after_inst_simp)
       apply(rule seq_empty)
       apply(after_seq_empty_not_final)
      apply(simp add: word_rcat_simps)+
  prefer 2
  apply(simp add: word_rcat_simps pure_false_simps)
  apply(rule blocks_no)
  apply(rule seq_false_pre)
 apply(rule blocks_no)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_pc], rule inst_jumpdest[where rest="\<langle>word_rcat [cond] \<noteq> (0::256 word)\<rangle>"])
  apply(after_inst_simp)
  apply(simp add: word_rcat_simps)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest=emp])
  apply(after_inst_simp)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_misc], rule inst_stop[where rest="stack 0 (word_rcat [2])"])
  apply(after_inst_simp)
 apply(rule seq_empty)
apply(after_seq_empty_final)
done

(* Example with a Jump and a Next block*)

definition c4 where
"c4 = build_blocks [ Stack (PUSH_N [1]), Stack (PUSH_N [5]), Pc JUMP, Pc JUMPDEST, Stack (PUSH_N [2]), Pc JUMPDEST, Misc STOP]"

schematic_goal c4_val:
 " c4  = ?p"
 by(simp add: c4_def  word_rcat_simps Let_def dropWhile.simps blocks_simps next_i_def
  split:if_splits nat.splits option.splits )

lemma
 "\<exists>rest. triple_blocks c4
(continuing ** stack_height 0 ** program_counter 0 ** gas_pred 1000 ** memory_usage 0)
(0, the (blocks_list c4 0))
(stack 0 (word_rcat [1::byte]) ** stack_height (Suc (Suc 0)) ** stack 1 (word_rcat [2::byte]) ** rest)
"
apply(unfold c4_val)
apply (simp)
apply(rule exI)
apply(rule blocks_jump[where rest="stack 0 (word_rcat [1])"])
     prefer 3
     apply(simp)
     apply(rule seq_inst)
      apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest=emp])
      apply(after_inst_simp)
     apply(rule seq_inst)
      apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest="stack 0 (word_rcat [1])"
            and h="Suc 0"])
      apply(after_inst_simp)
     apply(rule seq_empty)
     apply(after_seq_empty_not_final)
    apply(simp add: word_rcat_simps)+
 apply(rule blocks_next)
    apply(simp)
   apply(simp)
  apply(rule seq_inst)
   apply(rule inst_strengthen_pre[OF inst_pc], rule inst_jumpdest[where rest="stack 0 1"])
   apply(after_inst_simp)
  apply(rule seq_inst)
   apply(rule inst_strengthen_pre[OF inst_stack], rule inst_push_n[where rest="stack 0 1"])
    apply(after_inst_simp)
  apply(rule seq_empty)
  apply(after_seq_empty_final)
 apply(rule blocks_no)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_pc], rule inst_jumpdest[where rest="stack 0 1 \<and>* stack (Suc 0) 2"])
  apply(after_inst_simp)
 apply(rule seq_inst)
  apply(rule inst_strengthen_pre[OF inst_misc], rule inst_stop[where rest="stack 0 1 \<and>* stack (Suc 0) 2"])
  apply(after_inst_simp)
 apply(rule seq_empty)
 apply(after_seq_empty_final simp: stack_height_sep stack_sep)
done
end

end
