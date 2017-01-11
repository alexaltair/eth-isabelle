theory HoareTripleForInstructions

imports Main "./Hoare"

begin

(* how to declare [simp] in a limited scope? *)
context

begin

(**
 ** Hoare Triple for each instruction
 **)
 
declare insert_functional [intro]

lemma arith_inst_size_one [simp]:
  "inst_size (Arith a) = 1"
apply(simp add: inst_size_def inst_code.simps)
done

lemma lst_longer [dest!]:
  "length l = Suc h \<Longrightarrow> \<exists> a t. l = a # t \<and> length t = h"
	by (simp add: length_Suc_conv)

lemma advance_pc_advance [simp]:
  " vctx_next_instruction x1 co_ctx = Some i \<Longrightarrow>
    inst_size i = 1 \<Longrightarrow>
    vctx_pc (vctx_advance_pc co_ctx x1) = vctx_pc x1 + 1"
apply(simp add: vctx_advance_pc_def)
done

lemma advance_pc_no_gas_change [simp] :
  "vctx_gas (vctx_advance_pc co_ctx x1) = vctx_gas x1"
apply(simp add: vctx_advance_pc_def)
apply(case_tac "vctx_next_instruction x1 co_ctx"; auto)
done

lemma stack_touching_operations_leaves [simp] :
"(contexts_as_set
              (vctx_advance_pc co_ctx x1\<lparr>vctx_stack := (v + w) # ta, vctx_gas := vctx_gas x1 - Gverylow\<rparr>) co_ctx -
             {StackHeightElm (Suc (length ta))} -
             {StackElm (length ta, v + w)} -
             {PcElm (vctx_pc x1 + 1)} -
             {GasElm (vctx_gas x1 - Gverylow)}) =
contexts_as_set
              (vctx_advance_pc co_ctx x1) co_ctx -
             {StackHeightElm (Suc (Suc (length ta)))} -
             {StackElm (length ta, v + w)} -
             {PcElm (vctx_pc x1 + 1)} -
             {GasElm (vctx_gas x1 - Gverylow)}
"
oops


lemma add_triple : "triple (\<langle> h \<le> 1023 \<and> g \<ge> Gverylow \<rangle> **
                            stack_height (h + 2) **
                            stack (h + 1) v **
                            stack h w **
                            program_counter k **
                            gas_pred g
                           )
                           {(k, Arith ADD)}
                           (stack_height (h + 1) **
                            stack h (v + w) **
                            program_counter (k + 1) **
                            gas_pred (g - Gverylow)
                            )"
apply(auto simp add: triple_def)
apply(rule_tac x = "1" in exI)
apply(case_tac presult; simp)
apply(auto simp add: program_sem.simps vctx_next_instruction_def instruction_sem_def check_resources_def
      inst_stack_numbers.simps arith_inst_numbers.simps predict_gas_def C_def Cmem_def
      Gmemory_def new_memory_consumption.simps thirdComponentOfC.simps
      vctx_next_instruction_default_def stack_2_1_op_def subtract_gas.simps)



(*

apply(case_tac "vctx_stack x1"; simp)
apply(case_tac list; simp)
apply(auto simp add: subtract_gas.simps strict_if_def program_sem.simps
      vctx_advance_pc_def vctx_next_instruction_def inst_size_def inst_code.simps                                                                               
      contexts_as_set_def constant_ctx_as_set_def variable_ctx_as_set_def stack_as_set_def
      program_as_set_def)
apply(simp add: insert_Diff_if)
apply(rule pred_functional)
 apply(simp)

apply(rule insert_functional; blast?)
apply(rule insert_functional; blast?)
apply(rule insert_functional; blast?)
apply(rule insert_functional; blast?)
apply(rule insert_functional; blast?)
apply(rule insert_functional; blast?)
apply(rule Set.equalityI)
 apply(clarify)
 apply(simp)
 apply(drule disjE; simp)
 apply(drule disjE; simp?)
  apply(blast)
 apply(drule disjE; simp?)
  defer
  apply(clarify)
  apply(simp)
  apply(case_tac "idx \<ge> length lista"; simp)
  apply(case_tac "idx = Suc (length lista)"; simp)
 apply(clarify)
 apply(simp)
 apply(drule disjE; simp?)
  apply(drule disjE; simp?)
   apply(blast)
  apply(drule disjE; simp?)
   defer
   apply(clarify)
   apply(simp)
   apply(case_tac "idx = (length lista)"; simp)
  apply(drule disjE; simp?)
   apply(blast)
  apply(drule disjE; simp?)
 apply(clarify)
 apply(simp)
apply(clarify)
apply(simp)
done

*)
end (* context *)

end
