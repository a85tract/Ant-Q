#!/bin/bash
# Single-circuit fixed-cost decomposition on c3 (batch_server v7 stage timestamps): all 20 paper circuits x 10 repeats
# with dma_server STRM_POLL_US=0 (tight t_last_read detection), then three short circuits x 10 at STRM_POLL_US=200 (the
# Table 4 condition) to quantify the poll-latency share; the board is left at STRM_POLL_US=200 (its previous state).
cd "$(dirname "$0")"
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
GW=/home/yicheng/gateware_yguang_check/gw_build_c3_8s/top/zcu216_14_2/build_63329aaf_20260830175903
LOG=../results/decomp.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
run(){ # $1 tag, $2 poll, $3 repeats, $4 idx list
  python antq_runner.py --real --mode c3 --bits $GW --gw $GW --num-ch 14 --what single --idx "$4" --repeats $3 --wns 0.000 \
    --tag $1 --decomp --strm-poll-us $2 --note "decomp; batch_server v7; dma STRM_POLL_US=$2" 2>&1 | grep -v "^ PREFILL\|BS-T\|^\[DDR batch\]" >> $LOG
}
# runner idx numbering = the paper's Table speedup (1-13, 19-25), NOT the QCE26 noise-study numbering: the first launch
# (22:34) passed the noise-study list and stopped at the unknown idx 16 after 7, 6, 8; this pass covers all 20.
log "DECOMP START (poll 0)"
python -c "import run_stop_campaign as S; S.restart_dma(0)" >> $LOG 2>&1
run c3_14q_decomp_p0 0 10 10,9,12,6,5,11,20,25,8,13,7,4,3,2,1,21,23,22,19,24
log "poll 0 pass done; switching dma_server to STRM_POLL_US=200"
python -c "import run_stop_campaign as S; S.restart_dma(200)" >> $LOG 2>&1
run c3_14q_decomp_p200 200 10 10,9,12
log "DECOMP DONE (board left at STRM_POLL_US=200)"
